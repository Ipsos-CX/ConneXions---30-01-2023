CREATE PROCEDURE [WeeklySampleCheck].[uspSampleVolumeFeed_Settings]
AS



/*
	Purpose:	Update SampleVolumeFeed
	
	Release			Version			Date			Developer			Comment
	LIVE			1.0				19102022		Ben King    		TASK 1011

*/

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

SET LANGUAGE ENGLISH
SET DATEFORMAT DMY

BEGIN TRY

	

		--INSERT NEW SETTINGS
		INSERT INTO WeeklySampleCheck.LiveBrandMarketQuestionnaire ([Brand], [Market], [Questionnaire], [Frequency], [ExpectedDays], [VolumeReportOutput])
		SELECT DISTINCT
			S.Brand,
			S.Market, 
			S.Questionnaire, 
		
			S.Frequency,
			S.ExpectedDays,
			S.VolumeReportOutput
		FROM [$(ETLDB)].Stage.SampleVolumeFeed S
		LEFT JOIN WeeklySampleCheck.LiveBrandMarketQuestionnaire L   ON L.Brand = S.Brand
																	AND L.Market = S.Market
																	AND L.Questionnaire = S.Questionnaire
		WHERE L.Market IS NULL
		AND L.Questionnaire IS NULL
		AND L.Brand IS NULL

		
		--UPDATE CHANGED SETTINGS
		UPDATE L
			SET L.Frequency = S.Frequency,
				L.ExpectedDays = S.ExpectedDays,
				L.VolumeReportOutput = S.VolumeReportOutput
		--SELECT *
		FROM [$(ETLDB)].Stage.SampleVolumeFeed S
		LEFT JOIN WeeklySampleCheck.LiveBrandMarketQuestionnaire L   ON L.Brand = S.Brand
																	AND L.Market = S.Market
																	AND L.Questionnaire = S.Questionnaire

		WHERE CONCAT(S.Frequency , S.ExpectedDays , S.VolumeReportOutput)
			  <>
			  CONCAT(L.Frequency , L.ExpectedDays , L.VolumeReportOutput)
		AND L.Brand IS NOT NULL
		AND L.Market IS NOT NULL
		AND L.Questionnaire IS NOT NULL


		--CHECK STAGE TABLE ISNT EMPTY FROM ERROR FLUSH.
		IF EXISTS (
					SELECT * 
					FROM [$(ETLDB)].[Stage].[SampleVolumeFeed]
				  )

		BEGIN

				--REMOVE DELETED 
				DELETE L
				--SELECT *
				FROM WeeklySampleCheck.LiveBrandMarketQuestionnaire L 
				LEFT JOIN [$(ETLDB)].Stage.SampleVolumeFeed S ON L.Brand = S.Brand
															 AND L.Market = S.Market
															 AND L.Questionnaire = S.Questionnaire
				WHERE S.Market IS NULL
				AND S.Questionnaire IS NULL
				AND S.Brand IS NULL
		
		END
	
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
		
		
	-- CREATE A COPY OF THE STAGING TABLE FOR USE IN PRODUCTION SUPPORT
	DECLARE @TimestampString CHAR(15)
	SELECT @TimestampString = [$(ErrorDB)].dbo.udfGetTimestampString(GETDATE())
	
	EXEC(	'SELECT *
			INTO [Sample_Errors].Stage.SampleVolumeFeed_' + @TimestampString + '
			FROM Stage.SampleVolumeFeed')
	
	
	-- FINALLY RAISE THE ERROR
	RAISERROR ( @ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine )
END CATCH

GO
