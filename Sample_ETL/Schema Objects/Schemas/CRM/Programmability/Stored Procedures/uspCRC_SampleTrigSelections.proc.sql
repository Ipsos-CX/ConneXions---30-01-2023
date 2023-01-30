CREATE PROCEDURE   [CRM].[uspCRC_SampleTrigSelections]

AS

/*
		Purpose:	Create any required Sample Triggered Selections
	
		Version		Developer			Created			Comment
LIVE	1.0			Chris Ross			30/06/2015		Created
LIVE	1.1			Chris Ledger		10/01/2020		BUG 15372 - Fix Hard coded references to databases
LIVE	1.2			Chris Ledger		22/09/2021		TASK 502 - Reformat
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

	;WITH CTE_CRC_BMQs AS 
	(
		SELECT DISTINCT M.ManufacturerPartyID,
			M.CountryID,
			M.CreateSelection,
			M.SampleTriggeredSelection,
			M.QuestionnaireRequirementID ,
			M.SampleFileNamePrefix
		FROM [$(SampleDB)].dbo.vwBrandMarketQuestionnaireSampleMetadata M
			INNER JOIN [$(SampleDB)].Event.EventTypes ET ON ET.EventType = M.Questionnaire
			INNER JOIN [$(SampleDB)].ContactMechanism.Countries C ON C.CountryID = M.CountryID
		WHERE M.Questionnaire = 'CRC' 
			AND M.SampleLoadActive = 1
	)
	UPDATE V
	SET V.SampleTriggeredSelectionReqID = (CASE	WHEN BMQ.CreateSelection = 1 AND BMQ.SampleTriggeredSelection = 1 THEN BMQ.QuestionnaireRequirementID
												ELSE 0 END)
	FROM CRM.CRCCall_Call CRC
		INNER JOIN dbo.VWT V ON CRC.AuditItemID = V.AuditItemID
		INNER JOIN [$(AuditDB)].dbo.Files F ON F.AuditID = V.AuditID
		INNER JOIN CTE_CRC_BMQs BMQ ON BMQ.ManufacturerPartyID = V.ManufacturerID
										AND BMQ.CountryID = V.CountryID
										AND F.FileName LIKE (BMQ.SampleFileNamePrefix + '%')


	----------------------------------------------------------------------------------------------------
	-- UPDATE SampleTriggeredSelectionReqIDs in CRM Staging table for reference			
	----------------------------------------------------------------------------------------------------
	UPDATE CRC 
	SET CRC.SampleTriggeredSelectionReqID = V.SampleTriggeredSelectionReqID
	FROM CRM.CRCCall_Call CRC
		INNER JOIN dbo.VWT V ON CRC.AuditItemID = V.AuditItemID

	
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

