CREATE PROCEDURE [Stage].[uspStandardise_Global_Bodyshop]
/*
	Purpose:		(I)		Convert the supplied dates from a text string to a valid DATETIME type
					(II)	Populate mandatory meta data
	
	Version			Date			Developer			Comment
	1.0				16/08/2017		Eddie Thomas		Created from [Sample_ETL].dbo.uspStandardise_Global_PreOwned
	1.1			    16/04/2019		Ben King			BUG 15311 - Prevent partial loaded batch of files (uat)

*/
@SampleFileName NVARCHAR (100)
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
	;WITH RecordsToUpdate	(ID, Manufacturer, CountryCode, EventType, Country, CountryID)

	AS

	(
	--Add In CountryID
	SELECT		GS.ID, GS.Manufacturer, GS.CountryCode, GS.EventType, C.Country,C.CountryID
	FROM		[Stage].[Global_Bodyshop]		GS
	INNER JOIN	[$(SampleDB)].ContactMechanism.Countries	C  ON GS.CountryCode =	(  
																						Case
																							WHEN LEN(GS.CountryCode) = 2 THEN ISOAlpha2
																							ELSE ISOAlpha3
																						End
																					)	
	)
	--Retrieve Metadata values for each event in the table
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
		
		WHERE			(M.Questionnaire	= 'Bodyshop') AND
						(M.SampleLoadActive = 1	) AND
						(@SampleFileName LIKE SampleFileNamePrefix + '%')	

	)	MD				ON	RU.Manufacturer = MD.Brand AND
							RU.CountryID	= MD.CountryID
							
							
	--Populate the meta data fields for each record
	UPDATE		GS
	SET			ManufacturerPartyID			= C.ManufacturerPartyID,	 
				SampleSupplierPartyID		= C.ManufacturerPartyID,
				CountryID					= C.CountryID,
				EventTypeID					= C.EventTypeID,
				--LanguageID					= C.LanguageID,
				DealerCodeOriginatorPartyID	= C.DealerCodeOriginatorPartyID,
				SetNameCapitalisation		= C.SetNameCapitalisation,
				SampleTriggeredSelectionReqID = (
													Case
														WHEN	C.CreateSelection = 1 AND 
																C.SampleTriggeredSelection = 1 THEN C.QuestionnaireRequirementID
														ELSE	0
													END
												)
	
	FROM 		Stage.Global_Bodyshop		GS
	INNER JOIN	#Completed					C ON GS.ID =C.ID	
	
	
	

	
	---------------------------------------------------------------------------------------------------------
	-- Convert the Purchase Date 
	---------------------------------------------------------------------------------------------------------

	UPDATE	Stage.Global_Bodyshop
	SET		ConvertedVehiclePurchaseDate = CONVERT( DATETIME, VehiclePurchaseDate, 103)
	WHERE	NULLIF(VehiclePurchaseDate, '') IS NOT NULL
	
	
	
	---------------------------------------------------------------------------------------------------------
	-- Convert the Delivery Date 
	---------------------------------------------------------------------------------------------------------

	UPDATE	Stage.Global_Bodyshop
	SET		ConvertedVehicleDeliveryDate = CONVERT( DATETIME, VehicleDeliveryDate, 103)
	WHERE	NULLIF(VehicleDeliveryDate, '') IS NOT NULL
	


	---------------------------------------------------------------------------------------------------------
	-- Convert the Registration Date 
	---------------------------------------------------------------------------------------------------------

	UPDATE	Stage.Global_Bodyshop
	SET		ConvertedVehicleRegistrationDate = CONVERT( DATETIME, VehicleRegistrationDate, 103)
	WHERE	NULLIF(VehicleRegistrationDate, '') IS NOT NULL

	

	---------------------------------------------------------------------------------------------------------
	-- Convert the Bodyshop Event Date
	---------------------------------------------------------------------------------------------------------

	UPDATE	Stage.Global_Bodyshop
	SET		ConvertedBodyshopEventDate = CONVERT( DATETIME, BodyshopEventDate, 103)
	WHERE	NULLIF(BodyshopEventDate, '') IS NOT NULL
	

	---------------------------------------------------------------------------------------------------------
	-- Update (cleardown) the TelephoneNumbers, if a Dummy one is supplied (1.6)
	---------------------------------------------------------------------------------------------------------
	  
	DECLARE @FieldNameForDummyTN				NVARCHAR(200)=''
	DECLARE @FieldValueForDummyTN   			NVARCHAR(200)=''
		
	SELECT DISTINCT	@FieldNameForDummyTN	= ColumnFormattingIdentifier,
					@FieldValueForDummyTN = ColumnFormattingValue
		FROM			[$(SampleDB)].[dbo].SampleFileSpecialFormatting			SF
		INNER JOIN		[$(SampleDB)].[dbo].vwBrandMarketQuestionnaireSampleMetadata	SM 
							ON SF.SampleFileID = SM.SampleFileID
	  
	  WHERE			(@SampleFileName LIKE SampleFileNamePrefix + '%')	
		and ColumnFormattingIdentifier = 'clearDummyTelephoneNumber'
		
		IF @FieldNameForDummyTN = 'clearDummyTelephoneNumber'		
		BEGIN	
			
			UPDATE GS
			SET
				 GS.HomeTelephoneNumber =		Lookup.udfClearDummyTelephoneNumbers(GS.HomeTelephoneNumber,@FieldValueForDummyTN)
				,GS.BusinessTelephoneNumber =	Lookup.udfClearDummyTelephoneNumbers(GS.BusinessTelephoneNumber,@FieldValueForDummyTN)
				,GS.MobileTelephoneNumber =		Lookup.udfClearDummyTelephoneNumbers(GS.MobileTelephoneNumber,@FieldValueForDummyTN)
			FROM stage.Global_Bodyshop GS
		
				
		END	
	
	
	---------------------------------------------------------------------------------------------------------
	-- Set any blank Model Years to NULL 
	---------------------------------------------------------------------------------------------------------

	UPDATE	Stage.Global_Bodyshop
	SET		ModelYear = NULL
	WHERE	LEN(RTRIM(ModelYear)) = 0
	
	
	--V1.1 Check Model Year is numeric. If not, when appended to VWT, data flow will fail.
	IF EXISTS( 
				
			SELECT ModelYear 
			FROM   Stage.Global_Bodyshop
			WHERE (ISNUMERIC(ModelYear) <> 1
			AND ModelYear <> '')
			OR CONVERT(BIGINT, ModelYear) > 9999
				
			 )			 
	BEGIN 
			--MOove misaligned model year records to holding table then remove from staging.
			INSERT INTO	Stage.Removed_Records_Staging_Tables (AuditID, FileName, ActionDate, PhysicalFileRow, VIN, Misaligned_ModelYear)
			SELECT	GB.AuditID, F.FileName, F.ActionDate, GB.PhysicalRowID, GB.VIN, GB.ModelYear
			FROM	Stage.Global_Bodyshop GB
			INNER JOIN [$(AuditDB)].DBO.Files F ON GB.AuditID = F.AuditID
			WHERE (ISNUMERIC(GB.ModelYear) <> 1
			AND GB.ModelYear <> '')
			OR CONVERT(BIGINT, GB.ModelYear) > 9999
			
			DELETE 
			FROM   Stage.Global_Bodyshop
			WHERE (ISNUMERIC(ModelYear) <> 1
			AND ModelYear <> '')
			OR CONVERT(BIGINT, ModelYear) > 9999

	END 
	


	---------------------------------------------------------------------------------------------------------
	-- Update the preferred LanguageID, if a Preferred language supplied
	---------------------------------------------------------------------------------------------------------
	
	--V1.5 (See Comments above)
	UPDATE GS
	SET	LanguageId = 	CASE 
							--IF PREFERRED LANGUAGE ISN'T PERMITTED, SET LANGUAGE TO A DESIGNATED DEFAULT LANGUAGE
							WHEN [dbo].[udfIsLanguageExcluded](DL.CountryID,GS.PreferredLanguage) = 1 THEN DL.DefaultLanguageID

							--IF THERE IS A PREFERRED LANGUAGE, FIND THE CORRESPONDING LANGUAGEID
							ELSE LA.LanguageID		
									
						END
																	
	FROM		stage.Global_Bodyshop					GS
	INNER JOIN	#Completed									CM ON GS.ID = CM.ID
	LEFT JOIN	[$(SampleDB)].DBO.Languages						LA ON GS.PreferredLanguage =	CASE
																								WHEN LEN(LTRIM(RTRIM(GS.PreferredLanguage))) = 2 THEN LA.ISOAlpha2
																								WHEN LEN(LTRIM(RTRIM(GS.PreferredLanguage))) = 3 THEN LA.ISOAlpha3
																								ELSE LA.Language
																							END
	
	LEFT JOIN	[$(SampleDB)].ContactMechanism.Countries	DL ON DL.CountryID = GS.CountryID	-- V1.10

	WHERE		GS.PreferredLanguage <> ''
	
	
	--WE MAY NOT HAVE A DEFAULT LANGUAGE SET UP FOR THE LOADER, USE THE DEFAULT LANGUAGE FOR THE MARKET
	UPDATE gs
	SET gs.LanguageID = C.DefaultLanguageID
	FROM stage.Global_Bodyshop gs
	JOIN [$(SampleDB)].ContactMechanism.Countries C ON C.CountryID = gs.CountryID
	WHERE GS.LanguageID IS NULL
	-- V1.5 (See Comments above) 
	 
	---------------------------------------------------------------------------------------------------------
	--Set CustomIdentifierFlag									--V1.3 
	---------------------------------------------------------------------------------------------------------
	DECLARE @FieldName				NVARCHAR(200)=''
	DECLARE @FieldValue				NVARCHAR(200)=''
	
	--Dynamic formatting of special fields
	SET @FieldValue		=''
	
	SELECT			DISTINCT @FieldValue = ColumnFormattingValue
	
	FROM			[$(SampleDB)].dbo.SampleFileSpecialFormatting			SF
	INNER JOIN		[$(SampleDB)].dbo.vwBrandMarketQuestionnaireSampleMetadata	SM ON SF.SampleFileID = SM.SampleFileID
	WHERE			(@SampleFileName LIKE SampleFileNamePrefix + '%') AND	
					(ColumnFormattingIdentifier = 'CustomerIdentifierUsable')

	
	--BY DEFAULT CUSTOMERIDENTIFIER MATCHING IS DISABLED
	UPDATE	GS 
	SET		CustomerIdentifierUsable =  CAST(0 AS BIT)
	FROM	stage.Global_Bodyshop GS
	INNER JOIN	#Completed			C ON GS.ID = C.ID	
	
	IF   CAST(@FieldValue AS BIT) = 'True'	
	BEGIN	
			UPDATE	GS
					
			SET		CustomerIdentifier	=	CASE
											 		WHEN LEN(LTRIM(RTRIM(ISNULL(GS.CustomerUniqueID,'')))) > 0 THEN LTRIM(RTRIM(ISNULL(GS.CustomerUniqueID,''))) + '_GSL_' + LTRIM(RTRIM(ISNULL(GS.CountryCode,'')))
											 		ELSE ''
												END, 
							
					CustomerIdentifierUsable =	 CAST(@FieldValue AS BIT)
			FROM	stage.Global_Bodyshop	GS		
			INNER JOIN	#Completed			C ON GS.ID = C.ID						
	END	
	ELSE BEGIN 
		UPDATE GS
			SET CustomerIdentifier = ISNULL(GS.CustomerUniqueID,'')
			FROM	stage.Global_Bodyshop	GS		
			INNER JOIN	#Completed			C ON GS.ID = C.ID					
	END		
	
	
	---------------------------------------------------------------------------------------------------------
	-- Remove NoEmail@Contact.com email addresses					-- v1.4	
	---------------------------------------------------------------------------------------------------------
	
	UPDATE gs
	SET EmailAddress1 = NULL
	from Stage.Global_Bodyshop gs
	WHERE gs.EmailAddress1 IN ('noemail@contact.com',
							  'noemail@contract.com',
							  'noemail@jlr.com',
							  'noemail@nocontact.com')

	UPDATE gs
	SET EmailAddress2 = NULL
	from Stage.Global_Bodyshop gs
	WHERE gs.EmailAddress2 IN ('noemail@contact.com',
							  'noemail@contract.com',
							  'noemail@jlr.com',
							  'noemail@nocontact.com')
	
	---------------------------------------------------------------------------------------------------------
	-- Set Salutation field 
	---------------------------------------------------------------------------------------------------------
	--SET @FieldName				=''
	SET  @FieldValue				=''
	
	IF EXISTS(
	
				SELECT			DISTINCT ColumnFormattingValue
				
				FROM			[$(SampleDB)].dbo.SampleFileSpecialFormatting			SF
				INNER JOIN		[$(SampleDB)].dbo.vwBrandMarketQuestionnaireSampleMetadata	SM ON SF.SampleFileID = SM.SampleFileID
				WHERE			(@SampleFileName LIKE SampleFileNamePrefix + '%') AND	
								(ColumnFormattingIdentifier = 'Salutation')
			)
	BEGIN
	
			SELECT			DISTINCT @FieldValue = ColumnFormattingValue
				
			FROM			[$(SampleDB)].dbo.SampleFileSpecialFormatting			SF
			INNER JOIN		[$(SampleDB)].dbo.vwBrandMarketQuestionnaireSampleMetadata	SM ON SF.SampleFileID = SM.SampleFileID
			WHERE			(@SampleFileName LIKE SampleFileNamePrefix + '%') AND	
							(ColumnFormattingIdentifier = 'Salutation')

			-- V 1.7 WHERE clause added to only update rows from current file
			UPDATE			Stage.Global_Bodyshop 
			SET				Salutation = @FieldValue
			FROM			Stage.Global_Bodyshop S 
			INNER JOIN		[$(AuditDB)].dbo.Files F ON S.AuditID = F.AuditID
			WHERE			F.[FileName] = @SampleFileName
	END 
	---------------------------------------------------------------------------------------------------------
	--Validate for all records that require metadata fields to be populated. Raise an error otherwise.
	---------------------------------------------------------------------------------------------------------
	IF Exists( 
				SELECT	ID 
				FROM	[Stage].[Global_Bodyshop] 
				WHERE	(ManufacturerPartyID		IS NULL OR
						SampleSupplierPartyID	IS NULL OR
						CountryID				IS NULL OR 
						EventTypeID				IS NULL OR	
						DealerCodeOriginatorPartyID IS NULL OR
						SetNameCapitalisation  IS NULL OR
						LanguageID				IS NULL)
			)			 
			
			RAISERROR(	N'Data in Stage.Global_Bodyshop has missing Meta-Data.', 
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
		INTO [Sample_Errors].Stage.Global_Bodyshop_' + @TimestampString + '
		FROM Stage.Global_Bodyshop
	')
	
	-- FINALLY RAISE THE ERROR
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH