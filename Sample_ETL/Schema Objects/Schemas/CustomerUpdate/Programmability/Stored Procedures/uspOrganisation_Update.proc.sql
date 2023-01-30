CREATE PROCEDURE CustomerUpdate.uspOrganisation_Update

AS

/*
	Purpose:	Update Organisations and Legal Organisations with the data from the customer update and load into Audit.
				This is only for existing organisation parties

	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created from [Prophet-ETL].dbo.uspIP_CUSTOMERUPDATE_ODSUpdate_Organisation
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
	
		-- Check the CaseID and PartyID combination is valid  -- v1.1 Added as the running order of the 2 proc's seems to be reversed in the package.  Rather start messing with that now, I have 
																	-- simply included the CasePartyCombinationValid check here as well.  This whole process needs looking at.
		UPDATE CUO
		SET CUO.CasePartyCombinationValid = 1
		FROM CustomerUpdate.Organisation CUO
		INNER JOIN [$(SampleDB)].Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = CUO.CaseID
																	AND AEBI.PartyID = CUO.PartyID
		WHERE ISNULL(CUO.OrganisationName,'') <> ''	-- v1.1
	

		-- Set the OrganisationPartyID value and PartyTypeFlag to 'O', i.e. Organisation
		UPDATE CUO
		SET CUO.OrganisationPartyID = O.PartyID,
		CUO.PartyTypeFlag = 'O'
		FROM CustomerUpdate.Organisation CUO
		INNER JOIN [$(SampleDB)].Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = CUO.CaseID
																	AND AEBI.PartyID = CUO.PartyID
		INNER JOIN [$(SampleDB)].Party.Organisations O ON O.PartyID = AEBI.PartyID
		WHERE CUO.PartyTypeFlag IS NULL
		AND CUO.CasePartyCombinationValid = 1  -- v1.1
		
		
		
		-- We can receive a person update for a party that we only had organisation details for.  
		-- When this happens we add the People details to the existing party and copy the existing
		-- organisation party to a new party.  We then create a PartyRelationship between the new Person
		-- party and the copied Organisation party.  
		-- If we receive an Organisation update for a party that we have updated in this way we need to update 
		-- the organisation name for the copied Organisation party.  
		-- To do this we create a new row in CustomerUpdate.Organisation with the copied organisation PartyID
		INSERT INTO CustomerUpdate.Organisation
		(
			PartyID,
			CaseID,
			OrganisationName,
			AuditID,
			AuditItemID,
			ParentAuditItemID,
			CasePartyCombinationValid,
			OrganisationPartyID,
			PartyTypeFlag
		)
		SELECT DISTINCT
			CUO.PartyID,
			CUO.CaseID,
			CUO.OrganisationName,
			CUO.AuditID,
			CUO.AuditItemID,
			CUO.ParentAuditItemID,
			CUO.CasePartyCombinationValid,
			O_NEW.PartyID AS OrganisationPartyID,
			CUO.PartyTypeFlag
		FROM CustomerUpdate.Organisation CUO
		INNER JOIN [$(SampleDB)].Party.Organisations O ON O.PartyID = CUO.PartyID
		INNER JOIN [$(AuditDB)].Audit.CustomerUpdate_Person ACUP ON ACUP.PartyID = CUO.PartyID
															AND ACUP.CaseID = CUO.CaseID
		INNER JOIN [$(AuditDB)].Audit.PartyRelationships APR ON APR.AuditItemID = ACUP.AuditItemID
														AND APR.PartyIDFrom = ACUP.PartyID
		INNER JOIN [$(SampleDB)].Party.PartyRelationships PR ON PR.PartyIDFrom = APR.PartyIDFrom
														AND PR.PartyIDTo = APR.PartyIDTo
														AND PR.RoleTypeIDFrom = APR.RoleTypeIDFrom
														AND PR.RoleTypeIDTo = APR.RoleTypeIDTo
		INNER JOIN [$(SampleDB)].Party.Organisations O_NEW ON O_NEW.PartyID = PR.PartyIDTo
														AND O_NEW.OrganisationName = O.OrganisationName
		WHERE CUO.PartyTypeFlag = 'O'
		AND CUO.CasePartyCombinationValid = 1  -- v1.1


		-- we only update the organisation name if the PartyID supplied is for an existing organisation party
		-- Organisations
		UPDATE O
		SET
			O.OrganisationName = CUO.OrganisationName
		FROM CustomerUpdate.Organisation CUO
		INNER JOIN [$(SampleDB)].Party.Organisations O ON O.PartyID = CUO.OrganisationPartyID
		WHERE CUO.AuditItemID = CUO.ParentAuditItemID
		AND CUO.PartyTypeFlag = 'O'
		AND CUO.CasePartyCombinationValid = 1  -- v1.1

		-- we only update the organisation name if the PartyID supplied is for an existing organisation party
		-- LegalOrganisations
		UPDATE LO
		SET
			LO.LegalName = CUO.OrganisationName
		FROM CustomerUpdate.Organisation CUO
		INNER JOIN [$(SampleDB)].Party.LegalOrganisations LO ON LO.PartyID = CUO.OrganisationPartyID
		WHERE CUO.AuditItemID = CUO.ParentAuditItemID
		AND CUO.PartyTypeFlag = 'O'
		AND CUO.CasePartyCombinationValid = 1  -- v1.1


		-- we only insert the organisation name update if the PartyID supplied is for an existing organisation party
		-- Audit Organisations
		INSERT INTO [$(AuditDB)].Audit.Organisations
		(
			AuditItemID,
			PartyID,
			FromDate,
			OrganisationName
		)
		SELECT
			CUO.AuditItemID,
			CUO.OrganisationPartyID,
			GETDATE(),
			CUO.OrganisationName
		FROM CustomerUpdate.Organisation CUO
		INNER JOIN [$(SampleDB)].Party.Organisations LO ON LO.PartyID = CUO.OrganisationPartyID
		LEFT JOIN [$(AuditDB)].Audit.Organisations AO ON AO.AuditItemID = CUO.AuditItemID
								AND AO.PartyID = CUO.OrganisationPartyID
		WHERE CUO.AuditItemID = CUO.ParentAuditItemID
		AND CUO.PartyTypeFlag = 'O'
		AND AO.AuditItemID IS NULL
		AND CUO.CasePartyCombinationValid = 1  -- v1.1

		-- Audit LegalOrganisations
		INSERT INTO [$(AuditDB)].Audit.LegalOrganisations
		(
			AuditItemID,
			PartyID,
			LegalName
		)
		SELECT
			CUO.AuditItemID,
			CUO.OrganisationPartyID,
			CUO.OrganisationName
		FROM CustomerUpdate.Organisation CUO
		INNER JOIN [$(SampleDB)].Party.LegalOrganisations LO ON LO.PartyID = CUO.OrganisationPartyID
		LEFT JOIN [$(AuditDB)].Audit.LegalOrganisations ALO ON ALO.AuditItemID = CUO.AuditItemID
								AND ALO.PartyID = CUO.OrganisationPartyID
		WHERE CUO.AuditItemID = CUO.ParentAuditItemID
		AND CUO.PartyTypeFlag = 'O'
		AND ALO.AuditItemID IS NULL
		AND CUO.CasePartyCombinationValid = 1  -- v1.1

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








