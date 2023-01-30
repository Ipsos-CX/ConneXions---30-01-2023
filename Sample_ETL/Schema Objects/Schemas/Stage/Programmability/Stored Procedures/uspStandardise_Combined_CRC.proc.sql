CREATE PROCEDURE Stage.uspStandardise_Combined_CRC
	
	@SampleFileName NVARCHAR(1000)

AS

/*
		Purpose:	Convert the service date from a text string to a valid DATETIME type
	
		Version		Date			Developer			Comment
LIVE	1.0			24-09-2014		Chris Ross			Created from Stage.[uspStandardise_Combined_Roadside_Service]
LIVE	1.1			28-05-2015		Chris Ross			BUG 6061 -
LIVE	1.2			25-05-2016		Chris Ledger		Fixed issue with SampleTriggeredSelectionReqID set to 0 when multiple countries loaded ON one day
LIVE	1.3			21-03-2017		Ben King			BUG 13697 - Fix brandCode
LIVE	1.4			07-07-2021		Eddie Thomas		BUG 18240 - Field Dates changed to DMY 
LIVE	1.5			18-02-2021		Chris Ledger		TASK 728 - Set PostalCode to Country for Russia 
*/

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

SET LANGUAGE ENGLISH

BEGIN TRY

	--SET DATEFORMAT YMD  -- First ensure correct date format for ISDATE functions
	SET DATEFORMAT DMY  -- First ensure correct date format for ISDATE functions		-- V1.4
	UPDATE S
	--SET S.ConvertedSRCreatedDate = CONVERT(DATETIME, S.SRCreatedDate, 120)		
	SET S.ConvertedSRCreatedDate = CONVERT(DATETIME, S.SRCreatedDate)			-- V1.4
	FROM Stage.Combined_CRC S
	WHERE ISDATE(S.SRCreatedDate) = 1
	
	
	------
	UPDATE S
	--SET S.ConvertedSRClosedDate = CONVERT(DATETIME, S.SRClosedDate, 120)
	SET S.ConvertedSRClosedDate = CONVERT(DATETIME, S.SRClosedDate)		-- V1.4
	FROM Stage.Combined_CRC S
	WHERE ISDATE(S.SRClosedDate) = 1

	
	-- V1.3
	UPDATE S
	SET S.BrandCode = 'L'
	FROM Stage.Combined_CRC S
	WHERE S.BrandCode LIKE 'L%'

	
	UPDATE S
	SET S.BrandCode = 'J'
	FROM Stage.Combined_CRC S
	WHERE S.BrandCode LIKE 'J%'
	
	
	-----  SET PREFERRED LANGUAGE ----------------------------------------
	-- 1st Lookup Preferred Language in Language table
	UPDATE S
	SET S.PreferredLanguageID = L.LanguageID
	FROM Stage.Combined_CRC S
		INNER JOIN [$(SampleDB)].dbo.Languages L ON L.Language = S.CustomerLanguageCode

	
	-- Then, if not found, set using default language for country
	UPDATE S
	SET S.PreferredLanguageID = C.DefaultLanguageID 
	FROM Stage.Combined_CRC S
		INNER JOIN [$(SampleDB)].ContactMechanism.Countries C ON C.ISOAlpha3 = S.MarketCode  -- Use the original country code supplied to determine preferred language
	WHERE S.PreferredLanguageID IS NULL

	
	-- Failing that default to English
	UPDATE S
	SET S.PreferredLanguageID = (SELECT LanguageID FROM [$(SampleDB)].dbo.Languages WHERE Language = 'English')
	FROM Stage.Combined_CRC S
	WHERE S.PreferredLanguageID IS NULL	


	-- V1.5 Set PostalCode to Country for Russia
	UPDATE S
	SET S.PostalCode = S.Country
	FROM Stage.Combined_CRC S
		INNER JOIN [$(SampleDB)].ContactMechanism.Countries C ON C.ISOAlpha3 = S.MarketCode 
	WHERE S.Country = 'Russian Federation'


	----------------------------------------------------------------------------------------------------
	-- Set SampleTriggeredSelectionReqIDs where appropriate						V1.1
	----------------------------------------------------------------------------------------------------
	;WITH CTE_CRC_BMQs AS 
	(
		SELECT DISTINCT SUBSTRING(M.Brand, 1, 1) AS BrandCode,
			M.ISOAlpha3 AS CountryISOAlpha3,
			M.CreateSelection,
			M.SampleTriggeredSelection,
			M.QuestionnaireRequirementID
		FROM [$(SampleDB)].dbo.vwBrandMarketQuestionnaireSampleMetadata	M
			INNER JOIN [$(SampleDB)].Event.EventTypes ET ON ET.EventType = M.Questionnaire
			INNER JOIN [$(SampleDB)].ContactMechanism.Countries C ON C.CountryID = M.CountryID
		WHERE M.Questionnaire	= 'CRC'
			AND M.SampleLoadActive = 1
			AND @SampleFileName LIKE SampleFileNamePrefix + '%'
	)
	UPDATE CRC 
	SET SampleTriggeredSelectionReqID = CASE	WHEN BMQ.CreateSelection = 1 AND BMQ.SampleTriggeredSelection = 1 THEN BMQ.QuestionnaireRequirementID
												ELSE 0 END
	FROM Stage.Combined_CRC CRC
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
		INTO [$(ErrorDB)].Stage.Combined_CRC_' + @TimestampString + '
		FROM Stage.Combined_CRC
	')
	
	-- FINALLY RAISE THE ERROR
	RAISERROR ( @ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine )
END CATCH