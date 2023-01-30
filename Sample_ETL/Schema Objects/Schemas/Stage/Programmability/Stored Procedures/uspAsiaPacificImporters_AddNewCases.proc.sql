CREATE PROCEDURE Stage.uspAsiaPacificImporters_AddNewCases

AS

/*
		Purpose:	SP to load new cases
	
		Version		Date			Developer			Comment
LIVE	1.0			2021-10-12		Chris Ledger		Created
LIVE	1.1			2022-02-08		Chris Ledger		Only add new cases
LIVE	1.2			2022-04-04		Chris Ledger		Fix bug in adding of new cases
LIVE	1.3			2022-04-08		Chris Ledger		Task 850: only create new cases if data validated
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

		-- CREATE A TABLE TO HOLD THE SELECTED EVENTS (NEW CASES)
		DECLARE @NewCases TABLE
		(
			ID INT IDENTITY(1, 1),
			CaseStatusTypeID TINYINT,
			CaseID INT,
			EventID BIGINT,
			PartyID INT, 
			VehicleRoleTypeID SMALLINT, 
			VehicleID BIGINT
		)


		-- GET THE NEW CASES
		INSERT INTO @NewCases
		(
			CaseStatusTypeID,
			EventID,
			PartyID,
			VehicleRoleTypeID,
			VehicleID
		)
		SELECT DISTINCT
			3 AS CaseStatusTypeID,
			API.EventID,
			40 AS PartyID,
			1 AS VehicleRoleTypeID,
			API.VehicleID
		FROM Stage.AsiaPacificImporters API
		WHERE ISNULL(API.CaseID,0) = 0				-- V1.1, V1.2
			AND ISNULL(API.ValidatedData,0) = 1		-- V1.3


		-- GENERATE THE NEW CASEIDS
		DECLARE @MaxCaseID INT
		SELECT @MaxCaseID = ISNULL(MAX(CaseID), 0) FROM [$(SampleDB)].Event.Cases

		UPDATE @NewCases
		SET CaseID = ID + @MaxCaseID


		-- INSERT THE NEW CASES
		INSERT INTO [$(SampleDB)].Event.Cases (CaseID, CaseStatusTypeID)
		SELECT NC.CaseID, 
			NC.CaseStatusTypeID
		FROM @NewCases NC


		-- INSERT THE NEW AUTOMOTIVEEVENTBASEDINTERVIEWS
		INSERT INTO [$(SampleDB)].Event.AutomotiveEventBasedInterviews (CaseID, EventID, PartyID, VehicleRoleTypeID, VehicleID)
		SELECT NC.CaseID, 
			NC.EventID, 
			NC.PartyID, 
			NC.VehicleRoleTypeID, 
			NC.VehicleID
		FROM @NewCases NC


		-- WRITE BACK NEWLY CREATED CASE IDS TO ASIA_PACIFIC_IMPORTERS
		UPDATE API
		SET API.CaseID = AEBI.CaseID
		FROM Stage.AsiaPacificImporters API
			INNER JOIN [$(SampleDB)].Event.AutomotiveEventBasedInterviews AEBI ON API.EventID = AEBI.EventID


		-- AUDIT NEW CASES
		INSERT INTO [$(AuditDB)].Audit.Cases
		(
			AuditItemID,
			PartyCaseIDComboValid,
			CaseID,
			PartyID,
			CaseStatusTypeID,
			CreationDate
		)	
		SELECT DISTINCT 
			API.AuditItemID,
			CASE	WHEN AEBI.CaseID IS NULL THEN 0
					ELSE 1 END AS PartyCaseIDComboValid,	
			NC.CaseID,
			NC.PartyID,
			NC.CaseStatusTypeID,
			C.CreationDate
		FROM @NewCases NC
			INNER JOIN [$(SampleDB)].Event.Cases C ON NC.CaseID = C.CaseID
			INNER JOIN Stage.AsiaPacificImporters API ON NC.CaseID = API.CaseID
			LEFT JOIN [$(AuditDB)].Audit.Cases AC ON AC.AuditItemID = API.AuditItemID
			LEFT JOIN [$(SampleDB)].Event.AutomotiveEventBasedInterviews AEBI ON NC.CaseID = AEBI.CaseID
																				AND NC.PartyID = AEBI.PartyID
		WHERE AC.AuditItemID IS NULL

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