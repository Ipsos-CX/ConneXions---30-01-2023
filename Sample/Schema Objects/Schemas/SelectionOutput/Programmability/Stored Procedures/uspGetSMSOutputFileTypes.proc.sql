CREATE PROCEDURE [SelectionOutput].[uspGetSMSOutputFileTypes]
@Brand VARCHAR (100), @Market VARCHAR (100), @Questionnaire VARCHAR (100)
AS

/*
	Purpose:	Get SMS Output File Types
	
	Version			Date			Developer			Comment
	1.1				21/01/2020		Chris Ledger		BUG 15372: Fix Hard coded references to databases.
*/


SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	SELECT		DISTINCT	
				m.SMSOutputFileExtension			
	FROM		SelectionOutput.Merged_SMS						S
	INNER JOIN	dbo.Markets										m	ON S.Ccode						= M.CountryID
	INNER JOIN	dbo.vwBrandMarketQuestionnaireSampleMetadata	MD	ON M.CountryID					= MD.CountryID
	INNER JOIN	SelectionOutput.ContactMethodologyTypes			CMT ON CMT.ContactMethodologyTypeID = MD.ContactMethodologyTypeID
	INNER JOIN
	(
		SELECT		DISTINCT
						
					BMQ.Brand,
					BMQ.Market,
					BMQ.Questionnaire,
					SR.RequirementID AS SelectionRequirementID
		FROM		Requirement.SelectionRequirements				SR
		INNER JOIN	Requirement.RequirementRollups					SQ ON SQ.RequirementIDMadeUpOf = SR.RequirementID
		INNER JOIN	Requirement.QuestionnaireRequirements			QR ON QR.RequirementID			= SQ.RequirementIDPartOf
		INNER JOIN	Event.EventCategories							EC ON EC.EventCategoryID		= QR.EventCategoryID
		INNER JOIN	dbo.vwBrandMarketQuestionnaireSampleMetadata	BMQ ON	BMQ.CountryID			= QR.CountryID AND 
																			BMQ.ManufacturerPartyID = QR.ManufacturerPartyID AND 
																			BMQ.Questionnaire		= EC.EventCategory
		INNER JOIN	Requirement.SelectionCases						SC	ON	SR.RequirementID		= SC.RequirementIDPartOf
		INNER JOIN	SelectionOutput.Merged_SMS						MS	ON	SC.CaseID				= MS.ID
	
		WHERE		(BMQ.SelectionOutputActive = 1) AND 
					(QR.ManufacturerPartyID IN (SELECT ManufacturerPartyID FROM dbo.Brands)) AND	
					(BMQ.Brand		= @Brand) AND
					(BMQ.Market		= @Market) AND
					(BMQ.Questionnaire = @Questionnaire)  AND
					(MS.DateOutput IS NULL)

	) N ON MD.Brand = N.Brand AND MD.Questionnaire = N.Questionnaire AND MD.Market = N.Market
	WHERE S.DateOutput IS NULL

END TRY
BEGIN CATCH

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
		
	IF @@TRANCOUNT > 0
	BEGIN
		ROLLBACK TRAN
	END
		
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH