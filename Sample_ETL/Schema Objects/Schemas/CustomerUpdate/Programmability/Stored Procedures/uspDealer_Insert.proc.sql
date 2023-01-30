CREATE PROCEDURE CustomerUpdate.uspDealer_Insert

AS

/*
	Purpose:	Add any new rows to EventPartyRoles with the data from CustomerUpdate.Dealer and load into Audit
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)	Simon Peacock		Created from [Prophet-ETL].dbo.uspIP_CUSTOMERUPDATE_ODSInsert_Dealer
	1.1				27/01/2016		Chris Ross			BUG 12038 - Add in PreOwned RoleTypeabl
	1.2				25/08/2016		Chris Ross			BUG 12859 - Add in Lost Leads RoleType and updates to Sample Logging table
	1.3				09/08/2017		Chris Ledger		BUG 13922 - Add in Bodyshop RoleType - UAT
	1.4				02/10/2019		Chris Ledger		BUG 15460 - Add in PreOwned LostLeads 
	1.5				17/10/2019		Chris Ledger		BUG 16673 - Add in CQI3MIS and CQI24MIS
	1.6				18/02/2020		Chris Ledger		BUG 17942 - Add in MCQI1MIS
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

		-- FIND OUT WHICH ROWS ARE FOR EVENTS THAT WE DON'T ALREADY HAVE A VALUE IN EventPartyRoles
		UPDATE CUD
		SET	CUD.NewDealer = 1,
			CUD.EventID = AEBI.EventID
		FROM CustomerUpdate.Dealer CUD
		INNER JOIN [$(SampleDB)].Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = CUD.CaseID
		LEFT JOIN [$(SampleDB)].Event.EventPartyRoles EPR ON EPR.EventID = AEBI.EventID
		WHERE CUD.DealerPartyID > 0
		AND EPR.EventID IS NULL

		-- FIND OUT THE RoleTypeID OF THE DEALER
		UPDATE CUD
		SET 	CUD.RoleTypeID = CASE BMQ.Questionnaire
					WHEN 'Bodyshop' THEN (SELECT TOP 1 RoleTypeID FROM [$(SampleDB)].dbo.vwBodyshopDealerRoleTypes)				-- V1.3
					WHEN 'Sales' THEN (SELECT TOP 1 RoleTypeID FROM [$(SampleDB)].dbo.vwSalesDealerRoleTypes)
					WHEN 'LostLeads' THEN (SELECT TOP 1 RoleTypeID FROM [$(SampleDB)].dbo.vwSalesDealerRoleTypes)
					WHEN 'PreOwned' THEN (SELECT TOP 1 RoleTypeID FROM [$(SampleDB)].dbo.vwPreOwnedDealerRoleTypes)				-- v1.1
					WHEN 'PreOwned LostLeads' THEN (SELECT TOP 1 RoleTypeID FROM [$(SampleDB)].dbo.vwPreOwnedDealerRoleTypes)	-- V1.4
					WHEN 'Service' THEN (SELECT TOP 1 RoleTypeID FROM [$(SampleDB)].dbo.vwServiceDealerRoleTypes)
					WHEN 'CQI 3MIS' THEN (SELECT TOP 1 RoleTypeID FROM [$(SampleDB)].dbo.vwSalesDealerRoleTypes)				-- V1.5
					WHEN 'CQI 24MIS' THEN (SELECT TOP 1 RoleTypeID FROM [$(SampleDB)].dbo.vwSalesDealerRoleTypes)				-- V1.5
					WHEN 'MCQI 1MIS' THEN (SELECT TOP 1 RoleTypeID FROM [$(SampleDB)].dbo.vwSalesDealerRoleTypes)				-- V1.6
				END,
			CUD.ManufacturerPartyID = BMQ.ManufacturerPartyID
		FROM CustomerUpdate.Dealer CUD
		INNER JOIN [$(SampleDB)].Requirement.SelectionCases SC ON SC.CaseID = CUD.CaseID
		INNER JOIN [$(SampleDB)].Requirement.RequirementRollups SQ ON SQ.RequirementIDMadeUpOf = SC.RequirementIDPartOf
		INNER JOIN [$(SampleDB)].dbo.vwBrandMarketQuestionnaireSampleMetadata BMQ ON BMQ.QuestionnaireRequirementID = SQ.RequirementIDPartOf
		WHERE CUD.NewDealer = 1


		/* LOAD INTO ODS */

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
		WHERE NewDealer = 1
		AND RoleTypeID IS NOT NULL
		AND EventID IS NOT NULL
		AND DealerCode IS NOT NULL


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
		WHERE NewDealer = 1
		AND RoleTypeID IS NOT NULL
		AND EventID IS NOT NULL
		AND DealerCode IS NOT NULL

		-- Update Sales Dealer Codes
		UPDATE SL
		SET SL.SalesDealerCode = LU.DealerCode,
			SL.SalesDealerID = LU.DealerPartyID 
		FROM #SampleLoggingUpdates LU
		INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL ON SL.AuditItemID = LU.AuditItemID 
		WHERE LU.Questionnaire IN ('Sales', 'LostLeads', 'PreOwned', 'Bodyshop', 'PreOwned LostLeads', 'CQI 3MIS', 'CQI 24MIS', 'MCQI 1MIS') 		-- V1.3, V1.4, V1.5, V1.6

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






