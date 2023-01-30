CREATE PROCEDURE [Stage].[uspStandardise_Global_LostLeads]

/*
		Purpose:	(I)		Convert the supplied dates FROM a text string to a valid DATETIME type
					(II)	Populate mandatory meta data
	
		Version		Date			Developer			Comment
LIVE	1.0			09/08/2016		Chris Ross			Created FROM [Sample_ETL].dbo.uspStandardise_Global_Sales
LIVE	1.1			01/08/2018		Eddie Thomas		BUG 14820 - Lost Leads Global loader change
LIVE	1.2         06/08/2019      Ben King            BUG 15311 - Prevent Partial Load
LIVE	1.3			25/10/2019		Chris Ledger		BUG 15490 - Add PreOwned Events
LIVE	1.4			04/11/2019		Chris Ledger		BUG 16737 - Only Match  'PreOwned LostLeads' UK Questionnaire
LIVE	1.5			08/09/2021		Chris Ledger		TASK 585 - Recode Jaguar US/Canada Dealers (i.e. 'J1234' to '01234') & Tidy Formatting
LIVE	1.6			18/10/2022		Chris Ledger		TASK 1046 - Remove matching of 'PreOwned LostLeads'
*/

@SampleFileName  NVARCHAR(100)

AS

DECLARE @ErrorNumber	INT

DECLARE @ErrorSeverity	INT
DECLARE @ErrorState		INT
DECLARE @ErrorLocation	NVARCHAR(500)
DECLARE @ErrorLine		INT
DECLARE @ErrorMessage	NVARCHAR(2048)

SET LANGUAGE ENGLISH

BEGIN TRY

	----------------------------------------------------------------------------------------------------
	-- Set the BMQ specific load variables 
	----------------------------------------------------------------------------------------------------
	;WITH RecordsToUpdate (ID, Manufacturer, CountryCode, EventType, Country, CountryID) AS
	(
		--Add In CountryID
		SELECT GS.ID, 
			GS.Manufacturer, 
			GS.CountryCode, 
			GS.EventType, 
			C.Country,
			C.CountryID
		FROM Stage.Global_LostLeads	GS
			INNER JOIN	[$(SampleDB)].ContactMechanism.Countries C ON GS.CountryCode = (CASE	WHEN LEN(GS.CountryCode) = 2 THEN ISOAlpha2
																								ELSE ISOAlpha3 END)	
	)
	--Retrieve Metadata values for each event in the table
	SELECT	DISTINCT RU.*, 
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
							INNER JOIN [$(SampleDB)].ContactMechanism.Countries C ON C.CountryID = M.CountryID
						WHERE M.SampleLoadActive = 1
							AND @SampleFileName LIKE SampleFileNamePrefix + '%') MD ON RU.Manufacturer = MD.Brand 
																						AND RU.CountryID = MD.CountryID 
																						AND CASE	WHEN RU.EventType = 2 AND RU.CountryCode = 'GB' THEN 'PreOwned LostLeads' 
																									ELSE 'LostLeads' END = MD.Questionnaire		-- V1.3 V1.4
							
							
	--Populate the meta data fields for each record
	UPDATE GS
	SET GS.ManufacturerPartyID	= C.ManufacturerPartyID,	 
		GS.SampleSupplierPartyID = C.ManufacturerPartyID,
		GS.CountryID = C.CountryID,
		GS.EventTypeID = C.EventTypeID,
		--GS.LanguageID = C.LanguageID,
		GS.DealerCodeOriginatorPartyID	= C.DealerCodeOriginatorPartyID,
		GS.SetNameCapitalisation = C.SetNameCapitalisation,
		GS.SampleTriggeredSelectionReqID = CASE	WHEN C.CreateSelection = 1 AND C.SampleTriggeredSelection = 1 THEN C.QuestionnaireRequirementID
												ELSE 0 END
	FROM Stage.Global_LostLeads GS
		INNER JOIN	#Completed C ON GS.ID = C.ID	


	---------------------------------------------------------------------------------------------------------
	-- V1.6 V1.4 UPDATE EventTypeID TO PreOwned LostLeads WHERE EventType = 2
	---------------------------------------------------------------------------------------------------------
	/*
	UPDATE Stage.Global_LostLeads
	SET EventTypeID = (	SELECT EventTypeID 
						FROM [$(SampleDB)].Event.EventTypes 
						WHERE EventType = 'PreOwned LostLeads')
	WHERE EventType = 2
	*/

		
	---------------------------------------------------------------------------------------------------------
	-- Convert the DateMarkedAsLostLead Date  
	---------------------------------------------------------------------------------------------------------
	UPDATE Stage.Global_LostLeads
	SET	ConvertedDateMarkedAsLostLead = CONVERT(DATETIME, DateMarkedAsLostLead, 103)
	WHERE NULLIF(DateMarkedAsLostLead, '') IS NOT NULL


	---------------------------------------------------------------------------------------------------------
	-- Convert the DateOfLastContact Date  
	---------------------------------------------------------------------------------------------------------
	UPDATE Stage.Global_LostLeads
	SET ConvertedDateOfLastContact = CONVERT(DATETIME, DateOfLastContact, 103)
	WHERE NULLIF(DateOfLastContact, '') IS NOT NULL	


	---------------------------------------------------------------------------------------------------------
	-- V1.2 Check Model Year is numeric. If not, when appended to VWT, data flow will fail.
	---------------------------------------------------------------------------------------------------------
	IF EXISTS (	SELECT ModelYear 
				FROM Stage.Global_LostLeads
				WHERE (ISNUMERIC(ModelYear) <> 1 AND ModelYear <> '')
					OR CONVERT(BIGINT, ModelYear) > 9999)                
	BEGIN 
		--Move misaligned model year records to holding table then remove FROM staging.
		INSERT INTO Stage.Removed_Records_Staging_Tables (AuditID, FileName, ActionDate, PhysicalFileRow, Misaligned_ModelYear)
		SELECT LL.AuditID, 
			F.FileName, 
			F.ActionDate, 
			LL.PhysicalRowID, 
			LL.ModelYear
		FROM  Stage.Global_LostLeads LL
			INNER JOIN [$(AuditDB)].dbo.Files F ON LL.AuditID = F.AuditID
		WHERE (ISNUMERIC(LL.ModelYear) <> 1 AND LL.ModelYear <> '')
			OR CONVERT(BIGINT, LL.ModelYear) > 9999
                  
		DELETE 
		FROM Stage.Global_LostLeads
		WHERE (ISNUMERIC(ModelYear) <> 1 AND ModelYear <> '')
			OR CONVERT(BIGINT, ModelYear) > 9999
	END


	---------------------------------------------------------------------------------------------------------
	-- Update (cleardown) the TelephoneNumbers, if a Dummy one is supplied 
	---------------------------------------------------------------------------------------------------------
	DECLARE @FieldNameForDummyTN				NVARCHAR(200)=''
	DECLARE @FieldValueForDummyTN   			NVARCHAR(200)=''
		
	SELECT DISTINCT	@FieldNameForDummyTN = ColumnFormattingIdentifier,
		@FieldValueForDummyTN = ColumnFormattingValue
	FROM [$(SampleDB)].dbo.SampleFileSpecialFormatting SF
		INNER JOIN [$(SampleDB)].dbo.vwBrandMarketQuestionnaireSampleMetadata SM ON SF.SampleFileID = SM.SampleFileID  
	WHERE @SampleFileName LIKE SampleFileNamePrefix + '%'	
		AND ColumnFormattingIdentifier = 'clearDummyTelephoneNumber'
		
	IF @FieldNameForDummyTN = 'clearDummyTelephoneNumber'		
	BEGIN	
			
		UPDATE GS
		SET GS.HomeTelephoneNumber = Lookup.udfClearDummyTelephoneNumbers(GS.HomeTelephoneNumber,@FieldValueForDummyTN),
			GS.BusinessTelephoneNumber = Lookup.udfClearDummyTelephoneNumbers(GS.BusinessTelephoneNumber,@FieldValueForDummyTN),
			GS.MobileTelephoneNumber = Lookup.udfClearDummyTelephoneNumbers(GS.MobileTelephoneNumber,@FieldValueForDummyTN)
		FROM Stage.Global_LostLeads GS
					
	END	

	
	---------------------------------------------------------------------------------------------------------
	-- Set any blank Model Years to NULL 
	---------------------------------------------------------------------------------------------------------
	UPDATE Stage.Global_LostLeads
	SET	ModelYear = NULL
	WHERE LEN(ModelYear) = 0


	---------------------------------------------------------------------------------------------------------
	-- Update the preferred LanguageID, if a Preferred language supplied
	---------------------------------------------------------------------------------------------------------
	--V1.8 UPDATE AZERBI TO AZERBAJANII
	UPDATE GS
	SET GS.PreferredLanguage = 'Azerbaijani'
	FROM Stage.Global_LostLeads GS
	WHERE GS.PreferredLanguage = 'Azeri'

	--V1.5 (See Comments above)
	UPDATE GS
	SET	LanguageID = CASE	WHEN [dbo].[udfIsLanguageExcluded](DL.CountryID,GS.PreferredLanguage) = 1 THEN DL.DefaultLanguageID		--IF PREFERRED LANGUAGE ISN'T PERMITTED, SET LANGUAGE TO A DESIGNATED DEFAULT LANGUAGE
							ELSE LA.LanguageID END																					--IF THERE IS A PREFERRED LANGUAGE, FIND THE CORRESPONDING LANGUAGEID
	FROM Stage.Global_LostLeads	GS
		INNER JOIN #Completed CM ON GS.ID = CM.ID
		LEFT JOIN [$(SampleDB)].dbo.Languages LA ON GS.PreferredLanguage = CASE	WHEN LEN(LTRIM(RTRIM(GS.PreferredLanguage))) = 2 THEN LA.ISOAlpha2
																				WHEN LEN(LTRIM(RTRIM(GS.PreferredLanguage))) = 3 THEN LA.ISOAlpha3
																				ELSE LA.Language END
		LEFT JOIN [$(SampleDB)].ContactMechanism.Countries	DL ON DL.CountryID = GS.CountryID										-- V1.10
	WHERE GS.PreferredLanguage <> ''
	
	
	--WE MAY NOT HAVE A DEFAULT LANGUAGE SET UP FOR THE LOADER, USE THE DEFAULT LANGUAGE FOR THE MARKET
	UPDATE GS
	SET GS.LanguageID = C.DefaultLanguageID
	FROM Stage.Global_LostLeads GS
		INNER JOIN [$(SampleDB)].ContactMechanism.Countries C ON C.CountryID = GS.CountryID
	WHERE GS.LanguageID IS NULL
	-- V1.5 (See Comments above) 
	
	
	---------------------------------------------------------------------------------------------------------
	--Set CustomIdentifierFlag -- V1.3 
	---------------------------------------------------------------------------------------------------------
	DECLARE @FieldName	NVARCHAR(200)=''
	DECLARE @FieldValue	NVARCHAR(200)=''
	
	--Dynamic formatting of special fields
	SET @FieldValue = ''
	
	SELECT DISTINCT @FieldValue = ColumnFormattingValue
	FROM [$(SampleDB)].dbo.SampleFileSpecialFormatting SF
		INNER JOIN [$(SampleDB)].dbo.vwBrandMarketQuestionnaireSampleMetadata SM ON SF.SampleFileID = SM.SampleFileID
	WHERE @SampleFileName LIKE SM.SampleFileNamePrefix + '%'
		AND SF.ColumnFormattingIdentifier = 'CustomerIdentifierUsable'

	
	--BY DEFAULT CUSTOMERIDENTIFIER MATCHING IS DISABLED
	UPDATE GS 
	SET GS.CustomerIdentifierUsable = CAST(0 AS BIT)
	FROM Stage.Global_LostLeads GS
	INNER JOIN #Completed C ON GS.ID = C.ID	
	
	IF CAST(@FieldValue AS BIT) = 'True'	
		BEGIN	
			UPDATE GS	
			SET CustomerIdentifier = CASE	WHEN LEN(LTRIM(RTRIM(ISNULL(GS.CustomerUniqueID,'')))) > 0 THEN LTRIM(RTRIM(ISNULL(GS.CustomerUniqueID,''))) + '_GSL_' + LTRIM(RTRIM(ISNULL(GS.CountryCode,'')))
											ELSE '' END, 
				CustomerIdentifierUsable =  CAST(@FieldValue AS BIT)
			FROM Stage.Global_LostLeads	GS		
				INNER JOIN	#Completed C ON GS.ID = C.ID						
		END	
	ELSE 
		BEGIN 
			UPDATE GS 
			SET GS.CustomerIdentifier = ISNULL(GS.CustomerUniqueID,'')
			FROM Stage.Global_LostLeads	GS		
				INNER JOIN	#Completed C ON GS.ID = C.ID					
		END		
	
	
	---------------------------------------------------------------------------------------------------------
	-- Remove NoEmail@Contact.com email addresses					-- V1.4	
	---------------------------------------------------------------------------------------------------------
	UPDATE GS
	SET GS.EmailAddress1 = NULL
	FROM Stage.Global_LostLeads GS
	WHERE GS.EmailAddress1 IN ('noemail@contact.com', 'noemail@contract.com', 'noemail@jlr.com', 'noemail@nocontact.com')

	UPDATE GS
	SET GS.EmailAddress2 = NULL
	FROM Stage.Global_LostLeads GS
	WHERE GS.EmailAddress2 IN ('noemail@contact.com','noemail@contract.com', 'noemail@jlr.com', 'noemail@nocontact.com')

	
	---------------------------------------------------------------------------------------------------------
	-- Swap FirstName and LastName For Taiwan (CountryID = 202)	-- V1.9	
	---------------------------------------------------------------------------------------------------------
	UPDATE GS 
	SET GS.SurnameField1 = GS.FirstName, 
		GS.FirstName = NULL
	FROM Stage.Global_LostLeads GS
		INNER JOIN [$(AuditDB)].dbo.Files F ON GS.AuditID = F.AuditID
	WHERE GS.CountryID = 202
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
	
			SELECT DISTINCT @FieldValue = ColumnFormattingValue	
			FROM [$(SampleDB)].dbo.SampleFileSpecialFormatting SF
				INNER JOIN [$(SampleDB)].dbo.vwBrandMarketQuestionnaireSampleMetadata SM ON SF.SampleFileID = SM.SampleFileID
			WHERE @SampleFileName LIKE SampleFileNamePrefix + '%'
				AND	ColumnFormattingIdentifier = 'Salutation'

			-- V1.7 WHERE clause added to only update rows FROM current file
			UPDATE S 
			SET S.Salutation = @FieldValue
			FROM Stage.Global_LostLeads S 
				INNER JOIN [$(AuditDB)].dbo.Files F ON S.AuditID = F.AuditID
			WHERE F.FileName = @SampleFileName
	
	END 
	
	UPDATE Stage.Global_LostLeads 
	SET EventType = ISNULL(NULLIF(EventType,''),0)
	
	
	---------------------------------------------------------------------------------------------------------
	-- V1.5 Update US Jaguar DealerCode from 'J1234' to '01234'
	---------------------------------------------------------------------------------------------------------
	UPDATE LL
	SET LL.DealerCode = '0' + SUBSTRING(LL.DealerCode, 2, LEN(LL.DealerCode)-1)
	FROM Stage.Global_LostLeads LL
	WHERE LL.CountryCode IN ('US','CA')
		AND LL.Manufacturer = 'Jaguar'
		AND SUBSTRING(LL.DealerCode, 1, 1) = 'J'


	---------------------------------------------------------------------------------------------------------
	--Validate for all records that require metadata fields to be populated. Raise an error otherwise.
	---------------------------------------------------------------------------------------------------------
	IF EXISTS ( SELECT ID 
				FROM Stage.Global_LostLeads 
				WHERE ManufacturerPartyID IS NULL
					OR SampleSupplierPartyID IS NULL 
					OR CountryID IS NULL
					OR EventTypeID IS NULL 
					OR DealerCodeOriginatorPartyID IS NULL 
					OR SetNameCapitalisation IS NULL
					OR LanguageID IS NULL)
	RAISERROR (	N'Data in Stage.Global_LostLeads has missing Meta-Data.', 16, 1)

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
		INTO [$(ErrorDB)].Stage.Global_LostLeads_' + @TimestampString + '
		FROM Stage.Global_LostLeads
	')
	
	-- FINALLY RAISE THE ERROR
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH