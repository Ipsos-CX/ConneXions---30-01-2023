CREATE PROCEDURE [GeneralEnquiry].[uspGeneral_Enquiry_SampleTrigSelections]

AS

/*
	Purpose:	Create any required Sample Triggered Selections
	
	Version		Developer			Created			Comment
	1.0			Eddie Thomas		05/07/2021		Ceated from CRM.uspCRC_SampleTrigSelections
	1.1			Eddie Thomas		30/07/2021		FIXED a bug preventing SampleTriggeredSelectionReqID being populated
													
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
	SET			SampleTriggeredSelectionReqID = CASE	WHEN BMQ.CreateSelection = 1 AND BMQ.SampleTriggeredSelection = 1 THEN BMQ.QuestionnaireRequirementID
												ELSE 0 END
	

	FROM		GeneralEnquiry.GeneralEnquiryEvents		GE
	INNER JOIN	dbo.VWT									V	ON	GE.AuditID			= V.AuditID AND			--V1.1
																GE.PhysicalRowID	= V.PhysicalFileRow		--V1.1
	INNER JOIN	[$(AuditDB)].dbo.Files				F	ON	F.AuditID = V.AuditID
	INNER JOIN	CTE_GE_BMQs								BMQ ON	BMQ.ManufacturerPartyID = V.ManufacturerID AND 
																BMQ.CountryID = V.CountryID AND 
																F.[Filename] LIKE (BMQ.SampleFileNamePrefix + '%')
	WHERE		V.SampleTriggeredSelectionReqID IS NULL


	----------------------------------------------------------------------------------------------------
	-- UPDATE SampleTriggeredSelectionReqIDs in GeneralEnquiry.GeneralEnquiryEvents table for reference			
	----------------------------------------------------------------------------------------------------
	UPDATE			GE 
	SET				SampleTriggeredSelectionReqID	= V.SampleTriggeredSelectionReqID
	FROM			GeneralEnquiry.GeneralEnquiryEvents GE
	INNER JOIN		dbo.VWT								V ON	GE.AuditID			= V.AuditID AND			--V1.1
																GE.PhysicalRowID	= V.PhysicalFileRow		--V1.1
	
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
GO

