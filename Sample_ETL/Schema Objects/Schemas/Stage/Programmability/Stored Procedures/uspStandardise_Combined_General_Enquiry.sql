CREATE PROCEDURE Stage.uspStandardise_Combined_General_Enquiry

	@SampleFileName NVARCHAR(1000)

AS

/*
		Purpose:	Convert the service date from a text string to a valid DATETIME type
	
		Version		Date			Developer			Comment
LIVE	1.0			2021-07-02		Eddie Thomas		Created from Stage.[uspStandardise_Combined_GeneralEnquiry]
LIVE	1.1			2022-02-18		Chris Ledger		TASK 728 - Set PostalCode to Country for Russia 
*/

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

SET LANGUAGE ENGLISH

BEGIN TRY

	SET DATEFORMAT DMY  -- First ensure correct date format for ISDATE functions

	UPDATE S
	SET S.ConvertedSRCreatedDate = CONVERT(DATETIME, S.SRCreatedDate)
	FROM Stage.Combined_GeneralEnquiry S
	WHERE ISDATE(S.SRCreatedDate) = 1
	
	
	------
	UPDATE S
	SET S.ConvertedSRClosedDate = CONVERT(DATETIME, S.SRClosedDate)
	FROM Stage.Combined_GeneralEnquiry S
	WHERE ISDATE(S.SRClosedDate) = 1

	
	-- V1.3
	UPDATE S
	SET S.BrandCode = 'L'
	FROM Stage.Combined_GeneralEnquiry S
	WHERE S.BrandCode LIKE 'L%'

	
	UPDATE S
	SET S.BrandCode = 'J'
	FROM Stage.Combined_GeneralEnquiry S
	WHERE S.BrandCode LIKE 'J%'
	
	
	-- SET PREFERRED LANGUAGE ----------------------------------------	
	-- 1st Lookup Preferred Language in Language table
	UPDATE S
	SET S.PreferredLanguageID = L.LanguageID
	FROM Stage.Combined_GeneralEnquiry S
		INNER JOIN [$(SampleDB)].dbo.Languages L ON L.Language = S.CustomerLanguageCode

	
	-- Then, if not found, set using default language for country
	UPDATE S
	SET S.PreferredLanguageID = C.DefaultLanguageID 
	FROM Stage.Combined_GeneralEnquiry S
		INNER JOIN [$(SampleDB)].ContactMechanism.Countries C ON C.ISOAlpha3 = S.MarketCode  -- Use the original country code supplied to determine preferred language
	WHERE S.PreferredLanguageID IS NULL

	
	-- Failing that default to English
	UPDATE S
	SET S.PreferredLanguageID = (SELECT LanguageID FROM [$(SampleDB)].dbo.Languages WHERE Language = 'English')
	FROM Stage.Combined_GeneralEnquiry S
	WHERE S.PreferredLanguageID IS NULL	


	----------------------------------------------------------------------------------------------------
	-- SET THE BMQ SPECIFIC LOAD VARIABLES
	----------------------------------------------------------------------------------------------------
	;WITH RecordsToUpdate (ID, Manufacturer, Country_Code, Country, CountryID) AS
	(
		--ADD IN COUNTRYID
		SELECT GS.ID,
			CASE	WHEN LEFT(GS.BrandCode,1) = 'J' THEN 'Jaguar'
					WHEN LEFT(GS.BrandCode,1) = 'L' THEN 'Land Rover'
					ELSE GS.BrandCode END AS Manufacturer, 
			GS.MarketCode, 
			C.Country,
			C.CountryID
		FROM Stage.Combined_GeneralEnquiry GS
			INNER JOIN [$(SampleDB)].ContactMechanism.Countries	C ON GS.MarketCode = CASE	WHEN LEN(GS.MarketCode) = 2 THEN ISOAlpha2
																							ELSE ISOAlpha3 END																						
	)
	--RETRIEVE METADATA VALUES FOR EACH EVENT IN THE TABLE
	SELECT DISTINCT	RU.ID, 
		RU.Manufacturer, 
		RU.Country_Code, 
		RU.Country, 
		RU.CountryID,
		MD.ManufacturerPartyID, 
		MD.EventTypeID, 
		MD.LanguageID, 
		MD.SetNameCapitalisation,
		MD.DealerCodeOriginatorPartyID, 
		MD.CreateSelection, 
		MD.SampleTriggeredSelection,
		MD.QuestionnaireRequirementID, 
		MD.SampleFileID
	INTO #Completed							
	FROM RecordsToUpdate RU INNER JOIN (	SELECT DISTINCT M.ManufacturerPartyID, 
												M.CountryID, 
												ET.EventTypeID,  
												C.DefaultLanguageID AS LanguageID, 
												M.SetNameCapitalisation, 
												M.DealerCodeOriginatorPartyID,
												M.Brand, 
												M.Questionnaire, 
												M.SampleLoadActive, 
												M.SampleFileNamePrefix,
												M.CreateSelection, 
												M.SampleTriggeredSelection, 
												M.QuestionnaireRequirementID,
												M.SampleFileID					
											FROM [$(SampleDB)].dbo.vwBrandMarketQuestionnaireSampleMetadata	M
												INNER JOIN [$(SampleDB)].Event.EventTypes ET ON ET.EventType = M.Questionnaire
												INNER JOIN [$(SampleDB)].ContactMechanism.Countries C ON C.CountryID = M.CountryID
											WHERE M.Questionnaire = 'CRC General Enquiry'
												AND M.SampleLoadActive = 1
												AND @SampleFileName LIKE SampleFileNamePrefix + '%') MD ON RU.Manufacturer = MD.Brand 
																											AND RU.CountryID = MD.CountryID
							
							
	--POPULATE THE META DATA FIELDS FOR EACH RECORD
	UPDATE GS
	SET GS.ManufacturerPartyID = C.ManufacturerPartyID,	 
		GS.SampleSupplierPartyID = C.ManufacturerPartyID,
		GS.CountryID = C.CountryID,
		GS.EventTypeID = C.EventTypeID,
		GS.DealerCodeOriginatorPartyID = C.DealerCodeOriginatorPartyID,
		GS.SetNameCapitalisation = C.SetNameCapitalisation,
		GS.SampleTriggeredSelectionReqID = CASE	WHEN C.CreateSelection = 1 AND C.SampleTriggeredSelection = 1 THEN C.QuestionnaireRequirementID
												ELSE 0 END
	FROM Stage.Combined_GeneralEnquiry GS
		INNER JOIN	#Completed C ON GS.ID =C.ID	


	-- V1.1 Set PostalCode to Country for Russia
	UPDATE S
	SET S.PostalCode = S.Country
	FROM Stage.Combined_GeneralEnquiry S
		INNER JOIN [$(SampleDB)].ContactMechanism.Countries C ON C.CountryID = S.CountryID 
	WHERE S.Country = 'Russian Federation'


	---------------------------------------------------------------------------------------------------------
	-- VALIDATE FOR ALL RECORDS THAT REQUIRE METADATA FIELDS TO BE POPULATED. RAISE AN ERROR OTHERWISE.
	---------------------------------------------------------------------------------------------------------
	IF EXISTS (	SELECT ID 
				FROM Stage.Combined_GeneralEnquiry 
				WHERE ManufacturerPartyID IS NULL 
					OR SampleSupplierPartyID IS NULL 
					OR CountryID IS NULL 
					OR EventTypeID IS NULL 
					OR DealerCodeOriginatorPartyID IS NULL 
					OR SetNameCapitalisation IS NULL
					OR PreferredLanguageID IS NULL)			 
				RAISERROR (	N'Data in Stage.Combined_GeneralEnquiry has missing Meta-Data.', 
							16,
							1)

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
		INTO [Sample_Errors].Stage.Combined_GeneralEnquiry_' + @TimestampString + '
		FROM Stage.Combined_GeneralEnquiry
	')
	
	-- FINALLY RAISE THE ERROR
	RAISERROR ( @ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine )
END CATCH
GO