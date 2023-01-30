CREATE PROCEDURE [OWAPv2].[uspUpdateRegistration]
@EventID [dbo].[EventID] = NULL, @RegistrationNumber [dbo].[RegistrationNumber] = NULL, @RegistrationDate DATETIME2(7) = NULL, @Validated BIT OUTPUT, @ValidationFailureReason VARCHAR (255) OUTPUT
/*
	Purpose:	OWAP Registration Update

	Version		Date			Developer			Comment
	1.1			2018-04-04		Chris Ledger		BUG 14399 - GDPR Update Registration
	1.2			2018-06-29		Chris Ledger		BUG 14819 - Update on EventID Only and Add Validation
	1.3			2018-08-07		Chris Ledger		BUG 14819 - Update All EventIDs After current Event
	1.4			2020-01-21		Chris Ledger		BUG 15372: Fix Hard coded references to databases.	
*/

AS

SET NOCOUNT ON

	DECLARE @ErrorNumber INT
	DECLARE @ErrorSeverity INT
	DECLARE @ErrorState INT
	DECLARE @ErrorLocation NVARCHAR(500)
	DECLARE @ErrorLine INT
	DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	--------------------------------------------------------------------------------
	-- V1.2 Check parameters populated correctly
	--------------------------------------------------------------------------------
	SET @Validated = 0
		
	IF	@EventID IS NULL
	BEGIN
		SET @ValidationFailureReason = '@EventID parameter has not been supplied'
		RETURN 0
	END 

	IF	@RegistrationNumber IS NULL
	BEGIN
		SET @ValidationFailureReason = '@RegistrationNumber parameter has not been supplied'
		RETURN 0
	END 

	IF	0 = (SELECT COUNT(*) FROM Vehicle.VehiclePartyRoleEvents WHERE EventID = @EventID)
	BEGIN
		SET @ValidationFailureReason = 'The supplied EventID is not found in the VehiclePartyRoleEvents table.'
		RETURN 0
	END 

	SET @Validated = 1
	--------------------------------------------------------------------------------

	BEGIN TRAN

		--------------------------------------------------------------------------------
		-- V1.2 Get VehicleID
		--------------------------------------------------------------------------------
		DECLARE @VehicleID [dbo].[VehicleID]

		SELECT @VehicleID = VehicleID FROM Vehicle.VehiclePartyRoleEvents WHERE EventID = @EventID
		--------------------------------------------------------------------------------
		
		--------------------------------------------------------------------------------
		-- HOLDS DATA TO BE LOADED INTO THE REGISTRATION TABLES
		--------------------------------------------------------------------------------
		CREATE TABLE #VehicleRegistrationEvents 
		(
			VehicleRegistrationEventsID INT IDENTITY(1, 1),
			ParentVehicleRegistrationEventsID INT DEFAULT(0),
			AuditID INT,
			AuditItemID INT,
			VehicleID INT, 
			RegistrationID INT, 
			EventID INT,
			RegistrationNumber NVARCHAR(100), 
			RegistrationDate DATETIME,
			NewRegistration BIT DEFAULT(1)
		)
		--------------------------------------------------------------------------------

		--------------------------------------------------------------------------------
		-- ADD EVENT TO BE UPDATED
		--------------------------------------------------------------------------------
		INSERT INTO #VehicleRegistrationEvents (VehicleID, EventID,	RegistrationNumber, RegistrationDate)
		
		VALUES	(@VehicleID, @EventID, @RegistrationNumber, @RegistrationDate)
		--------------------------------------------------------------------------------

		--------------------------------------------------------------------------------
		-- ADD ALL EVENTS AFTER EXISTING EVENT (N.B THESE WILL ALL SET TO SAME DATE)
		--------------------------------------------------------------------------------
		INSERT INTO #VehicleRegistrationEvents (VehicleID, EventID,	RegistrationNumber, RegistrationDate)
		SELECT VRE.VehicleID, VRE.EventID, @RegistrationNumber AS RegistrationNumber, @RegistrationDate AS RegistrationDate
		FROM Vehicle.VehicleRegistrationEvents VRE
		WHERE VRE.VehicleID = @VehicleID
		AND VRE.EventID > @EventID
		--------------------------------------------------------------------------------

		--------------------------------------------------------------------------------
		-- LOG AUDITID OF METADATA
		--------------------------------------------------------------------------------
		DECLARE @DateTimeStamp VARCHAR(50) = CONVERT(VARCHAR,CONVERT(DATE,GETDATE())) + '_' + SUBSTRING(CONVERT(VARCHAR,CONVERT(TIME,GETDATE())),1,5)
		DECLARE @FileName VARCHAR(50) = 'GDPR_UpdateCarReg_' + @DateTimeStamp
		DECLARE @FileType VARCHAR(50) = 'GDPR Update'
		DECLARE @FileRowCount INT = (SELECT COUNT(*) FROM #VehicleRegistrationEvents)
		DECLARE @FileChecksum INT = CHECKSUM(@FileName)
		DECLARE @LoadSuccess INT = 1
		--------------------------------------------------------------------------------

		--------------------------------------------------------------------------------
		-- GET THE MAXIMUM AuditID FROM Audit
		--------------------------------------------------------------------------------
		DECLARE @AuditID dbo.AuditID
		SELECT @AuditID = ISNULL(MAX(AuditID), 0) + 1 FROM [$(AuditDB)].dbo.Audit
		--------------------------------------------------------------------------------

		--------------------------------------------------------------------------------
		-- INSERT THE NEW AuditID INTO Audit
		--------------------------------------------------------------------------------
		INSERT INTO [$(AuditDB)].dbo.Audit (AuditID)
		SELECT @AuditID
		--------------------------------------------------------------------------------

		--------------------------------------------------------------------------------
		-- NOW INSERT THE FILE DETAILS
		--------------------------------------------------------------------------------
		INSERT INTO [$(AuditDB)].dbo.Files
		(
			 AuditID
			,FileTypeID
			,FileName
			,FileRowCount
			,ActionDate
		)
		SELECT @AuditID, FileTypeID, @FileName, @FileRowCount, GETDATE() FROM [$(AuditDB)].dbo.FileTypes WHERE FileType = @FileType
		
		INSERT INTO [$(AuditDB)].dbo.IncomingFiles
		(
			 AuditID
			,FileChecksum
			,LoadSuccess
		)
		VALUES (@AuditID, @FileChecksum, @LoadSuccess)

		UPDATE #VehicleRegistrationEvents
		SET AuditID = @AuditID
		--------------------------------------------------------------------------------

		--------------------------------------------------------------------------------
		-- ADD AUDITITEMIDS OF METADATA
		--------------------------------------------------------------------------------

		--------------------------------------------------------------------------------
		-- GET THE NEXT AUDITITEMID
		--------------------------------------------------------------------------------
		DECLARE @MaxAuditItemID INT
		SET @MaxAuditItemID = (SELECT MAX(AuditItemID) FROM [$(AuditDB)].dbo.AuditItems)
		--------------------------------------------------------------------------------

		--------------------------------------------------------------------------------
		-- ASSIGN THE NEXT AUDITITEMIDS IN SEQUENCE TO ANY RECORDS WITHOUT AN AUDITITEMID 
		--------------------------------------------------------------------------------
		UPDATE #VehicleRegistrationEvents
		SET AuditItemID = @MaxAuditItemID + VehicleRegistrationEventsID
		--------------------------------------------------------------------------------

		--------------------------------------------------------------------------------
		-- WRITE THE NEW AUDITITEMIDS
		--------------------------------------------------------------------------------
		INSERT INTO [$(AuditDB)].dbo.AuditItems
		(
			AuditID
			,AuditItemID
		)
		SELECT 
			AuditID
			,AuditItemID
		FROM #VehicleRegistrationEvents D
		WHERE NOT EXISTS (SELECT 1 FROM [$(AuditDB)].dbo.AuditItems AI WHERE AI.AuditItemID = D.AuditItemID)
		--------------------------------------------------------------------------------


		--------------------------------------------------------------------------------
		-- USE TODAY'S FULL DATE AS OUR DUMMY DATE FOR NULL LINKING
		--------------------------------------------------------------------------------
		DECLARE @DummyDatetime DATETIME
		SET @DummyDatetime = GETDATE()
		--------------------------------------------------------------------------------

		--------------------------------------------------------------------------------
		-- CREATE TABLE MAX REGISTRATION IDs AND MAX BLANK REGISTRATION IDS FOR LINKING
		--------------------------------------------------------------------------------
		SELECT NVRE.RegistrationNumber, ISNULL(NVRE.RegistrationDate, @DummyDatetime) AS RegistrationDate , MAX(R.RegistrationID) AS MaxRegistrationID
		INTO #MaxRegs   
		FROM #VehicleRegistrationEvents NVRE
		INNER JOIN Vehicle.Registrations R ON R.RegistrationNumber = ISNULL(NVRE.RegistrationNumber, '')
											AND COALESCE(R.RegistrationDate, @DummyDatetime) = COALESCE(NVRE.RegistrationDate, R.RegistrationDate, @DummyDatetime)
		WHERE ISNULL(NVRE.RegistrationNumber, '') <> ''
		GROUP BY NVRE.RegistrationNumber, ISNULL(NVRE.RegistrationDate, @DummyDatetime)

		UNION

 		SELECT '', RegistrationDate, MAX(RegistrationID)  
		FROM Vehicle.Registrations 
		WHERE RegistrationNumber = '' AND RegistrationDate IS NOT NULL
		GROUP BY RegistrationDate
		--------------------------------------------------------------------------------
		
		--------------------------------------------------------------------------------
		-- MATCH EXISTING REGISTRATION NUMERS FOR THE VEHICLE
		--------------------------------------------------------------------------------
		UPDATE NVRE
		SET	NVRE.RegistrationID = X.MaxRegistrationID,
			NVRE.NewRegistration = 0
		FROM #VehicleRegistrationEvents NVRE
		INNER JOIN #MaxRegs X ON X.RegistrationNumber = NVRE.RegistrationNumber
						AND COALESCE(X.RegistrationDate, @DummyDatetime) = COALESCE(NVRE.RegistrationDate, @DummyDatetime)			
		--------------------------------------------------------------------------------

		--------------------------------------------------------------------------------
		-- FIND DUPLICATE REGISTRATION NUMBERS
		--------------------------------------------------------------------------------
		UPDATE R
		SET R.ParentVehicleRegistrationEventsID = M.ParentVehicleRegistrationEventsID
		FROM #VehicleRegistrationEvents R
		INNER JOIN (
			SELECT
				MAX(VehicleRegistrationEventsID) AS ParentVehicleRegistrationEventsID,
				VehicleID,
				RegistrationNumber,
				RegistrationDate
			FROM #VehicleRegistrationEvents
			GROUP BY VehicleID, RegistrationNumber, RegistrationDate
		) M ON M.VehicleID = R.VehicleID 
				AND M.RegistrationNumber = R.RegistrationNumber 
				AND COALESCE(M.RegistrationDate, @DummyDatetime) = COALESCE(R.RegistrationDate, @DummyDatetime)
		--------------------------------------------------------------------------------

		--------------------------------------------------------------------------------
		-- GET THE NEW REGISTRATIONS
		--------------------------------------------------------------------------------
		CREATE TABLE #NewVehicleRegistrationEvents
		(
			 NewVehicleRegistrationEventsID INT IDENTITY(1,1)
			,VehicleRegistrationEventsID INT
			,RegistrationID INT
		)

		INSERT INTO #NewVehicleRegistrationEvents (VehicleRegistrationEventsID)
		SELECT VehicleRegistrationEventsID
		FROM #VehicleRegistrationEvents
		WHERE ISNULL(RegistrationID, 0) = 0
		AND NewRegistration = 1
		AND (ISNULL(RegistrationNumber, '') <> '' OR RegistrationDate IS NOT NULL)	
		AND VehicleRegistrationEventsID = ParentVehicleRegistrationEventsID
		ORDER BY VehicleRegistrationEventsID
		--------------------------------------------------------------------------------

		--------------------------------------------------------------------------------
		-- GENERATE SOME NEW REGISTRATIONIDS
		--------------------------------------------------------------------------------
		DECLARE @MaxRegistrationID INT

		SELECT @MaxRegistrationID = MAX(RegistrationID) FROM Vehicle.Registrations

		UPDATE #NewVehicleRegistrationEvents
		SET RegistrationID = NewVehicleRegistrationEventsID + @MaxRegistrationID
		--------------------------------------------------------------------------------

		--------------------------------------------------------------------------------
		-- WRITE THE NEW REGISTRATIONIDS BACK TO #VehicleRegistrationEvents
		--------------------------------------------------------------------------------
		UPDATE V
		SET V.RegistrationID = N.RegistrationID
		FROM #NewVehicleRegistrationEvents N
		INNER JOIN #VehicleRegistrationEvents V ON V.ParentVehicleRegistrationEventsID = N.VehicleRegistrationEventsID
		DROP TABLE #NewVehicleRegistrationEvents
		--------------------------------------------------------------------------------

		--------------------------------------------------------------------------------
		-- DELETE THE EXISTING VehicleRegistrationEvents
		--------------------------------------------------------------------------------
		DELETE VRE
		FROM #VehicleRegistrationEvents N
		INNER JOIN Vehicle.VehicleRegistrationEvents VRE ON VRE.EventID = N.EventID
		--------------------------------------------------------------------------------

		--------------------------------------------------------------------------------
		-- INSERT THE NEW REGISTRATIONS
		--------------------------------------------------------------------------------
		SET IDENTITY_INSERT Vehicle.Registrations ON
		INSERT INTO Vehicle.Registrations
		(
			RegistrationID,
			RegistrationNumber,
			RegistrationDate
		)
		SELECT DISTINCT
			VRE.RegistrationID,
			ISNULL(VRE.RegistrationNumber, '') AS RegistrationNumber,
			VRE.RegistrationDate
		FROM #VehicleRegistrationEvents VRE
		LEFT JOIN Vehicle.Registrations R ON R.RegistrationID = VRE.RegistrationID
		WHERE VRE.NewRegistration = 1
		AND VRE.RegistrationID <> 0
		AND R.RegistrationID IS NULL
		SET IDENTITY_INSERT Vehicle.Registrations OFF
		--------------------------------------------------------------------------------

		--------------------------------------------------------------------------------
		-- AUDIT THE NEW REGISTRATIONS
		--------------------------------------------------------------------------------
		INSERT INTO [$(AuditDB)].Audit.Registrations
		(
			RegistrationID,
			RegistrationNumber,
			RegistrationDateOrig,
			RegistrationDate,
			AuditItemID
		)
		SELECT DISTINCT
			NVRE.RegistrationID,
			NVRE.RegistrationNumber AS RegistrationNumber,
			NVRE.RegistrationDate,
			NVRE.RegistrationDate,
			NVRE.AuditItemID
		FROM #VehicleRegistrationEvents NVRE 
		LEFT JOIN [$(AuditDB)].Audit.Registrations AR ON AR.AuditItemID = NVRE.AuditItemID 
		WHERE AR.AuditItemID IS NULL
		AND NVRE.RegistrationID <> 0
		AND NVRE.NewRegistration = 1
		--------------------------------------------------------------------------------

		--------------------------------------------------------------------------------
		-- INSERT THE VehicleRegistrationEvents
		--------------------------------------------------------------------------------
		INSERT INTO Vehicle.VehicleRegistrationEvents
		(
			VehicleID,
			RegistrationID,
			EventID
		)
		SELECT DISTINCT
			N.VehicleID,
			N.RegistrationID,
			N.EventID
		FROM #VehicleRegistrationEvents N
		LEFT JOIN Vehicle.VehicleRegistrationEvents VRE ON VRE.VehicleID = N.VehicleID
														AND VRE.RegistrationID = N.RegistrationID
														AND VRE.EventID = N.EventID
		WHERE N.RegistrationID <> 0
		AND VRE.VehicleID IS NULL
		--------------------------------------------------------------------------------

		--------------------------------------------------------------------------------
		-- AUDIT THE VehicleRegistrationEvents
		--------------------------------------------------------------------------------
		INSERT INTO [$(AuditDB)].Audit.VehicleRegistrationEvents
		(
			AuditItemID,
			VehicleID,
			RegistrationID,
			EventID
		)
		SELECT DISTINCT
			NVRE.AuditItemID,
			NVRE.VehicleID,
			NVRE.RegistrationID,
			NVRE.EventID
		FROM #VehicleRegistrationEvents NVRE
		LEFT JOIN [$(AuditDB)].Audit.VehicleRegistrationEvents AVRE ON AVRE.AuditItemID = NVRE.AuditItemID 
		WHERE AVRE.AuditItemID IS NULL
		--------------------------------------------------------------------------------

		--------------------------------------------------------------------------------
		-- UPDATE LOGGING
		--------------------------------------------------------------------------------
		UPDATE SL SET SL.ODSRegistrationID = NVRE.RegistrationID
		FROM [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL
		INNER JOIN #VehicleRegistrationEvents NVRE ON SL.MatchedODSEventID = NVRE.EventID
													AND SL.MatchedODSVehicleID = NVRE.VehicleID
		
		DROP TABLE #VehicleRegistrationEvents
			
	COMMIT TRAN

END TRY
BEGIN CATCH

	IF @@TRANCOUNT > 0
	BEGIN
		ROLLBACK TRAN
	END

	SELECT
		 @ErrorNumber = Error_Number()
		,@ErrorSeverity = Error_Severity()
		,@ErrorState = Error_State()
		,@ErrorLocation = Error_Procedure()
		,@ErrorLine = Error_Line()
		,@ErrorMessage = Error_Message()

	EXEC [$(ErrorDB)].dbo.uspLogDatabaseError
		 @ErrorNumber
		,@ErrorSeverity
		,@ErrorState
		,@ErrorLocation
		,@ErrorLine
		,@ErrorMessage
		
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH