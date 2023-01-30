CREATE PROCEDURE [Stage].[uspStandardise_SampleVolumeFeed]
AS

/*
	Purpose:	Stanadise data & flag data errors which can not be processed
	
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


		-- Frequency text incorrect
		UPDATE I
		SET I.IP_DataError = 'Frequency text incorrect'
		--SELECT * 
		FROM [Stage].[SampleVolumeFeed] I
		WHERE I.Frequency NOT IN ('Daily','Weekly','Monthly')
		AND I.Frequency IS NOT NULL


		-- VolumeReportOutput incorrect
		UPDATE I
		SET I.IP_DataError = 'VolumeReportOutput incorrect - 1 = ON, 0 OR BLANK = OFF'
		--SELECT * 
		FROM [Stage].[SampleVolumeFeed] I
		WHERE I.VolumeReportOutput NOT IN ('1','0')
		AND I.VolumeReportOutput IS NOT NULL


		-- Report where Brand is not found
	    UPDATE I
		SET I.IP_DataError = 'Brand not correct'
		--SELECT * 
		FROM [Stage].[SampleVolumeFeed] I
		WHERE NOT EXISTS (SELECT * FROM [$(SampleDB)].dbo.Brands b WHERE b.Brand = I.Brand)



		-- Report where Country/Market is not found
		UPDATE I
		SET I.IP_DataError = 'Market not found'
		--SELECT * 
		FROM [Stage].[SampleVolumeFeed] I
		WHERE NOT EXISTS (SELECT * FROM [$(SampleDB)].dbo.Markets MK WHERE COALESCE(MK.DealerTableEquivMarket, MK.Market) = I.Market)



		-- Report where Questionnaire is not found
		UPDATE I
		SET I.IP_DataError = 'Questionnaire is not found'
		--SELECT * 
		FROM [Stage].[SampleVolumeFeed] I
		WHERE I.Questionnaire NOT IN (SELECT DISTINCT Questionnaire FROM [$(SampleDB)].[dbo].[Questionnaires] q )		--V1.2


		--Report duplicate entries
		UPDATE I
		SET I.IP_DataError = 'Duplicate Brand, Market, Questionnaire'
		--SELECT DISTINCT * 
		FROM [Stage].[SampleVolumeFeed] I
		INNER JOIN (
						SELECT 
							LTRIM(RTRIM(Brand)) AS 'Brand', 
							LTRIM(RTRIM(Market)) AS 'Market', 
							LTRIM(RTRIM(Questionnaire)) AS 'Questionnaire', 
							COUNT(Questionnaire) AS COUNT
						FROM [Stage].[SampleVolumeFeed] I
						GROUP BY Brand, Market, Questionnaire
						HAVING COUNT(Questionnaire) > 1
					) C ON
						LTRIM(RTRIM(I.Brand)) = C.Brand
					AND LTRIM(RTRIM(I.Market)) = C.Market
					AND LTRIM(RTRIM(I.Questionnaire)) = C.Questionnaire


		---------------------------------------------------------------------------------------------------------
		-- Check which markets are not present 
		---------------------------------------------------------------------------------------------------------

	
		IF EXISTS(SELECT * FROM [Stage].[SampleVolumeFeed] WHERE IP_DataError IS NOT NULL)
		BEGIN                                                                            
			SELECT 1/0
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

