CREATE PROC [SelectionOutput].[uspGetOutputFileTypes]
(
	@Brand  VARCHAR(100),
	@Market VARCHAR(100),
	@Questionnaire VARCHAR(100)
)
AS

/*
	Purpose:	Returns flags indicating whether or not we need to run the output for the different file types
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created from [Prophet-ODS].dbo.uspSELECTIONOUTPUT_JLR_GetOutputFileTypes
	1.1				16/01/2014		Chris Ross			BUG 9500 - Add in SMS output
	1.2				05/12/2014		Chris Ross			BUG 11025 - Set the SMS output to be 0 if the market is SMS Output by Language
	1.3				19/06/2019		Eddie Thomas		BUG 15440/15441 - Using alternative Output format based on new flag AltSMSOutputFile 
*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	SELECT DISTINCT
		 CMT.PostalOutput
		,CMT.TelephoneOutput
		,CASE WHEN m.SMSOutputByLanguage = 1 THEN CAST(0 AS BIT) ELSE CMT.SMSOutput END AS SMSOutput
		,CASE
			WHEN ISNULL(N.SelectionRequirementID, 0) > 0 THEN CAST(1 AS BIT)
			ELSE CAST(0 AS BIT)
		END AS NonOutput,
		m.SMSOutputFileExtension, 
		m.AltSMSOutputFile			--V1.3	
	FROM SelectionOutput.SelectionsToOutput O
	INNER JOIN ContactMechanism.Countries c ON c.ISOAlpha3 = O.Market
	INNER JOIN dbo.Markets m ON m.CountryId = c.CountryID
	INNER JOIN SelectionOutput.ContactMethodologyTypes CMT ON CMT.ContactMethodologyTypeID = O.ContactMethodologyTypeID
	LEFT JOIN
	(
		SELECT DISTINCT SC.RequirementIDPartOf AS SelectionRequirementID
		FROM SelectionOutput.NonOutput N
		INNER JOIN Requirement.SelectionCases SC ON SC.CaseID = N.CaseID
	) N ON N.SelectionRequirementID = O.SelectionRequirementID
	WHERE O.Brand = @Brand
	AND O.Market = @Market
	AND O.Questionnaire = @Questionnaire

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