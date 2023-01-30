
CREATE PROCEDURE [Stage].[uspStandardise_CXP_CRC]
@SampleFileName NVARCHAR (1000)
AS

/*
	Purpose:	Convert the service date from a text string to a valid DATETIME type
	
	Release			Version			Date			Developer			Comment
	LIVE			1.0				2018-06-04		Chris Ledger		Created from [Stage].[uspStandardise_CXP_CRC]
	LIVE			1.1				2018-06-06		Chris Ledger		Change Date Formatting
	LIVE			1.2				2019-10-23		Ben King			BUG 15652
	LIVE			1.3				2020-01-10		Chris Ledger		BUG 15372 - Fix Hard coded references to databases
	LIVE			1.4				2020-13-18		Ben King			BUG 18007 - Remove N/A's from address
	LIVE 			1.5             27/01/2022      Ben King            TASK 753 - Allow Mandarin for all Taiwan files
*/

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

SET LANGUAGE ENGLISH

BEGIN TRY

	SET DATEFORMAT DMY  -- First ensure correct date format for ISDATE functions	-- V1.1

	UPDATE [Stage].CXP_CRC
	SET ConvertedSRCreatedDate = CONVERT(DATETIME, SRCreatedDate, 103)
	WHERE ISDATE(SRCreatedDate) = 1
	
	
	------

	UPDATE [Stage].CXP_CRC
	SET ConvertedSRClosedDate = CONVERT(DATETIME, SRClosedDate, 103)
	WHERE ISDATE(SRClosedDate) = 1
	
	--1.3
	UPDATE [Stage].CXP_CRC
	SET BrandCode = 'L'
	WHERE BrandCode LIKE 'L%'
	
	UPDATE [Stage].CXP_CRC
	SET BrandCode = 'J'
	WHERE BrandCode LIKE 'J%'

	--V1.4
	UPDATE	[stage].[CXP_CRC]
	SET		AddressLine1 =	CASE 
							WHEN RTRIM(LTRIM(AddressLine1)) = 'N/A' 
							THEN '' 
							ELSE AddressLine1 
							END,
			AddressLine2 =	CASE WHEN RTRIM(LTRIM(AddressLine2)) = 'N/A' 
							THEN '' 
							ELSE AddressLine2 
							END,
			AddressLine3 =	CASE WHEN RTRIM(LTRIM(AddressLine3)) = 'N/A' 
							THEN '' 
							ELSE AddressLine3 
							END,
			AddressLine4 =	CASE WHEN RTRIM(LTRIM(AddressLine4)) = 'N/A' 
							THEN '' 
							ELSE AddressLine4 
							END,
			City =			CASE WHEN RTRIM(LTRIM(City)) = 'N/A' 
							THEN '' 
							ELSE City 
							END,
			PostalCode =	CASE WHEN RTRIM(LTRIM(PostalCode)) = 'N/A' 
							THEN '' 
							ELSE PostalCode 
							END
	

	--V1.5
	UPDATE G
	SET G.CustomerLanguageCode = 'Taiwanese Chinese (Taiwan)'
	FROM Stage.CXP_CRC G
	WHERE G.CustomerLanguageCode = 'Mandarin'
	AND G.MarketCode = 'TWN'

	
	-----  SET PREFERRED LANGUAGE ----------------------------------------

	--V1.2
	UPDATE S
	SET S.PreferredLanguageID = l.LanguageID
	FROM Stage.CXP_CRC S 
	INNER JOIN [$(SampleDB)].ContactMechanism.Countries C ON S.MarketCode = C.ISOAlpha3
	INNER JOIN [$(SampleDB)].dbo.Markets M ON C.CountryID = M.CountryID
	INNER JOIN [$(SampleDB)].dbo.Regions R ON M.RegionID = R.RegionID 
	INNER JOIN [$(SampleDB)].dbo.Languages l ON l.ISOAlpha2 = S.CustomerLanguageCode --use 2 character isoAlpha code
	WHERE R.Region = 'MENA'
	
	-- 1st Lookup Preferred Language in Language table
	UPDATE s
	SET s.PreferredLanguageID = l.LanguageID
	FROM  Stage.CXP_CRC s
	INNER JOIN [$(SampleDB)].dbo.Languages l ON l.Language = s.CustomerLanguageCode
	
	-- Then, if not found, set using default language for country
	UPDATE s
	SET s.PreferredLanguageID = c.DefaultLanguageID 
	FROM Stage.CXP_CRC s
	INNER JOIN [$(SampleDB)].ContactMechanism.Countries c ON c.ISOAlpha3 = s.Marketcode  -- Use the original country code supplied to determine preferred language
	WHERE s.PreferredLanguageID IS NULL
	
	-- Failing that default to English
	UPDATE Stage.CXP_CRC
	SET PreferredLanguageID = (SELECT LanguageID FROM [$(SampleDB)].dbo.Languages WHERE Language = 'English')
	WHERE PreferredLanguageID IS NULL	


	----------------------------------------------------------------------------------------------------
	-- Set SampleTriggeredSelectionReqIDs where appropriate						v1.1
	----------------------------------------------------------------------------------------------------

	;WITH CTE_CRC_BMQs
	AS (
		SELECT DISTINCT SUBSTRING(M.Brand, 1, 1) AS BrandCode ,
						M.ISOAlpha3 AS CountryISOAlpha3,
						M.CreateSelection,
						M.SampleTriggeredSelection,
						M.QuestionnaireRequirementID
		FROM			[$(SampleDB)].dbo.vwBrandMarketQuestionnaireSampleMetadata	M
		INNER JOIN		[$(SampleDB)].Event.EventTypes ET ON ET.EventType = M.Questionnaire
		INNER JOIN		[$(SampleDB)].ContactMechanism.Countries C ON C.CountryID = M.CountryID
		WHERE			(M.Questionnaire	= 'CRC') AND
						(M.SampleLoadActive = 1	) AND
						(@SampleFileName LIKE SampleFileNamePrefix + '%')
	)
	UPDATE CRC 
	SET SampleTriggeredSelectionReqID = (CASE WHEN BMQ.CreateSelection = 1 AND BMQ.SampleTriggeredSelection = 1 
											THEN BMQ.QuestionnaireRequirementID
											ELSE 0 END)
	FROM Stage.CXP_CRC CRC
	INNER JOIN CTE_CRC_BMQs BMQ ON BMQ.BrandCode = CRC.BrandCode
								AND BMQ.CountryISOAlpha3 = CRC.MarketCode



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
	
	EXEC('
		SELECT *
		INTO [$(ErrorDB)].Stage.CXP_CRC_' + @TimestampString + '
		FROM Stage.CXP_CRC
	')
	
	-- FINALLY RAISE THE ERROR
	RAISERROR ( @ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine )
END CATCH