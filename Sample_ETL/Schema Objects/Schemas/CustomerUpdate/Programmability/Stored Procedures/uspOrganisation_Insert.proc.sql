CREATE PROCEDURE CustomerUpdate.uspOrganisation_Insert

AS

/*
	Purpose:	Insert into Organisations the data from customer update file and load into Audit.
				We only insert an organisation name for a person party.
				We then create a PartyRelationship between the person and organisation parties.  

	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created from [Prophet-ETL].dbo.uspIP_CUSTOMERUPDATE_ODSInsert_Organisation
	1.1				05/06/2017		Chris Ross			BUG 14039 - Add in a check into CasePartyCombinationValid that the checks Organisation is populated too. 

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

		-- Check the CaseID and PartyID combination is valid
		UPDATE CUO
		SET CUO.CasePartyCombinationValid = 1
		FROM CustomerUpdate.Organisation CUO
		INNER JOIN [$(SampleDB)].Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = CUO.CaseID
																	AND AEBI.PartyID = CUO.PartyID
		WHERE ISNULL(CUO.OrganisationName,'') <> ''	-- v1.1

		-- Set the PartyTypeFlag to 'P', i.e. People, for all people parties supplied
		UPDATE CUO
		SET CUO.PartyTypeFlag = 'P'
		FROM CustomerUpdate.Organisation CUO
		INNER JOIN [$(SampleDB)].Party.People P ON P.PartyID = CUO.PartyID
		LEFT JOIN [$(SampleDB)].Party.Organisations O ON O.PartyID = CUO.PartyID
		WHERE CUO.CasePartyCombinationValid = 1
		AND O.PartyID IS NULL


		-- Check if we've already got a party and organisation relationship
		-- if so we get the organisation PartyID and set the PartyTypeFlag to 'O' for Organisation
		-- this will now get processed by CustomerUpdate.uspOrganisation_Update
		UPDATE CUO
		SET CUO.OrganisationPartyID = CASE WHEN ER.PartyIDFrom IS NOT NULL THEN ER.PartyIDTo ELSE 0 END,
		CUO.PartyTypeFlag = CASE WHEN ER.PartyIDFrom IS NOT NULL THEN 'O' ELSE CUO.PartyTypeFlag END
		FROM CustomerUpdate.Organisation CUO
		LEFT JOIN (
			SELECT
				ER.PartyIDFrom,
				ER.PartyIDTo
			FROM [$(SampleDB)].Party.EmployeeRelationships ER
			INNER JOIN [$(SampleDB)].Party.Organisations O ON O.PartyID = ER.PartyIDTo
		) ER ON ER.PartyIDFrom = CUO.PartyID
		WHERE CUO.PartyTypeFlag = 'P'
		AND CUO.CasePartyCombinationValid = 1		--v1.1

		-- Create some new organisation parties
		INSERT INTO [$(SampleDB)].Party.vwDA_LegalOrganisations
		(
			PartyID, 
			FromDate, 
			OrganisationName,
			ParentAuditItemID,
			AuditItemID
		)
		SELECT
			OrganisationPartyID,
			GETDATE(),
			OrganisationName,
			ParentAuditItemID,
			AuditItemID
		FROM CustomerUpdate.Organisation
		WHERE PartyTypeFlag = 'P'
		AND CasePartyCombinationValid = 1  -- v1.1

		-- Get the newly created PartyIDs
		UPDATE CUO
		SET CUO.OrganisationPartyID = AO.PartyID
		FROM CustomerUpdate.Organisation CUO
		INNER JOIN [$(AuditDB)].Audit.Organisations AO ON AO.AuditItemID = CUO.ParentAuditItemID
		WHERE CUO.PartyTypeFlag = 'P'
		AND CUO.CasePartyCombinationValid = 1  -- v1.1


		-- Now we create new EmployeeRelationships for these people and organisation parties
		INSERT INTO [$(SampleDB)].Party.vwDA_EmployeeRelationships
		(
			AuditItemID,
			PartyIDFrom,
			RoleTypeIDFrom,
			PartyIDTo,
			RoleTypeIDTo,
			FromDate,
			PartyRelationshipTypeID,
			EmployeeIdentifier,
			EmployeeIdentifierUsable
		)
		SELECT
			AuditItemID,
			PartyID,
			(SELECT RoleTypeID FROM [$(SampleDB)].dbo.RoleTypes WHERE RoleType = 'Employee') AS RoleTypeIDFrom,
			OrganisationPartyID,
			(SELECT RoleTypeID FROM [$(SampleDB)].dbo.RoleTypes WHERE RoleType = 'Employer') AS RoleTypeIDTo,
			GETDATE() AS FromDate,
			1 AS PartyRelationshipTypeID,
			'' AS EmployeeIdentifier,
			1 AS EmployeeIdentifierUsable
		FROM CustomerUpdate.Organisation
		WHERE PartyTypeFlag = 'P'
		AND CasePartyCombinationValid = 1  -- v1.1

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
