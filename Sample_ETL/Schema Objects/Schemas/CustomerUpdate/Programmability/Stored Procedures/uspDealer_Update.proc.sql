CREATE PROCEDURE CustomerUpdate.uspDealer_Update

AS

/*
	Purpose:	Update EventPartyRoles with the data from CustomerUpdate.Dealer and load into Audit
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)	Simon Peacock		Created from [Prophet-ETL].dbo.uspIP_CUSTOMERUPDATE_ODSUpdate_Dealer
	1.1				25-08-2016		Chris Ross			BUG 12859 - Add in Sample Logging table updates
	1.2				09-08-2017		Chris Ledger		BUG 13922 - Add in Bodyshop RoleType - UAT 
	1.3				02-10-2019		Chris Ledger		BUG 15460 - Add in PreOwned LostLeads questionnaire
	1.4				17-10-2019		Chris Ledger		BUG 16683 - Add in CQI questionnaires
	1.5				18-02-2020		Chris Ledger		BUG 17942 - Add in MCQI questionnaire
*/


SET NOCOUNT ON

	DECLARE @ErrorNumber INT
	DECLARE @ErrorSeverity INT
	DECLARE @ErrorState INT
	DECLARE @ErrorLocation NVARCHAR(500)
	DECLARE @ErrorLine INT
	DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	-- NB. RUN CustomerUpdate.uspDealer_Update BEFORE THIS

	BEGIN TRAN

		-- GET THE RoleTypeID
		UPDATE CUD
		SET
			CUD.RoleTypeID = EPR.RoleTypeID
		FROM CustomerUpdate.Dealer CUD
		INNER JOIN [$(SampleDB)].Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = CUD.CaseID AND AEBI.PartyID = CUD.PartyID
		INNER JOIN [$(SampleDB)].Event.EventPartyRoles EPR ON EPR.EventID = AEBI.EventID
		INNER JOIN [$(SampleDB)].Party.DealerNetworks DN_CURRENT ON DN_CURRENT.PartyIDFrom = EPR.PartyID AND DN_CURRENT.RoleTypeIDFrom = EPR.RoleTypeID
		INNER JOIN [$(SampleDB)].dbo.Brands B ON B.ManufacturerPartyID = DN_CURRENT.PartyIDTo
		WHERE CUD.ParentAuditItemID = CUD.AuditItemID
		AND CUD.DealerPartyID > 0

		-- CHECK THE DealerPartyID SUPPLIED IS VALID
		UPDATE CUD
		SET
			CUD.DealerPartyIDValid = 1,
			CUD.EventID = AEBI.EventID,
			CUD.DealerCode = DN_NEW.DealerCode,
			CUD.ManufacturerPartyID = B.ManufacturerPartyID
		FROM CustomerUpdate.Dealer CUD
		INNER JOIN [$(SampleDB)].Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = CUD.CaseID AND AEBI.PartyID = CUD.PartyID
		INNER JOIN [$(SampleDB)].Event.EventPartyRoles EPR ON EPR.EventID = AEBI.EventID
		INNER JOIN [$(SampleDB)].Party.DealerNetworks DN_CURRENT ON DN_CURRENT.PartyIDFrom = EPR.PartyID AND DN_CURRENT.RoleTypeIDFrom = EPR.RoleTypeID
		INNER JOIN [$(SampleDB)].dbo.Brands B ON B.ManufacturerPartyID = DN_CURRENT.PartyIDTo
		INNER JOIN [$(SampleDB)].Party.DealerNetworks DN_NEW ON DN_NEW.PartyIDFrom = CUD.DealerPartyID AND DN_NEW.RoleTypeIDFrom = DN_CURRENT.RoleTypeIDFrom AND DN_NEW.PartyIDTo = DN_CURRENT.PartyIDTo
		WHERE CUD.ParentAuditItemID = CUD.AuditItemID
		AND CUD.DealerPartyID > 0

		-- IF DealerPartyID = 0 WE WANT TO DELETE THE EXISTING DATA FROM EventPartyRoles
		UPDATE CUD
		SET
			CUD.DeleteEventPartyRole = 1,
			CUD.EventID = AEBI.EventID,
			CUD.RoleTypeID = EPR.RoleTypeID
		FROM CustomerUpdate.Dealer CUD
		INNER JOIN [$(SampleDB)].Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = CUD.CaseID AND AEBI.PartyID = CUD.PartyID
		INNER JOIN [$(SampleDB)].Event.EventPartyRoles EPR ON EPR.EventID = AEBI.EventID
		WHERE CUD.ParentAuditItemID = CUD.AuditItemID
		AND CUD.DealerPartyID = 0


		/* LOAD INTO ODS */

		-- DELETE THE EXISTING EventPartyRoles WHERE WE'VE GOT A NEW DealerPartyID
		DELETE EPR
		FROM CustomerUpdate.Dealer CUD
		INNER JOIN [$(SampleDB)].Event.EventPartyRoles EPR ON EPR.EventID = CUD.EventID AND EPR.RoleTypeID = CUD.RoleTypeID
		WHERE CUD.DealerPartyIDValid = 1

		-- DELETE THE EXISTING EventPartyRoles WHERE WE'VE BEEN SUPPLIED WITH DealerPartyID = 0
		DELETE EPR
		FROM CustomerUpdate.Dealer CUD
		INNER JOIN [$(SampleDB)].Event.EventPartyRoles EPR ON EPR.EventID = CUD.EventID AND EPR.RoleTypeID = CUD.RoleTypeID
		WHERE CUD.DeleteEventPartyRole = 1

		-- ADD THE NEW DealerPartyID INTO EventPartyRoles
		INSERT INTO [$(SampleDB)].Event.vwDA_EventPartyRoles
		(
			AuditItemID,
			PartyID,
			RoleTypeID,
			EventID,
			DealerCode
		)
		SELECT DISTINCT
			AuditItemID,
			DealerPartyID,
			RoleTypeID,
			EventID,
			DealerCode
		FROM CustomerUpdate.Dealer
		WHERE DealerPartyID IS NOT NULL
		AND RoleTypeID IS NOT NULL
		AND EventID IS NOT NULL

		-----------------------------------------------------------------
		-- UPDATE the Sample Logging tables 
		-----------------------------------------------------------------

		--- Get records to update
		SELECT SL.AuditItemID, SL.Questionnaire, CUD.CaseID, CUD.DealerPartyID, CUD.DealerCode
		INTO #SampleLoggingUpdates
		FROM CustomerUpdate.Dealer CUD
		INNER JOIN [$(SampleDB)].Requirement.SelectionCases SC ON SC.CaseID = CUD.CaseID
		INNER JOIN [$(SampleDB)].Requirement.RequirementRollups SQ ON SQ.RequirementIDMadeUpOf = SC.RequirementIDPartOf
		INNER JOIN [$(SampleDB)].dbo.vwBrandMarketQuestionnaireSampleMetadata BMQ ON BMQ.QuestionnaireRequirementID = SQ.RequirementIDPartOf
		INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL ON SL.CaseID = CUD.CaseID
		WHERE DealerPartyID IS NOT NULL
		AND RoleTypeID IS NOT NULL
		AND EventID IS NOT NULL

		-- Update Sales Dealer Codes
		UPDATE SL
		SET SL.SalesDealerCode = LU.DealerCode,
			SL.SalesDealerID = LU.DealerPartyID 
		FROM #SampleLoggingUpdates LU
		INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL ON SL.AuditItemID = LU.AuditItemID 
		WHERE LU.Questionnaire IN ('Sales', 'LostLeads', 'PreOwned', 'Bodyshop', 'PreOwned LostLeads', 'CQI 3MIS', 'CQI 24MIS', 'MCQI 1MIS') 		-- V1.3, V1.4, V1.5

		-- Update Service Dealer Codes
		UPDATE SL
		SET SL.ServiceDealerCode = LU.DealerCode,
			SL.ServiceDealerID = LU.DealerPartyID 
		FROM #SampleLoggingUpdates LU
		INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL ON SL.AuditItemID = LU.AuditItemID 
		WHERE LU.Questionnaire IN ('Service') 		
	

	
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














