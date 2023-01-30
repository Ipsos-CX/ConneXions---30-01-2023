CREATE PROCEDURE [Stage].[uspStandardise_CXP_Sales]
/*
	Purpose:		(I)		Convert the supplied dates from a text string to a valid DATETIME type
					(II)	Populate mandatory meta data
	
	Release			Version			Date			Developer			Comment
	LIVE			1.0				10/10/2018		Eddie Thomas		Created from [Sample_ETL].dbo.uspStandardise_Global_Sales
	LIVE			1.1				20/05/2021		Eddie Thomas		Bugratacker 18207 - Blank Event_Type field values causes loader to bomb when copying data to VWT
	LIVE 			1.2             27/01/2022      Ben King            TASK 753 - Allow Mandarin for all Taiwan files
*/
@SampleFileName NVARCHAR (1000)
AS
DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

SET LANGUAGE ENGLISH

BEGIN TRY

	SET DATEFORMAT DMY  -- First ensure correct date format for ISDATE functions

	----------------------------------------------------------------------------------------------------
	-- SET THE BMQ SPECIFIC LOAD VARIABLES
	----------------------------------------------------------------------------------------------------
	;WITH RecordsToUpdate	(ID, Manufacturer, Country_Code, Country, CountryID)

	AS

	(
	--ADD IN COUNTRYID
	SELECT		GS.ID, GS.Manufacturer, GS.Country_Code, C.Country,C.CountryID
	FROM		[Stage].[CXP_Sales]		GS
	INNER JOIN	[$(SampleDB)].ContactMechanism.Countries	C  ON GS.Country_Code =	(  
																						Case
																							WHEN LEN(GS.Country_Code) = 2 THEN ISOAlpha2
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
		
		WHERE			(M.Questionnaire		= 'Sales') AND
						(M.SampleLoadActive		= 1	) AND
						(@SampleFileName LIKE SampleFileNamePrefix + '%')
						--M.SampleFileExtension	= RIGHT(@SampleFileName, len(@SampleFileName) - PATINDEX('%.%',@SampleFileName)+1)

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
	
	FROM 		Stage.CXP_Sales		GS
	INNER JOIN	#Completed					C ON GS.ID =C.ID	
	

	---------------------------------------------------------------------------------------------------------
	--	BY DEFAULT CUSTOMERIDENTIFIER MATCHING IS DISABLED
	---------------------------------------------------------------------------------------------------------
	UPDATE		GS 
	SET			CustomerIdentifierUsable =  CAST(0 AS BIT)
	FROM		Stage.CXP_Sales GS
	INNER JOIN	#Completed			C ON GS.ID = C.ID	
	
	
	----------------------------------------------------------------------------------------------------
	-- CONVERT KEY DATES 
	----------------------------------------------------------------------------------------------------

	UPDATE	[Stage].CXP_Sales
	SET		ConvertedSalesEventDate = CONVERT(DATETIME, [Sales_Event_Date], 103)
	WHERE	ISDATE([Sales_Event_Date]) = 1
	
	
	------

	UPDATE	[Stage].CXP_Sales
	SET		[ConvertedVehicleRegistrationDate] = CONVERT(DATETIME, Vehicle_Registration_Date, 103)
	WHERE	ISDATE(Vehicle_Registration_Date) = 1
	

	--V1.2
	UPDATE G
	SET G.Preferred_Language = 'Taiwanese Chinese (Taiwan)'
	FROM Stage.CXP_Sales G
	WHERE G.Preferred_Language= 'Mandarin'
	AND G.Country_Code  = 'TW'
	

	----------------------------------------------------------------------------------------------------
	---  SET PREFERRED LANGUAGE ----------------------------------------
	----------------------------------------------------------------------------------------------------
	
	-- 1ST LOOKUP PREFERRED LANGUAGE IN LANGUAGE TABLE
	UPDATE		s
	SET			s.LanguageID = l.LanguageID
	FROM		Stage.CXP_Sales s
	INNER JOIN	[$(SampleDB)].dbo.Languages l ON l.Language = s.Preferred_Language
	
	-- THEN, IF NOT FOUND, SET USING DEFAULT LANGUAGE FOR COUNTRY
	UPDATE		s
	SET			s.LanguageID = c.DefaultLanguageID 
	FROM		Stage.CXP_Sales s
	INNER JOIN	[$(SampleDB)].ContactMechanism.Countries c ON c.ISOAlpha2 = s.Country_Code  -- Use the original country code supplied to determine preferred language
	WHERE		s.LanguageID IS NULL
	
	-- Failing that default to English
	UPDATE		Stage.CXP_Sales
	SET			LanguageID = (SELECT LanguageID FROM [$(SampleDB)].dbo.Languages WHERE Language = 'English')
	WHERE		LanguageID IS NULL	


	---------------------------------------------------------------------------------------------------------
	-- SET ANY BLANK MODEL YEARS TO NULL
	---------------------------------------------------------------------------------------------------------cc
	UPDATE	Stage.CXP_Sales
	SET		Model_Year = NULL
	WHERE	LEN(LTRIM(RTRIM(Model_Year))) = 0
	
	--		REMOVE INVALID MODEL YEAR
	UPDATE	Stage.CXP_Sales
	SET		Model_Year = NULL
	WHERE	ISNUMERIC(Model_Year) = 0
	
	---------------------------------------------------------------------------------------------------------
	-- V1.1	SET ANY 'JLR EVENT TYPES' TO NULL
	---------------------------------------------------------------------------------------------------------cc
	UPDATE	Stage.CXP_Sales
	SET		Event_Type = NULL
	WHERE	LEN(LTRIM(RTRIM(Event_Type))) = 0


	---------------------------------------------------------------------------------------------------------
	-- VALIDATE FOR ALL RECORDS THAT REQUIRE METADATA FIELDS TO BE POPULATED. RAISE AN ERROR OTHERWISE.
	---------------------------------------------------------------------------------------------------------
	IF Exists( 
				SELECT	ID 
				FROM	[Stage].[CXP_Sales] 
				WHERE	(ManufacturerPartyID		IS NULL OR
						SampleSupplierPartyID		IS NULL OR
						CountryID					IS NULL OR 
						EventTypeID					IS NULL OR	
						DealerCodeOriginatorPartyID IS NULL OR
						SetNameCapitalisation		IS NULL OR
						LanguageID					IS NULL)
			)			 
			
			RAISERROR(	N'Data in Stage.CXP_Sales has missing Meta-Data.', 
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
		INTO [Sample_Errors].Stage.CXP_Sales_' + @TimestampString + '
		FROM Stage.CXP_Sales
	')
	
	-- FINALLY RAISE THE ERROR
	RAISERROR ( @ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine )
END CATCH