CREATE PROCEDURE [Stage].[uspStandardise_Global_Service]
/*
		Purpose:	(I)		Convert the supplied dates from a text string to a valid DATETIME type
					(II)	Populate load variables
	
		Version		Date			Developer			Comment
LIVE	1.0			13/11/2014		Eddie Thomas		Created from [Sample_ETL].dbo.uspStandardise_Jaguar_Brazil_Service 
LIVE	1.1			22/04/2015							BUG 11402 : Remapping preferred language to English (MENA) 
LIVE	1.2			15/06/2015		Eddie Thomas		CustomIdnetifierUsable now set in proc NOT in package.
LIVE	1.3			15/06/2015		Chris Ross			BUG 11626 : Remove NoEmail@JLR.com email addresses from staging
LIVE	1.4			16/06/2015		Eddie Thomas		Revised preferred language settting to be be driven by Meta-Data (BUG 11545 - European Importer setup)  			
LIVE	1.5			26/06/2015		Jean Rebello		Added Dummy Phone Number Feature (BUG 11317 - Dummy Phone Number Feature)
LIVE	1.6			17/08/2015		Eddie Thomas		BUG 11757 : Due to poor sample quality of Australia Service sample we will remove sample supplied salutations and
																	use generic patterns instead.
LIVE	1.7			26/11/2015		Chris Ledger		Fixed issue with Salutations being removed from all loaded files if one removed. 
LIVE	1.8			15/03/2015		Chris Ledger		BUG 12021: MENA Languages by country
LIVE	1.9			07/06/2016		Chris Ledger		Set Taiwan FirstName to SurNameField1
LIVE	1.10		09/06/2016		Chris Ledger		Remove SampleFileID from udfIsLanguageExcluded 
LIVE	1.11		01/01/2017		Ben King			BUG 13444 Add check on ModelYear alignment
LIVE	1.12		11/04/2017		Eddie Thomas		BUG 13698 Remapping LO language code to LAO
LIVE	1.13		25/10/2017		Eddie Thomas		BUG 14326 - Remapping Hong Kong Chinese speakers to a new Chinese language variant
LIVE	1.14		07/01/2019		Eddie Thomas		BUG 15183 - Blank EventType values cause the loader to bomb out when copying records to the VWT
LIVE	1.15		16/04/2019		Ben King			BUG 15311 - Prevent partial loaded batch of files
LIVE	1.16		10/01/2020		Chris Ledger		BUG 15372 - Fix Hard coded references to databases
LIVE	1.17		23/11/2021		Eddie Thomas		BUG 18398 - Updated Logic surrounding ModelYear
LIVE	1.18		18/01/2022		Chris Ledger		TASK 762 - Update Language from Russian to Russian (Euro-Importers)
LIVE	1.19		31/03/2022		Eddie Thomas		BUG FIX - Improved date conversion logic 
*/
		
@SampleFileName  NVARCHAR(100)

AS

DECLARE @ErrorNumber		INT
DECLARE @ErrorSeverity		INT
DECLARE @ErrorState			INT
DECLARE @ErrorLocation		NVARCHAR(500)
DECLARE @ErrorLine			INT
DECLARE @ErrorMessage		NVARCHAR(2048)


SET LANGUAGE ENGLISH
SET DATEFORMAT DMY -- V1.19
BEGIN TRY


	----------------------------------------------------------------------------------------------------
	-- Set the BMQ specific load variables 
	----------------------------------------------------------------------------------------------------
	;WITH RecordsToUpdate (ID, Manufacturer, CountryCode, EventType, Country, CountryID) AS
	(
		SELECT GS.ID, 
			GS.Manufacturer, 
			GS.CountryCode, 
			GS.EventType, 
			C.Country,
			C.CountryID
		FROM Stage.Global_Service GS
			INNER JOIN [$(SampleDB)].ContactMechanism.Countries	C ON GS.CountryCode = CASE	WHEN LEN(GS.CountryCode) = 2 THEN ISOAlpha2
																							ELSE ISOAlpha3 END	
	)
	--Retrieve Metadata values for each event in the table
	SELECT DISTINCT RU.ID, 
		RU.Manufacturer, 
		RU.CountryCode, 
		RU.EventType, 
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
	FROM RecordsToUpdate RU
		INNER JOIN (	SELECT DISTINCT M.ManufacturerPartyID, 
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
							INNER JOIN [$(SampleDB)].ContactMechanism.Countries	C ON C.CountryID = M.CountryID
						WHERE M.Questionnaire = 'Service'
							AND M.SampleLoadActive = 1
							AND @SampleFileName LIKE SampleFileNamePrefix + '%') MD	ON RU.Manufacturer = MD.Brand 
																						AND RU.CountryID = MD.CountryID
	-- Populate the meta data fields for each record
	UPDATE GS
	SET ManufacturerPartyID	= C.ManufacturerPartyID,	 
		SampleSupplierPartyID = C.ManufacturerPartyID,
		CountryID = C.CountryID,
		EventTypeID	= C.EventTypeID,
		--LanguageID = C.LanguageID,
		DealerCodeOriginatorPartyID = C.DealerCodeOriginatorPartyID,
		SetNameCapitalisation = C.SetNameCapitalisation,
		SampleTriggeredSelectionReqID = (CASE	WHEN C.CreateSelection = 1 AND C.SampleTriggeredSelection = 1 THEN C.QuestionnaireRequirementID
												ELSE 0 END)	
	FROM Stage.Global_Service GS
		INNER JOIN #Completed C ON GS.ID = C.ID		
	
		
	---------------------------------------------------------------------------------------------------------
	-- Convert the Service Date 
	---------------------------------------------------------------------------------------------------------
	UPDATE Stage.Global_Service
	SET	ConvertedServiceEventDate = CONVERT(DATETIME, ServiceEventDate, 103)
	WHERE ISDATE(CONVERT(NVARCHAR, ServiceEventDate, 103)) = 1 -- V1.19

	---------------------------------------------------------------------------------------------------------
	-- Convert the Registration Date 
	---------------------------------------------------------------------------------------------------------
	UPDATE Stage.Global_Service
	SET	ConvertedVehicleRegistrationDate = CONVERT(DATETIME, VehicleRegistrationDate, 103)
	WHERE ISDATE(CONVERT(NVARCHAR, VehicleRegistrationDate, 103)) = 1	--V1.19


	---------------------------------------------------------------------------------------------------------
	-- Update (cleardown) the TelephoneNumbers, if a Dummy one is supplied
	---------------------------------------------------------------------------------------------------------
	DECLARE @FieldNameForDummyTN		NVARCHAR(200) = ''
	DECLARE @FieldValueForDummyTN  		NVARCHAR(200) = ''
		
	SELECT DISTINCT	@FieldNameForDummyTN = ColumnFormattingIdentifier,
		@FieldValueForDummyTN = ColumnFormattingValue
	FROM [$(SampleDB)].dbo.SampleFileSpecialFormatting SF
		INNER JOIN [$(SampleDB)].dbo.vwBrandMarketQuestionnaireSampleMetadata SM ON SF.SampleFileID = SM.SampleFileID
	WHERE @SampleFileName LIKE SM.SampleFileNamePrefix + '%'
		AND SF.ColumnFormattingIdentifier = 'clearDummyTelephoneNumber'
		
	IF @FieldNameForDummyTN = 'clearDummyTelephoneNumber'		
		BEGIN	
			UPDATE GS
			SET GS.HomeTelephoneNumber = Lookup.udfClearDummyTelephoneNumbers(GS.HomeTelephoneNumber, @FieldValueForDummyTN),
				GS.BusinessTelephoneNumber = Lookup.udfClearDummyTelephoneNumbers(GS.BusinessTelephoneNumber, @FieldValueForDummyTN),
				GS.MobileTelephoneNumber = Lookup.udfClearDummyTelephoneNumbers(GS.MobileTelephoneNumber, @FieldValueForDummyTN)
			FROM Stage.Global_Sales GS
		END



	---------------------------------------------------------------------------------------------------------
	-- Update the preferred LanguageID, if a Preferred language supplied
	---------------------------------------------------------------------------------------------------------
	-- V1.8 UPDATE AZERBI TO AZERBAJANII
	UPDATE GS
	SET GS.PreferredLanguage = 'Azerbaijani'
	FROM Stage.Global_Service GS
	WHERE GS.PreferredLanguage = 'Azeri'

		
	-- V1.4 (See Comments above) 
	UPDATE GS
	SET	GS.LanguageID = CASE	-- IF PREFERRED LANGUAGE ISN'T PERMITTED, SET LANGUAGE TO A DESIGNATED DEFAULT LANGUAGE
								WHEN [dbo].[udfIsLanguageExcluded](C.CountryID, GS.PreferredLanguage) = 1 THEN C.DefaultLanguageID
								-- IF THERE IS A PREFERRED LANGUAGE, FIND THE CORRESPONDING LANGUAGEID
								ELSE L.LanguageID END
	FROM Stage.Global_Service GS
		INNER JOIN	#Completed CM ON GS.ID = CM.ID
		LEFT JOIN [$(SampleDB)].dbo.Languages L ON GS.PreferredLanguage = CASE	WHEN LEN(LTRIM(RTRIM(GS.PreferredLanguage))) = 2 THEN L.ISOAlpha2
																				WHEN LEN(LTRIM(RTRIM(GS.PreferredLanguage))) = 3 THEN L.ISOAlpha3
																				ELSE L.Language END
		LEFT JOIN [$(SampleDB)].ContactMechanism.Countries C ON C.CountryID = GS.CountryID			-- V1.10
	WHERE GS.PreferredLanguage <> ''

	
	--WE MAY NOT HAVE A DEFAULT LANGUAGE SET UP FOR THE LOADER, USE THE DEFAULT LANGUAGE FOR THE MARKET
	UPDATE GS
	SET GS.LanguageID = C.DefaultLanguageID
	FROM Stage.Global_Service GS
		INNER JOIN [$(SampleDB)].ContactMechanism.Countries C ON C.CountryID = GS.CountryID
	WHERE GS.LanguageID IS NULL

	
	-- V1.12 (See Comments above) 
	UPDATE GS
	SET GS.LanguageID = (SELECT LanguageID FROM [$(SampleDB)].dbo.Languages WHERE ISOAlpha3 ='LAO')
	FROM Stage.Global_Service GS
		INNER JOIN [$(SampleDB)].dbo.Languages L ON GS.LanguageID = L.LanguageID
	WHERE L.ISOAlpha2 = 'LO' 
	
	
	-- V1.13 (See Comments above)
	UPDATE GS
	SET GS.LanguageID = (SELECT LanguageID FROM [$(SampleDB)].dbo.Languages WHERE ISOAlpha3 ='TCH')
	FROM Stage.Global_Service GS
		INNER JOIN [$(SampleDB)].dbo.Languages L ON GS.LanguageID = L.LanguageID 
													AND L.ISOAlpha3 = 'ZHO'
	WHERE GS.CountryID = (SELECT CountryID FROM [$(SampleDB)].ContactMechanism.Countries WHERE CountryShortName = 'Hong Kong')	


	-- V1.18 Set Russian Language to Russian (EuroImporters)
	UPDATE GS
	SET GS.LanguageID = (SELECT LanguageID FROM [$(SampleDB)].dbo.Languages WHERE Language = 'Russian (EuroImporters)')
	FROM Stage.Global_Service GS
		INNER JOIN [$(SampleDB)].dbo.Languages L ON GS.LanguageID = L.LanguageID 
		INNER JOIN [$(SampleDB)].ContactMechanism.Countries C ON GS.CountryID = C.CountryID 
	WHERE L.Language = 'Russian'
		AND C.Country <> 'Russian Federation'


	---------------------------------------------------------------------------------------------------------
	-- Set CustomIdentifierFlag 
	---------------------------------------------------------------------------------------------------------	
	-- Dynamic formatting of special fields
	DECLARE @FieldName		NVARCHAR(200)=''
	DECLARE @FieldValue		NVARCHAR(200)=''
	
	SELECT DISTINCT @FieldValue = ColumnFormattingValue
	
	FROM [$(SampleDB)].dbo.SampleFileSpecialFormatting SF
		INNER JOIN [$(SampleDB)].dbo.vwBrandMarketQuestionnaireSampleMetadata SM ON SF.SampleFileID = SM.SampleFileID
	WHERE @SampleFileName LIKE SampleFileNamePrefix + '%'
		AND	ColumnFormattingIdentifier = 'CustomerIdentifierUsable'

	-- V1.2
	-- BY DEFAULT CUSTOMERIDENTIFIER MATCHING IS DISABLED
	UPDATE	GS 
	SET GS.CustomerIdentifierUsable = CAST(0 AS BIT)
	FROM Stage.Global_Service GS
		INNER JOIN	#Completed C ON GS.ID = C.ID	
	
	IF CAST(@FieldValue AS BIT) = 'True'	
		BEGIN	
			UPDATE GS
			SET	GS.CustomerIdentifier = CASE	WHEN LEN(LTRIM(RTRIM(ISNULL(GS.CustomerUniqueID,'')))) > 0 THEN LTRIM(RTRIM(ISNULL(GS.CustomerUniqueID,''))) + '_GSL_' + LTRIM(RTRIM(ISNULL(GS.CountryCode,'')))
												ELSE '' END, 
				CustomerIdentifierUsable = CAST(@FieldValue AS BIT)
			FROM Stage.Global_Service GS		
				INNER JOIN #Completed C ON GS.ID = C.ID						
		END
	ELSE 
		BEGIN 
			UPDATE GS
			SET GS.CustomerIdentifier = ISNULL(GS.CustomerUniqueID,'')
			FROM Stage.Global_Service GS		
				INNER JOIN #Completed C ON GS.ID = C.ID					
	END			
	
	---------------------------------------------------------------------------------------------------------
	-- Set any blank Model Years to NULL 
	---------------------------------------------------------------------------------------------------------
	UPDATE Stage.Global_Service
	SET ModelYear = NULL
	WHERE LEN(ModelYear) = 0
	
	-- V1.17
	UPDATE Stage.Global_Service
	SET ModelYear = CASE	-- 2021.0 or 2021.00  --> 2021
							WHEN ISNULL(PATINDEX('%.%', ModelYear),0) > 0 AND RIGHT(ModelYear, CHARINDEX('.', REVERSE(ModelYear)) - 1) IN ('0','00') THEN LEFT(ModelYear, ISNULL(PATINDEX('%.%', ModelYear),0)-1)
							-- 2021.5  --> 2021
							WHEN ISNULL(PATINDEX('%.%', ModelYear),0) > 0 AND RIGHT(ModelYear, CHARINDEX('.', REVERSE(ModelYear)) - 1) IN ('5') THEN LEFT(ModelYear, ISNULL(PATINDEX('%.%', ModelYear),0)-1)
							--2021. --> 2021
							WHEN PATINDEX('%.%', ModelYear) > 1 AND RIGHT(ModelYear,1) ='.' THEN TRY_CONVERT(INT, SUBSTRING(ModelYear, 1, LEN(ModelYear)-1))
							-- TRY TO CONVERT EVERYTHING ELSE
							ELSE TRY_CONVERT(INT,ModelYear) END

	-- V1.15
	IF EXISTS (	SELECT ModelYear 
				FROM Stage.Global_Service
				WHERE (ISNUMERIC(ModelYear) <> 1 AND ModelYear <> '')
					OR CONVERT(BIGINT, ModelYear) > 9999)			 
	BEGIN 
			-- Move misaligned model year records to holding table then remove from staging.
			INSERT INTO	Stage.Removed_Records_Staging_Tables (AuditID, FileName, ActionDate, PhysicalFileRow, VIN, Misaligned_ModelYear)
			SELECT GS.AuditID, 
				F.FileName, 
				F.ActionDate, 
				GS.PhysicalRowID, 
				GS.VIN, 
				GS.ModelYear
			FROM Stage.Global_Service GS
				INNER JOIN [$(AuditDB)].dbo.Files F ON GS.AuditID = F.AuditID
			WHERE (ISNUMERIC(GS.ModelYear) <> 1 AND GS.ModelYear <> '')
				OR CONVERT(BIGINT, GS.ModelYear) > 9999
			
			DELETE 
			FROM Stage.Global_Service
			WHERE (ISNUMERIC(ModelYear) <> 1
				AND ModelYear <> '')
			OR CONVERT(BIGINT, ModelYear) > 9999
	END 
	

	---------------------------------------------------------------------------------------------------------
	-- V1.3 Remove NoEmail@Contact.com email addresses
	---------------------------------------------------------------------------------------------------------
	UPDATE GS
	SET GS.EmailAddress1 = NULL
	FROM Stage.Global_Service GS
	WHERE GS.EmailAddress1 IN ('noemail@contact.com','noemail@contract.com','noemail@jlr.com','noemail@nocontact.com')

	UPDATE GS
	SET GS.EmailAddress2 = NULL
	FROM Stage.Global_Service GS
	WHERE GS.EmailAddress2 IN ('noemail@contact.com','noemail@contract.com','noemail@jlr.com','noemail@nocontact.com')


	---------------------------------------------------------------------------------------------------------
	-- V1.9 Swap FirstName and LastName For Taiwan (CountryID = 202)
	---------------------------------------------------------------------------------------------------------
	UPDATE GS 
	SET GS.SurnameField1 = GS.FirstName, 
		GS.FirstName = NULL
	FROM Stage.Global_Service GS
		INNER JOIN [$(AuditDB)].dbo.Files F ON GS.AuditID = F.AuditID
	WHERE GS.CountryID = (SELECT CountryID FROM [$(SampleDB)].[ContactMechanism].[Countries] WHERE CountryShortName = 'Taiwan')
		AND F.FileName = @SampleFileName
	

	---------------------------------------------------------------------------------------------------------
	-- Set Salutation field 
	---------------------------------------------------------------------------------------------------------
	--SET @FieldName = ''
	SET  @FieldValue = ''
	
	IF EXISTS (	SELECT DISTINCT SF.ColumnFormattingValue
				FROM [$(SampleDB)].dbo.SampleFileSpecialFormatting SF
					INNER JOIN [$(SampleDB)].dbo.vwBrandMarketQuestionnaireSampleMetadata SM ON SF.SampleFileID = SM.SampleFileID
				WHERE @SampleFileName LIKE SM.SampleFileNamePrefix + '%'
					AND	SF.ColumnFormattingIdentifier = 'Salutation')
	BEGIN
	
			SELECT DISTINCT @FieldValue = ColumnFormattingValue
			FROM [$(SampleDB)].dbo.SampleFileSpecialFormatting SF
				INNER JOIN [$(SampleDB)].dbo.vwBrandMarketQuestionnaireSampleMetadata SM ON SF.SampleFileID = SM.SampleFileID
			WHERE @SampleFileName LIKE SM.SampleFileNamePrefix + '%'
				AND	SF.ColumnFormattingIdentifier = 'Salutation'

			-- V1.8 where clause added to only update rows from current file
			UPDATE GS
			SET	GS.Salutation = @FieldValue
			FROM Stage.Global_Service GS 
				INNER JOIN [$(AuditDB)].dbo.Files F ON GS.AuditID = F.AuditID
			WHERE F.FileName = @SampleFileName
			
	END 
	
	-- V1.14
	UPDATE Stage.Global_Service 
	SET EventType = ISNULL(NULLIF(EventType,''),0)

	
	---------------------------------------------------------------------------------------------------------
	--Validate for all records that require metadata fields to be populated. Raise an error otherwise.
	---------------------------------------------------------------------------------------------------------
	IF EXISTS (	SELECT ID 
				FROM Stage.Global_Service 
				WHERE ManufacturerPartyID IS NULL 
					OR SampleSupplierPartyID IS NULL 
					OR CountryID IS NULL 
					OR EventTypeID IS NULL 
					OR DealerCodeOriginatorPartyID IS NULL 
					OR SetNameCapitalisation IS NULL 
					OR LanguageID IS NULL 
					OR (ModelYear IS NOT NULL AND ISNUMERIC(ModelYear) = 0))
			
			RAISERROR(	N'Data in Stage.Global_Service has missing Meta-Data.', 
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
		INTO [$(ErrorDB)].Stage.Global_Service_' + @TimestampString + '
		FROM Stage.Global_Service
	')
	
	-- FINALLY RAISE THE ERROR
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH