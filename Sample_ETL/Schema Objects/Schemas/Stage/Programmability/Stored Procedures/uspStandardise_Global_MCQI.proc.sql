CREATE PROCEDURE [Stage].[uspStandardise_Global_MCQI]
/*
	Purpose:		(I)		Convert the supplied dates from a text string to a valid DATETIME type
					(II)	Populate mandatory meta data
	
	Version			Date			Developer			Comment
	1.1				2020-02-19		Chris Ledger		Bug 17942 - Copied from Stage.uspStandardise_Global_MCQI
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
	;WITH RecordsToUpdate	(ID, Manufacturer, CountryCode, Country, CountryID)

	AS

	(
	--Add In CountryID
	SELECT		GC.ID, GC.Manufacturer, C.ISOAlpha2 AS CountryCode, C.Country, C.CountryID
	FROM		[Stage].[Global_MCQI]		GC
	INNER JOIN	[$(AuditDB)].dbo.Files		F ON GC.AuditID = F.AuditID	
	INNER JOIN	[$(SampleDB)].ContactMechanism.Countries	C  ON 'GB' = C.ISOAlpha2
	)
	--Retrieve Metadata values for each event in the table
	SELECT	DISTINCT	RU.*, MD.ManufacturerPartyID, MD.Questionnaire, MD.EventTypeID, MD.LanguageID, MD.SetNameCapitalisation,
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
		
		WHERE			(M.SampleLoadActive = 1	) AND
						(@SampleFileName LIKE SampleFileNamePrefix + '%')	

	)	MD				ON	RU.Manufacturer = MD.Brand AND
							RU.CountryID	= MD.CountryID
							
							
	--Populate the meta data fields for each record
	UPDATE		GC
	SET			ManufacturerPartyID			= C.ManufacturerPartyID,	 
				SampleSupplierPartyID		= C.ManufacturerPartyID,
				CountryCode					= C.CountryCode,
				CountryID					= C.CountryID,
				EventType					= C.Questionnaire,
				EventTypeID					= C.EventTypeID,
				--LanguageID					= C.LanguageID,
				DealerCodeOriginatorPartyID	= C.DealerCodeOriginatorPartyID,
				SetNameCapitalisation		= C.SetNameCapitalisation,
				SampleTriggeredSelectionReqID = (
													CASE
														WHEN	C.CreateSelection = 1 AND 
																C.SampleTriggeredSelection = 1 THEN 0
														ELSE	0
													END
												)
	
	FROM 		Stage.Global_MCQI		GC
	INNER JOIN	#Completed					C ON GC.ID =C.ID	
	
	
	

	
	---------------------------------------------------------------------------------------------------------
	-- Convert the Purchase Date 
	---------------------------------------------------------------------------------------------------------

	UPDATE	Stage.Global_MCQI
	SET		ConvertedVehiclePurchaseDate = CONVERT( DATETIME, VehiclePurchaseDate, 103)
	WHERE	NULLIF(VehiclePurchaseDate, '') IS NOT NULL
	
	
	
	---------------------------------------------------------------------------------------------------------
	-- Convert the Delivery Date 
	---------------------------------------------------------------------------------------------------------
	UPDATE	Stage.Global_MCQI
	SET		ConvertedVehicleDeliveryDate = CONVERT( DATETIME, VehicleDeliveryDate, 103)
	WHERE	NULLIF(VehicleDeliveryDate, '') IS NOT NULL
	


	---------------------------------------------------------------------------------------------------------
	-- Convert the Registration Date 
	---------------------------------------------------------------------------------------------------------
	UPDATE	Stage.Global_MCQI
	SET		ConvertedVehicleRegistrationDate = CONVERT( DATETIME, VehicleRegistrationDate, 103)
	WHERE	NULLIF(VehicleRegistrationDate, '') IS NOT NULL


	
	---------------------------------------------------------------------------------------------------------
	-- Set any blank Model Years to NULL 
	---------------------------------------------------------------------------------------------------------
	UPDATE	Stage.Global_MCQI
	SET		ModelYear = NULL
	WHERE	LEN(ModelYear) = 0
	


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
	SET	LanguageID = 	CASE 
							--IF PREFERRED LANGUAGE ISN'T PERMITTED, SET LANGUAGE TO A DESIGNATED DEFAULT LANGUAGE
							WHEN [dbo].[udfIsLanguageExcluded](DL.CountryID,GC.PreferredLanguage) = 1 THEN DL.DefaultLanguageID

							--IF THERE IS A PREFERRED LANGUAGE, FIND THE CORRESPONDING LANGUAGEID
							ELSE LA.LanguageID		
									
						END
																	
	FROM		Stage.Global_MCQI						GC
	INNER JOIN	#Completed									CM ON GC.ID = CM.ID
	LEFT JOIN	[$(SampleDB)].dbo.Languages						LA ON GC.PreferredLanguage =	CASE
																								WHEN LEN(LTRIM(RTRIM(GC.PreferredLanguage))) = 2 THEN LA.ISOAlpha2
																								WHEN LEN(LTRIM(RTRIM(GC.PreferredLanguage))) = 3 THEN LA.ISOAlpha3
																								ELSE LA.Language
																							END
	
	LEFT JOIN	[$(SampleDB)].ContactMechanism.Countries	DL ON DL.CountryID = GC.CountryID	

	WHERE		GC.PreferredLanguage <> ''
	
	
	--WE MAY NOT HAVE A DEFAULT LANGUAGE SET UP FOR THE LOADER, USE THE DEFAULT LANGUAGE FOR THE MARKET
	UPDATE	gc
	SET		gc.LanguageID = C.DefaultLanguageID
	FROM	Stage.Global_MCQI gc
	JOIN	[$(SampleDB)].ContactMechanism.Countries C ON C.CountryID = gc.CountryID
	WHERE	GC.LanguageID IS NULL
	-- V1.5 (See Comments above) 
	
	
	 
	---------------------------------------------------------------------------------------------------------
	--Set CustomIdentifierFlag									
	---------------------------------------------------------------------------------------------------------
	DECLARE @FieldName				NVARCHAR(200)=''
	DECLARE @FieldValue				NVARCHAR(200)=''
	
	--Dynamic formatting of special fields
	SET @FieldValue		=''
	
	SELECT			DISTINCT @FieldValue = ColumnFormattingValue
	
	FROM			[$(SampleDB)].dbo.SampleFileSpecialFormatting SF
	INNER JOIN		[$(SampleDB)].dbo.vwBrandMarketQuestionnaireSampleMetadata	SM ON SF.SampleFileID = SM.SampleFileID
	WHERE			(@SampleFileName LIKE SampleFileNamePrefix + '%') AND	
					(ColumnFormattingIdentifier = 'CustomerIdentifierUsable')

	
	--BY DEFAULT CUSTOMERIDENTIFIER MATCHING IS DISABLED
	UPDATE	GC 
	SET		CustomerIdentifierUsable =  CAST(0 AS BIT)
	FROM	Stage.Global_MCQI GC
	INNER JOIN	#Completed C ON GC.ID = C.ID	
	
	IF   CAST(@FieldValue AS BIT) = 'True'	
	BEGIN	
			UPDATE	GC				
			SET		CustomerIdentifier	=	CASE
											 		WHEN LEN(LTRIM(RTRIM(ISNULL(GC.CustomerUniqueID,'')))) > 0 THEN LTRIM(RTRIM(ISNULL(GC.CustomerUniqueID,''))) + '_GSL_' + LTRIM(RTRIM(ISNULL(GC.CountryCode,'')))
											 		ELSE ''
												END, 
							
					CustomerIdentifierUsable =	 CAST(@FieldValue AS BIT)
			FROM	Stage.Global_MCQI	GC		
			INNER JOIN	#Completed			C ON GC.ID = C.ID						
	END	
	ELSE BEGIN 
		UPDATE GC
		SET CustomerIdentifier = ISNULL(GC.CustomerUniqueID,'')
		FROM Stage.Global_MCQI GC		
		INNER JOIN	#Completed C ON GC.ID = C.ID					
	END		
	
	
	---------------------------------------------------------------------------------------------------------
	-- Remove NoEmail@Contact.com email addresses					
	---------------------------------------------------------------------------------------------------------	
	UPDATE gc
	SET EmailAddress1 = NULL
	FROM Stage.Global_MCQI gc
	WHERE gc.EmailAddress1 IN ('noemail@contact.com',
							  'noemail@contract.com',
							  'noemail@jlr.com',
							  'noemail@nocontact.com')

	UPDATE gc
	SET EmailAddress2 = NULL
	FROM Stage.Global_MCQI gc
	WHERE gc.EmailAddress2 IN ('noemail@contact.com',
							  'noemail@contract.com',
							  'noemail@jlr.com',
							  'noemail@nocontact.com')

	

	---------------------------------------------------------------------------------------------------------
	--Validate for all records that require metadata fields to be populated. Raise an error otherwise.
	---------------------------------------------------------------------------------------------------------
	IF EXISTS( 
				SELECT	ID 
				FROM	[Stage].[Global_MCQI] 
				WHERE	(ManufacturerPartyID	IS NULL OR
						SampleSupplierPartyID	IS NULL OR
						CountryID				IS NULL OR 
						EventTypeID				IS NULL OR	
						DealerCodeOriginatorPartyID IS NULL OR
						SetNameCapitalisation  IS NULL OR
						LanguageID				IS NULL OR
						(ModelYear IS NOT NULL AND isnumeric(ModelYear)=0))
			)			 
			
			RAISERROR(	N'Data in Stage.Global_MCQI has missing Meta-Data.', 
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
		INTO [$(ErrorDB)].Stage.Global_MCQI_' + @TimestampString + '
		FROM Stage.Global_MCQI
	')
	
	-- FINALLY RAISE THE ERROR
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH