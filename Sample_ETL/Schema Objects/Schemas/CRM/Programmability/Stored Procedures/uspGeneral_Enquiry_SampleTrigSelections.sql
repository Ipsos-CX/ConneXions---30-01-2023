CREATE PROCEDURE [CRM].[uspGeneral_Enquiry_SampleTrigSelections]

AS

/*
		Purpose:	Create any required Sample Triggered Selections
	
		Version		Developer			Created			Comment
LIVE	1.0			Chris Ledger		10/01/2020		TASK 299
LIVE	1.1			Chris Ledger		22/09/2021		TASK 502 - Reformat
*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	----------------------------------------------------------------------------------------------------
	-- Set SampleTriggeredSelectionReqIDs where appropriate					
	----------------------------------------------------------------------------------------------------
	;WITH CTE_GE_BMQs AS 
	(
		SELECT DISTINCT M.ManufacturerPartyID,
			M.CountryID,
			M.CreateSelection,
			M.SampleTriggeredSelection,
			M.QuestionnaireRequirementID ,
			M.SampleFileNamePrefix
		FROM [$(SampleDB)].dbo.vwBrandMarketQuestionnaireSampleMetadata	M
			INNER JOIN [$(SampleDB)].[Event].EventTypes ET ON ET.EventType = M.Questionnaire
			INNER JOIN [$(SampleDB)].ContactMechanism.Countries C ON C.CountryID = M.CountryID
		WHERE M.Questionnaire = 'CRC General Enquiry' 
			AND M.SampleLoadActive = 1
	)
	UPDATE V
	SET SampleTriggeredSelectionReqID = CASE	WHEN BMQ.CreateSelection = 1 AND BMQ.SampleTriggeredSelection = 1 THEN BMQ.QuestionnaireRequirementID
												ELSE 0 END
	FROM CRM.General_Enquiry GE
		INNER JOIN dbo.VWT V ON GE.AuditItemID = V.AuditItemID
		INNER JOIN [$(AuditDB)].dbo.Files F ON F.AuditID = V.AuditID
		INNER JOIN CTE_GE_BMQs BMQ ON BMQ.ManufacturerPartyID = V.ManufacturerID
									AND BMQ.CountryID = V.CountryID
									AND F.FileName LIKE (BMQ.SampleFileNamePrefix + '%')


	----------------------------------------------------------------------------------------------------
	-- UPDATE SampleTriggeredSelectionReqIDs in CRM Staging table for reference			
	----------------------------------------------------------------------------------------------------
	UPDATE GE 
	SET SampleTriggeredSelectionReqID = V.SampleTriggeredSelectionReqID
	FROM CRM.General_Enquiry GE
		INNER JOIN dbo.VWT V ON GE.AuditItemID = V.AuditItemID


	
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
		
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH

