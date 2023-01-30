CREATE PROCEDURE [Stage].[uspStandardise_Global_CQI]
/*
	Purpose:		(I)		Convert the supplied dates from a text string to a valid DATETIME type
					(II)	Populate mandatory meta data
	
	Version			Date			Developer			Comment
	1.1				09/01/2015		Chris Ross			Sample mapping definitions not communicated to client correctly and so are changing global
														mapping to use Service Date as Sales Event date and Purchase Date will now be invoice date.
	1.2				22/04/2015		Eddie Thomas		BUG 11402 : Remapping preferred language to English (MENA)
	1.3				15/06/2015		Eddie Thomas		CustomIdnetifierUsable now set in proc NOT in package.
	1.4				15/06/2015		Chris Ross			BUG 11626 : Remove NoEmail@JLR.com email addresses from staging
	1.5				16/06/2015		Eddie Thomas		Revised preferred language settting to be be driven by Meta-Data (BUG 11545 - European Importer setup)  			
	1.6				26/06/2015		Jean Rebello		Added Dummy Phone Number Feature (BUG 11317 - Dummy Phone Number Feature)
	1.7				26/11/2015		Chris Ledger		Fixed issue with Salutations being removed from all loaded files if one removed. 
	1.8				15/03/2016		Chris Ledger		BUG 12021: MENA Languages by country
	1.9				07/06/2016		Chris Ledger		Set Taiwan FirstName to SurNameField1
	1.10			09/06/2016		Chris Ledger		Remove SampleFileID from udfIsLanguageExcluded 
	1.11			01/01/2017		Ben King			BUG 13444 Add check on ModelYear alignment
	1.12			11/04/2017		Eddie Thomas		BUG 13698 Remapping LO language code to LAO
	1.13			25/10/2017		Eddie Thomas		BUG 14326 - Remapping Hong Kong Chinese speakers to a new Chinese language variant
	
	1.14			16/10/2019		Chris Ledger		Copied from dbo.uspStandardise_Global_Sales
	1.15			16/12/2019		Chris Ledger		BUG 16673: SampleTriggeredSelectionReqID set to 0 even though SampleTriggeredSelection set to 1 (avoids normal selections being created).
	1.16			18/12/2019		Chris Ledger		BUG 16673: Filter Records to Update by File Loaded
	1.17			22/04/2021		Chris Ledger		Tidy up formatting in preparation for restart of CQI
*/
		@SampleFileName  NVARCHAR(100)

AS

DECLARE @ErrorNumber			INT
DECLARE @ErrorSeverity			INT
DECLARE @ErrorState				INT
DECLARE @ErrorLocation			NVARCHAR(500)
DECLARE @ErrorLine				INT
DECLARE @ErrorMessage			NVARCHAR(2048)

SET LANGUAGE ENGLISH

BEGIN TRY

	----------------------------------------------------------------------------------------------------
	-- Set the BMQ specific load variables 
	----------------------------------------------------------------------------------------------------
	;WITH RecordsToUpdate (ID, Manufacturer, CountryCode, EventType, Country, CountryID) AS
	(
		--Add In CountryID
		SELECT GC.ID, 
			GC.Manufacturer, 
			GC.CountryCode, 
			GC.EventType, 
			C.Country, 
			C.CountryID
		FROM Stage.Global_CQI GC
		INNER JOIN [$(AuditDB)].dbo.Files F ON GC.AuditID = F.AuditID		-- V1.16
		INNER JOIN [$(SampleDB)].ContactMechanism.Countries	C ON GC.CountryCode = (CASE	WHEN LEN(GC.CountryCode) = 2 THEN C.ISOAlpha2
																						ELSE C.ISOAlpha3 END)	
		WHERE F.FileName = @SampleFileName									-- V1.16
	)
	--Retrieve Metadata values for each event in the table
	SELECT DISTINCT 
		RU.*, 
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
							M.CountryID, ET.EventTypeID,  
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
							INNER JOIN [$(SampleDB)].[Event].EventTypes ET ON ET.EventType = M.Questionnaire
							INNER JOIN [$(SampleDB)].ContactMechanism.Countries	C ON C.CountryID = M.CountryID
						WHERE M.SampleLoadActive = 1 
							AND @SampleFileName LIKE SampleFileNamePrefix + '%') MD ON RU.Manufacturer = MD.Brand 
																						AND	RU.CountryID = MD.CountryID
							
							
	--Populate the meta data fields for each record
	UPDATE GC
	SET ManufacturerPartyID	= C.ManufacturerPartyID,	 
		SampleSupplierPartyID = C.ManufacturerPartyID,
		CountryID = C.CountryID,
		EventTypeID	= C.EventTypeID,
		DealerCodeOriginatorPartyID	= C.DealerCodeOriginatorPartyID,
		SetNameCapitalisation = C.SetNameCapitalisation,
		SampleTriggeredSelectionReqID = (CASE	WHEN C.CreateSelection = 1 AND C.SampleTriggeredSelection = 1 THEN 0	-- V1.15
												ELSE 0 END)
	FROM Stage.Global_CQI GC
		INNER JOIN #Completed C ON GC.ID = C.ID	
	
	
	---------------------------------------------------------------------------------------------------------
	-- Convert the Purchase Date 
	---------------------------------------------------------------------------------------------------------
	UPDATE Stage.Global_CQI
	SET ConvertedVehiclePurchaseDate = CONVERT(DATETIME, VehiclePurchaseDate, 103)
	WHERE NULLIF(VehiclePurchaseDate, '') IS NOT NULL	
	
	
	---------------------------------------------------------------------------------------------------------
	-- Convert the Delivery Date 
	---------------------------------------------------------------------------------------------------------
	UPDATE Stage.Global_CQI
	SET ConvertedVehicleDeliveryDate = CONVERT(DATETIME, VehicleDeliveryDate, 103)
	WHERE NULLIF(VehicleDeliveryDate, '') IS NOT NULL
	

	---------------------------------------------------------------------------------------------------------
	-- Convert the Registration Date 
	---------------------------------------------------------------------------------------------------------
	UPDATE Stage.Global_CQI
	SET ConvertedVehicleRegistrationDate = CONVERT(DATETIME, VehicleRegistrationDate, 103)
	WHERE NULLIF(VehicleRegistrationDate, '') IS NOT NULL
	

	---------------------------------------------------------------------------------------------------------
	-- Update (cleardown) the TelephoneNumbers, if a Dummy one is supplied
	---------------------------------------------------------------------------------------------------------	  
	DECLARE @FieldNameForDummyTN	NVARCHAR(200) = ''
	DECLARE @FieldValueForDummyTN   NVARCHAR(200) = ''
		
	SELECT DISTINCT	@FieldNameForDummyTN = ColumnFormattingIdentifier,
		@FieldValueForDummyTN = ColumnFormattingValue
	FROM [$(SampleDB)].dbo.SampleFileSpecialFormatting SF
		INNER JOIN [$(SampleDB)].dbo.vwBrandMarketQuestionnaireSampleMetadata SM ON SF.SampleFileID = SM.SampleFileID
	WHERE @SampleFileName LIKE SampleFileNamePrefix + '%'	
		AND ColumnFormattingIdentifier = 'clearDummyTelephoneNumber'
		
	IF @FieldNameForDummyTN = 'clearDummyTelephoneNumber'		
		BEGIN		
			UPDATE GC
			SET GC.HomeTelephoneNumber = [Lookup].udfClearDummyTelephoneNumbers(GC.HomeTelephoneNumber, @FieldValueForDummyTN),
				GC.BusinessTelephoneNumber = [Lookup].udfClearDummyTelephoneNumbers(GC.BusinessTelephoneNumber, @FieldValueForDummyTN),
				GC.MobileTelephoneNumber =	[Lookup].udfClearDummyTelephoneNumbers(GC.MobileTelephoneNumber, @FieldValueForDummyTN)
			FROM Stage.Global_CQI GC						
		END	

	
	---------------------------------------------------------------------------------------------------------
	-- Convert the Service Date   Actually this is Sales Event Date
	---------------------------------------------------------------------------------------------------------
	UPDATE Stage.Global_CQI
	SET ConvertedServiceEventDate = CONVERT(DATETIME, ServiceEventDate, 103)
	WHERE NULLIF(ServiceEventDate, '') IS NOT NULL
	
	
	---------------------------------------------------------------------------------------------------------
	-- Set any blank Model Years to NULL 
	---------------------------------------------------------------------------------------------------------
	UPDATE Stage.Global_CQI
	SET ModelYear = NULL
	WHERE LEN(ModelYear) = 0	


	---------------------------------------------------------------------------------------------------------
	-- Update the preferred LanguageID, if a Preferred language supplied
	---------------------------------------------------------------------------------------------------------	
	-- UPDATE AZERBI TO AZERBAJANII
	UPDATE GC
	SET GC.PreferredLanguage = 'Azerbaijani'
	FROM Stage.Global_CQI GC
	WHERE GC.PreferredLanguage = 'Azeri'
	
	--V1.5 (See Comments above)
	UPDATE GC
	SET	LanguageID = CASE	--IF PREFERRED LANGUAGE ISN'T PERMITTED, SET LANGUAGE TO A DESIGNATED DEFAULT LANGUAGE
							WHEN dbo.udfIsLanguageExcluded(DL.CountryID, GC.PreferredLanguage) = 1 THEN DL.DefaultLanguageID
							--IF THERE IS A PREFERRED LANGUAGE, FIND THE CORRESPONDING LANGUAGEID
							ELSE L.LanguageID END																
	FROM Stage.Global_CQI GC
		INNER JOIN #Completed CM ON GC.ID = CM.ID
		LEFT JOIN [$(SampleDB)].dbo.Languages L ON GC.PreferredLanguage = CASE WHEN LEN(LTRIM(RTRIM(GC.PreferredLanguage))) = 2 THEN L.ISOAlpha2
																				WHEN LEN(LTRIM(RTRIM(GC.PreferredLanguage))) = 3 THEN L.ISOAlpha3
																				ELSE L.Language END	
		LEFT JOIN [$(SampleDB)].ContactMechanism.Countries DL ON DL.CountryID = GC.CountryID	
	WHERE GC.PreferredLanguage <> ''
	
	
	--WE MAY NOT HAVE A DEFAULT LANGUAGE SET UP FOR THE LOADER, USE THE DEFAULT LANGUAGE FOR THE MARKET
	UPDATE GC
	SET	GC.LanguageID = C.DefaultLanguageID
	FROM Stage.Global_CQI GC
		INNER JOIN [$(SampleDB)].ContactMechanism.Countries C ON C.CountryID = GC.CountryID
	WHERE GC.LanguageID IS NULL
	-- V1.5 (See Comments above) 
	
	
	-- V1.12 (See Comments above)
	UPDATE GC
	SET	LanguageID = (	SELECT LanguageID 
						FROM [$(SampleDB)].dbo.Languages 
						WHERE ISOAlpha3 ='LAO')
	FROM Stage.Global_CQI GC
		INNER JOIN [$(SampleDB)].dbo.Languages L ON GC.LanguageID = L.LanguageID
	WHERE L.ISOAlpha2 = 'LO'
	

	-- V1.13 (See Comments above)
	UPDATE GC
	SET	LanguageID = (	SELECT LanguageID 
						FROM [$(SampleDB)].dbo.Languages 
						WHERE ISOAlpha3 ='TCH')
	FROM Stage.Global_CQI GC
		INNER JOIN [$(SampleDB)].dbo.Languages L ON GC.LanguageID = L.LanguageID 
													AND L.ISOAlpha3 = 'ZHO'
	WHERE GC.CountryID = (	SELECT CountryID 
							FROM [$(SampleDB)].ContactMechanism.Countries 
							WHERE CountryShortName = 'Hong Kong')	
	
	 
	---------------------------------------------------------------------------------------------------------
	--Set CustomIdentifierFlag									
	---------------------------------------------------------------------------------------------------------
	DECLARE @FieldName	NVARCHAR(200) = ''
	DECLARE @FieldValue	NVARCHAR(200) = ''
	
	--Dynamic formatting of special fields
	SET @FieldValue = ''
	
	SELECT DISTINCT @FieldValue = SF.ColumnFormattingValue
	FROM [$(SampleDB)].dbo.SampleFileSpecialFormatting SF
		INNER JOIN [$(SampleDB)].dbo.vwBrandMarketQuestionnaireSampleMetadata SM ON SF.SampleFileID = SM.SampleFileID
	WHERE @SampleFileName LIKE SM.SampleFileNamePrefix + '%' 
		AND	SF.ColumnFormattingIdentifier = 'CustomerIdentifierUsable'

	
	--BY DEFAULT CUSTOMERIDENTIFIER MATCHING IS DISABLED
	UPDATE GC 
	SET GC.CustomerIdentifierUsable = CAST(0 AS BIT)
	FROM Stage.Global_CQI GC
		INNER JOIN #Completed C ON GC.ID = C.ID	
	
	IF CAST(@FieldValue AS BIT) = 'True'	
		BEGIN	
			UPDATE GC				
			SET GC.CustomerIdentifier = CASE	WHEN LEN(LTRIM(RTRIM(ISNULL(GC.CustomerUniqueID, '')))) > 0 THEN LTRIM(RTRIM(ISNULL(GC.CustomerUniqueID, ''))) + '_GSL_' + LTRIM(RTRIM(ISNULL(GC.CountryCode, '')))
												ELSE '' END, 
				GC.CustomerIdentifierUsable = CAST(@FieldValue AS BIT)
			FROM Stage.Global_CQI GC		
				INNER JOIN #Completed C ON GC.ID = C.ID						
		END	
	ELSE 
		BEGIN 
			UPDATE GC
			SET GC.CustomerIdentifier = ISNULL(GC.CustomerUniqueID,'')
			FROM Stage.Global_CQI GC		
				INNER JOIN #Completed C ON GC.ID = C.ID					
		END		
	
	
	---------------------------------------------------------------------------------------------------------
	-- Remove NoEmail@Contact.com email addresses					
	---------------------------------------------------------------------------------------------------------	
	UPDATE GC
	SET EmailAddress1 = NULL
	FROM Stage.Global_CQI GC
	WHERE GC.EmailAddress1 IN ('noemail@contact.com',
							  'noemail@contract.com',
							  'noemail@jlr.com',
							  'noemail@nocontact.com')

	UPDATE GC
	SET EmailAddress2 = NULL
	FROM Stage.Global_CQI GC
	WHERE GC.EmailAddress2 IN ('noemail@contact.com',
							  'noemail@contract.com',
							  'noemail@jlr.com',
							  'noemail@nocontact.com')

	
	---------------------------------------------------------------------------------------------------------
	-- Swap FirstName and LastName For Taiwan (CountryID = 202)	
	---------------------------------------------------------------------------------------------------------
	UPDATE GC SET GC.SurnameField1 = GC.FirstName, 
		GC.FirstName = NULL
	FROM Stage.Global_CQI GC
		INNER JOIN [$(AuditDB)].dbo.Files F ON GC.AuditID = F.AuditID
	WHERE GC.CountryID = 202
		AND F.FileName = @SampleFileName
	

	---------------------------------------------------------------------------------------------------------
	-- Set Salutation field 
	---------------------------------------------------------------------------------------------------------
	--SET @FieldName = ''
	SET  @FieldValue = ''
	
	IF EXISTS (	SELECT DISTINCT SF.ColumnFormattingValue
				FROM [$(SampleDB)].dbo.SampleFileSpecialFormatting SF
					INNER JOIN [$(SampleDB)].dbo.vwBrandMarketQuestionnaireSampleMetadata SM ON SF.SampleFileID = SM.SampleFileID
				WHERE @SampleFileName LIKE SampleFileNamePrefix + '%'
					AND	ColumnFormattingIdentifier = 'Salutation')
		BEGIN
			SELECT DISTINCT @FieldValue = SF.ColumnFormattingValue		
			FROM [$(SampleDB)].dbo.SampleFileSpecialFormatting SF
				INNER JOIN [$(SampleDB)].dbo.vwBrandMarketQuestionnaireSampleMetadata SM ON SF.SampleFileID = SM.SampleFileID
			WHERE @SampleFileName LIKE SM.SampleFileNamePrefix + '%'
				AND	SF.ColumnFormattingIdentifier = 'Salutation'

			-- V 1.7 WHERE clause added to only update rows from current file
			UPDATE Stage.Global_CQI 
			SET	Salutation = @FieldValue
			FROM Stage.Global_CQI S 
				INNER JOIN [$(AuditDB)].dbo.Files F ON S.AuditID = F.AuditID
			WHERE F.FileName = @SampleFileName
		END 


	---------------------------------------------------------------------------------------------------------
	--Validate for all records that require metadata fields to be populated. Raise an error otherwise.
	---------------------------------------------------------------------------------------------------------
	IF EXISTS ( SELECT ID 
				FROM Stage.Global_CQI
				WHERE (ManufacturerPartyID IS NULL 
					OR SampleSupplierPartyID IS NULL
					OR CountryID IS NULL 
					OR EventTypeID IS NULL 
					OR DealerCodeOriginatorPartyID IS NULL 
					OR SetNameCapitalisation IS NULL 
					OR LanguageID IS NULL 
					OR (ModelYear IS NOT NULL AND ISNUMERIC(ModelYear) = 0))
			)			 
	RAISERROR(	N'Data in Stage.Global_CQI has missing Meta-Data.', 
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
	
	EXEC ('	SELECT *
			INTO [$(ErrorDB)].Stage.Global_CQI_' + @TimestampString + '
			FROM Stage.Global_CQI')
	
	-- FINALLY RAISE THE ERROR
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH