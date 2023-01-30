CREATE PROCEDURE [Stage].[uspStandardise_CXP_General_Enquiry]
@SampleFileName NVARCHAR (1000)
AS

/*
	Purpose:	Convert the service date from a text string to a valid DATETIME type
	
	Release			Version			Date			Developer			Comment
	LIVE			1.0				14-07-2021		Eddie Thomas		Created from [Stage].[uspStandardise_Combined_General_Enquiry]
	LIVE 			1.1             27/01/2022      Ben King            TASK 753 - Allow Mandarin for all Taiwan files
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

	UPDATE [Stage].CXP_GeneralEnquiry
	SET ConvertedSRCreatedDate = CONVERT(datetime, SRCreatedDate)
	WHERE ISDATE(SRCreatedDate) = 1
	
	
	------

	UPDATE [Stage].CXP_GeneralEnquiry
	SET ConvertedSRClosedDate = CONVERT(datetime, SRClosedDate)
	WHERE ISDATE(SRClosedDate) = 1
	
	--1.3
	UPDATE [Stage].CXP_GeneralEnquiry
	SET BrandCode = 'L'
	WHERE BrandCode like 'L%'
	
	UPDATE [Stage].CXP_GeneralEnquiry
	SET BrandCode = 'J'
	WHERE BrandCode like 'J%'
	

	--V1.1
	UPDATE G
	SET G.CustomerLanguageCode = 'Taiwanese Chinese (Taiwan)'
	FROM stage.CXP_GeneralEnquiry G
	WHERE G.CustomerLanguageCode = 'Mandarin'
	AND G.MarketCode = 'TWN'
	

	-----  SET PREFERRED LANGUAGE ----------------------------------------
	
	-- 1st Lookup Preferred Language in Language table
	UPDATE s
	SET s.PreferredLanguageID = l.LanguageID
	FROM  stage.CXP_GeneralEnquiry s
	INNER JOIN [$(SampleDB)].dbo.Languages l on l.Language = s.CustomerLanguageCode
	
	-- Then, if not found, set using default language for country
	UPDATE s
	SET s.PreferredLanguageID = c.DefaultLanguageID 
	FROM stage.CXP_GeneralEnquiry s
	INNER JOIN [$(SampleDB)].ContactMechanism.Countries c on c.ISOAlpha3 = s.Marketcode  -- Use the original country code supplied to determine preferred language
	WHERE s.PreferredLanguageID IS NULL
	
	-- Failing that default to English
	UPDATE stage.CXP_GeneralEnquiry
	SET PreferredLanguageID = (SELECT LanguageID FROM [$(SampleDB)].dbo.Languages WHERE Language = 'English')
	WHERE PreferredLanguageID IS NULL	


	----------------------------------------------------------------------------------------------------
	-- SET THE BMQ SPECIFIC LOAD VARIABLES
	----------------------------------------------------------------------------------------------------
	;WITH RecordsToUpdate	(ID, Manufacturer, Country_Code, Country, CountryID)

	AS

	(
	--ADD IN COUNTRYID
	SELECT		GS.ID, CASE 
							WHEN LEFT(GS.BrandCode,1) = 'J' THEN 'Jaguar'
							WHEN LEFT(GS.BrandCode,1) = 'L' THEN 'Land Rover'
							ELSE GS.BrandCode
						END, 
				GS.MarketCode, C.Country,C.CountryID
	FROM		[Stage].[CXP_GeneralEnquiry]		GS
	INNER JOIN	[$(SampleDB)].ContactMechanism.Countries	C  ON GS.MarketCode =	(  
																						Case
																							WHEN LEN(GS.MarketCode) = 2 THEN ISOAlpha2
																							ELSE ISOAlpha3
																						End
																					)	
	)
	--RETRIEVE METADATA VALUES FOR EACH EVENT IN THE TABLE
	SELECT	DISTINCT	RU.*, MD.ManufacturerPartyID, MD.EventTypeID, MD.LanguageID, MD.SetNameCapitalisation,
						MD.DealerCodeOriginatorPartyID, MD.CreateSelection, MD.SampleTriggeredSelection,
						MD.QuestionnaireRequirementID, MD.SampleFileID

	INTO	#Completed							
	FROM	RecordsToUpdate RU
	INNER JOIN 
	(
		SELECT DISTINCT M.ManufacturerPartyID, M.CountryID, ET.EventTypeID,  
						C.DefaultLanguageID AS LanguageID, M.SetNameCapitalisation, M.DealerCodeOriginatorPartyID,
						M.Brand, M.Questionnaire, M.SampleLoadActive, M.SampleFileNamePrefix,
						M.CreateSelection, M.SampleTriggeredSelection, 
						M.QuestionnaireRequirementID,
						M.SampleFileID
						
		FROM			[$(SampleDB)].dbo.vwBrandMarketQuestionnaireSampleMetadata	M
		INNER JOIN		[$(SampleDB)].Event.EventTypes								ET ON ET.EventType = M.Questionnaire
		INNER JOIN		[$(SampleDB)].ContactMechanism.Countries					C ON C.CountryID = M.CountryID
		
		WHERE			(M.Questionnaire		= 'CRC General Enquiry') AND
						(M.SampleLoadActive		= 1	) AND
						(@SampleFileName LIKE SampleFileNamePrefix + '%')

	)	MD				ON	RU.Manufacturer = MD.Brand AND
							RU.CountryID	= MD.CountryID
							
							
	--POPULATE THE META DATA FIELDS FOR EACH RECORD
	UPDATE		GS
	SET			ManufacturerPartyID			= C.ManufacturerPartyID,	 
				SampleSupplierPartyID		= C.ManufacturerPartyID,
				CountryID					= C.CountryID,
				EventTypeID					= C.EventTypeID,
				DealerCodeOriginatorPartyID	= C.DealerCodeOriginatorPartyID,
				SetNameCapitalisation		= C.SetNameCapitalisation,
				SampleTriggeredSelectionReqID = (
													Case
														WHEN	C.CreateSelection = 1 AND 
																C.SampleTriggeredSelection = 1 THEN C.QuestionnaireRequirementID
														ELSE	0
													END
												)
	
	FROM 		Stage.CXP_GeneralEnquiry		GS
	INNER JOIN	#Completed					C ON GS.ID =C.ID	



	---------------------------------------------------------------------------------------------------------
	-- VALIDATE FOR ALL RECORDS THAT REQUIRE METADATA FIELDS TO BE POPULATED. RAISE AN ERROR OTHERWISE.
	---------------------------------------------------------------------------------------------------------
	IF Exists( 
				SELECT	ID 
				FROM	[Stage].[CXP_GeneralEnquiry] 
				WHERE	(ManufacturerPartyID		IS NULL OR
						SampleSupplierPartyID		IS NULL OR
						CountryID					IS NULL OR 
						EventTypeID					IS NULL OR	
						DealerCodeOriginatorPartyID IS NULL OR
						SetNameCapitalisation		IS NULL OR
						PreferredLanguageID			IS NULL)
			)			 
			
			RAISERROR(	N'Data in Stage.CXP_GeneralEnquiry has missing Meta-Data.', 
						16,
						1
					 )

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
		INTO [Sample_Errors].Stage.CXP_GeneralEnquiry_' + @TimestampString + '
		FROM Stage.CXP_GeneralEnquiry
	')
	
	-- FINALLY RAISE THE ERROR
	RAISERROR ( @ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine )
END CATCH
GO



