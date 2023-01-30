CREATE TRIGGER Vehicle.TR_I_vwDA_VehicleRegistrationEvents ON Vehicle.vwDA_VehicleRegistrationEvents
INSTEAD OF INSERT

AS

/*
	Purpose:	Handles insert into vwDA_VehicleRegistrationEvents.
				Inserts new data into VehicleRegistrationEvents and Registrations.
				Inserts all data into Audit.VehicleRegistrationEvents and Audit_Registrations

	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created from [Prophet-ODS].dbo.vwDA_vwDA_VehiclePartyRoles.TR_I_vwDA_vwDA_VehiclePartyRoles
	1.1				11/03/2013		Chris Ross			BUG 8626 : Modified ensure that blank vehicle registrations are not matched to existing vehicle registrations 
														unless the registration has an actual registration number. I.e. don't link blanks.
	1.2				01/08/2013		Chris Ross			BUG 8969 : Fixed linkage on existing registrations to include registration date as was assigning all blank 
														reg's with the same reg date.
														Also, updated the 'get new registrations' select to only lookup vehicles we are interested in.
	1.3				22/10/2014		Chris Ross			BUG 10903: Updated registration MAX(ID) code as was inefficient when linking on blank registrations 
																   (of which there are currently 350,000)
	1.4				31/10/2014		Chris Ross			BUG 10903: Add extra code in to ensure that Registrations with NULL reg dates do not create new duplicate registrations.
	1.5				06/08/2018		Chris Ledger		BUG 14819: Exclude duplicates
*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	BEGIN TRAN

		-- HOLDS DATA ABOUT TO BE LOADED INTO THE ODS
		CREATE TABLE #VehicleRegistrationEvents 
		(
			VehicleRegistrationEventsID INT IDENTITY(1, 1),
			ParentVehicleRegistrationEventsID INT DEFAULT(0),		-- V1.5
			VehicleID INT, 
			RegistrationID INT, 
			EventID INT,
			RegNumber NVARCHAR(100), 
			RegistrationDate DATETIME,
			NewRegistration BIT DEFAULT(1),
			VehicleRegistrationEventExists BIT DEFAULT(0)
		)

		-- GET NEW RECS FROM VWT
		INSERT #VehicleRegistrationEvents
		(
			VehicleID,
			RegistrationID,
			EventID,
			RegNumber,
			RegistrationDate
		)
		SELECT DISTINCT
			VehicleID,
			RegistrationID,
			EventID, 
			RegNumber,
			RegistrationDate
		FROM INSERTED
		WHERE ISNULL(EventID, 0) > 0

		-- Use today's full date as our dummy date for NULL linking			-- v1.4
		DECLARE @DummyDatetime DATETIME
		SET @DummyDatetime = GETDATE()

		-- Create table max registration IDs and MAX blank registration IDs for linking  -- v1.3
			SELECT NVRE.RegNumber, ISNULL(NVRE.RegistrationDate, @DummyDatetime) AS RegistrationDate , MAX(R.RegistrationID) AS MaxRegistrationID	-- v1.4
			INTO #MaxRegs   
			FROM #VehicleRegistrationEvents NVRE
			INNER JOIN Vehicle.Registrations R ON R.RegistrationNumber = ISNULL(NVRE.RegNumber, '')
									AND COALESCE(R.RegistrationDate, @DummyDatetime) = COALESCE(NVRE.RegistrationDate, @DummyDatetime)
			WHERE ISNULL(NVRE.RegNumber, '') <> ''
			GROUP BY NVRE.RegNumber, ISNULL(NVRE.RegistrationDate, @DummyDatetime)     -- v1.4
		UNION
		 	SELECT '', RegistrationDate, MAX(RegistrationID)  
			from Vehicle.Registrations 
			where RegistrationNumber = '' AND RegistrationDate IS NOT NULL
			GROUP BY RegistrationDate


		-- MATCH EXISTING Reg Numbers FOR THE VEHICLE   -- v1.3
		UPDATE NVRE
		SET
			NVRE.RegistrationID = X.MaxRegistrationID,
			NVRE.NewRegistration = 0
		FROM #VehicleRegistrationEvents NVRE
		INNER JOIN #MaxRegs X 
					ON X.RegNumber = ISNULL(NVRE.RegNumber, '')
					AND COALESCE(X.RegistrationDate, @DummyDatetime) = COALESCE(NVRE.RegistrationDate, @DummyDatetime)    -- v1.4
					

		-- IF WE HAVEN'T MATCHED THE REG NUMBER SEE IF WE'VE GOT A REGISTRATION RECORD FOR THE VEHICLE - THIS SHOULD FIND THE REGISTRATION ID FOR DDW EVENTS
		UPDATE NVRE
		SET
			 NVRE.RegistrationID = R.RegistrationID
			,NVRE.RegNumber = R.RegistrationNumber
			,NVRE.RegistrationDate = R.RegistrationDate
			,NVRE.NewRegistration = 0
		FROM #VehicleRegistrationEvents NVRE
		INNER JOIN (
			SELECT VRE.VehicleID, MAX(R.RegistrationID) AS MaxRegistrationID
			FROM #VehicleRegistrationEvents VLU -- v1.2 Added in to return only the vehicles we are actually interested in - this will speed up the query
			INNER JOIN Vehicle.VehicleRegistrationEvents VRE ON VLU.VehicleID = VRE.VehicleID 
			INNER JOIN Vehicle.Registrations R ON R.RegistrationID = VRE.RegistrationID
			AND R.RegistrationNumber <> ''    --- v1.1
			GROUP BY VRE.VehicleID
		) X ON X.VehicleID = NVRE.VehicleID
		INNER JOIN Vehicle.Registrations R ON R.RegistrationID = X.MaxRegistrationID
		WHERE NVRE.RegistrationID = 0
		AND ISNULL(NVRE.RegNumber, '') = ''
		AND NVRE.RegistrationDate IS NULL


		-- MARK ANY RECORDS THAT ALREADY EXIST IN THE TABLE
		UPDATE NVRE
		SET NVRE.VehicleRegistrationEventExists = 1
		FROM #VehicleRegistrationEvents NVRE
		INNER JOIN Vehicle.VehicleRegistrationEvents VRE ON VRE.EventID = NVRE.EventID
												AND VRE.VehicleID = NVRE.VehicleID
												AND VRE.RegistrationID = NVRE.RegistrationID


		----------------------------------------------------------
		-- FIND DUPLICATE REG NUMBERS
		----------------------------------------------------------
		UPDATE R
		SET R.ParentVehicleRegistrationEventsID = M.ParentVehicleRegistrationEventsID
		FROM #VehicleRegistrationEvents R
		INNER JOIN (
			SELECT
				MAX(VehicleRegistrationEventsID) AS ParentVehicleRegistrationEventsID,
				VehicleID,
				RegNumber,
				RegistrationDate
			FROM #VehicleRegistrationEvents
			GROUP BY VehicleID, RegNumber, RegistrationDate
		) M ON M.VehicleID = R.VehicleID 
				AND M.RegNumber = R.RegNumber 
				AND COALESCE(M.RegistrationDate, @DummyDatetime) = COALESCE(R.RegistrationDate, @DummyDatetime)
		----------------------------------------------------------
		
		
		-- GET THE NEW REGISTRATIONS
		CREATE TABLE #NewVehicleRegistrationEvents
		(
			 NewVehicleRegistrationEventsID INT IDENTITY(1,1)
			,VehicleRegistrationEventsID INT
			,RegistrationID INT
		)

		INSERT INTO #NewVehicleRegistrationEvents (VehicleRegistrationEventsID)
		SELECT VehicleRegistrationEventsID
		FROM #VehicleRegistrationEvents
		WHERE RegistrationID = 0
		AND NewRegistration = 1
		AND (ISNULL(RegNumber, '') <> '' OR RegistrationDate IS NOT NULL)	
		AND VehicleRegistrationEventsID = ParentVehicleRegistrationEventsID		-- V1.5 EXCLUDE DUPLICATE REGISTRATIONS
		ORDER BY VehicleRegistrationEventsID

		-- GENERATE SOME NEW RegistrationIDs
		DECLARE @MaxRegistrationID INT

		SELECT @MaxRegistrationID = MAX(RegistrationID) FROM Vehicle.Registrations

		UPDATE #NewVehicleRegistrationEvents
		SET RegistrationID = NewVehicleRegistrationEventsID + @MaxRegistrationID

		-- WRITE THE NEW RegistrationIDs BACK TO #VehicleRegistrationEvents
		UPDATE V
		SET V.RegistrationID = N.RegistrationID
		FROM #NewVehicleRegistrationEvents N
		INNER JOIN #VehicleRegistrationEvents V ON V.ParentVehicleRegistrationEventsID = N.VehicleRegistrationEventsID

		DROP TABLE #NewVehicleRegistrationEvents


		-- INSERT THE NEW Registrations
		SET IDENTITY_INSERT Vehicle.Registrations ON
		INSERT INTO Vehicle.Registrations
		(
			RegistrationID,
			RegistrationNumber,
			RegistrationDate
		)
		SELECT DISTINCT		-- V1.5 SET DUPLICATE REGISTRATIONS
			VRE.RegistrationID,
			ISNULL(VRE.RegNumber, '') AS RegistrationNumber,
			VRE.RegistrationDate
		FROM #VehicleRegistrationEvents VRE
		LEFT JOIN Vehicle.Registrations R ON R.RegistrationID = VRE.RegistrationID
		WHERE VRE.NewRegistration = 1
		AND VRE.RegistrationID <> 0
		AND R.RegistrationID IS NULL
		SET IDENTITY_INSERT Vehicle.Registrations OFF

		INSERT INTO [$(AuditDB)].Audit.Registrations
		(
			RegistrationID,
			RegistrationNumber,
			RegistrationDateOrig,
			RegistrationDate,
			AuditItemID
		)
		SELECT DISTINCT
			COALESCE(NVRE.RegistrationID, I.RegistrationID),
			COALESCE(I.RegNumber, NVRE.RegNumber, '') AS RegistrationNumber,
			I.RegistrationDateOrig,
			COALESCE(I.RegistrationDate, NVRE.RegistrationDate),
			I.AuditItemID
		FROM INSERTED I 
		LEFT JOIN #VehicleRegistrationEvents NVRE ON NVRE.EventID = I.EventID
													AND NVRE.VehicleID = I.VehicleID
		LEFT JOIN [Sample_Audit].Audit.Registrations AR ON AR.AuditItemID = I.AuditItemID
		WHERE AR.AuditItemID IS NULL
		AND NVRE.RegistrationID <> 0

		-- INSERT THE VehicleRegistrationEvents
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
		WHERE N.VehicleRegistrationEventExists = 0
		AND N.RegistrationID <> 0
		AND VRE.VehicleID IS NULL

		INSERT INTO [$(AuditDB)].Audit.VehicleRegistrationEvents
		(
			AuditItemID,
			VehicleID,
			RegistrationID,
			EventID
		)
		SELECT DISTINCT
			I.AuditItemID,
			I.VehicleID,
			COALESCE(NVRE.RegistrationID, I.RegistrationID),
			I.EventID
		FROM INSERTED I 
		LEFT JOIN #VehicleRegistrationEvents NVRE ON NVRE.EventID = I.EventID
													AND NVRE.VehicleID = I.VehicleID
													AND NVRE.RegNumber = COALESCE(I.RegNumber, NVRE.RegNumber)
		LEFT JOIN [$(AuditDB)].Audit.VehicleRegistrationEvents AVRE ON AVRE.AuditItemID = I.AuditItemID
		WHERE AVRE.AuditItemID IS NULL


		-- UPDATE THE VWT WITH THE NEW REGISTRATION IDS
		UPDATE V
		SET V.ODSRegistrationID = NVRE.RegistrationID
		FROM #VehicleRegistrationEvents NVRE
		INNER JOIN [$(ETLDB)].dbo.VWT V ON V.MatchedODSEventID = NVRE.EventID
											AND V.MatchedODSVehicleID = NVRE.VehicleID
											
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



