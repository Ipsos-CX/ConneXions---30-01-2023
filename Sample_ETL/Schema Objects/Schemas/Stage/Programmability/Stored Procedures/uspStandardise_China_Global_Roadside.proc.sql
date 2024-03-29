﻿CREATE PROCEDURE [Stage].[uspStandardise_China_Global_Roadside]
@SampleFileName NVARCHAR (100)
AS

/*
	Purpose:	Standardise China_Global_Roadside
	
	Version			Date			Developer			Comment
	1.1				10-01-2020		Chris Ledger		BUG 15372: Fix Hard coded references to databases												
*/

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
	FROM		[Stage].[Global_China_Roadside_WithResponses]		GS
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
		
		WHERE			(M.Questionnaire	= 'Roadside') AND
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
				DealerCodeOriginatorPartyID	= C.DealerCodeOriginatorPartyID,
				SetNameCapitalisation		= C.SetNameCapitalisation,
				SampleTriggeredSelectionReqID = (
													Case
														WHEN	C.CreateSelection = 1 AND 
																C.SampleTriggeredSelection = 1 THEN C.QuestionnaireRequirementID
														ELSE	0
													END
												)
	
	FROM 		Stage.Global_China_Roadside_WithResponses		GS
	INNER JOIN	#Completed					C ON GS.ID =C.ID	
	
	
	

	
	---------------------------------------------------------------------------------------------------------
	-- Convert the Purchase Date 
	---------------------------------------------------------------------------------------------------------

	UPDATE	Stage.Global_China_Roadside_WithResponses
	SET		ConvertedVehiclePurchaseDate = CONVERT( DATETIME, VehiclePurchaseDate, 103)
	WHERE	NULLIF(VehiclePurchaseDate, '') IS NOT NULL
	
	
	---------------------------------------------------------------------------------------------------------
	-- Convert the Service Date 
	---------------------------------------------------------------------------------------------------------

	UPDATE	Stage.Global_China_Roadside_WithResponses
	SET		ConvertedServiceEventDate = CONVERT( DATETIME, ServiceEventDate, 103)
	WHERE	NULLIF(ServiceEventDate, '') IS NOT NULL
	
	
	---------------------------------------------------------------------------------------------------------
	-- Convert the Registration Date 
	---------------------------------------------------------------------------------------------------------

	UPDATE	Stage.Global_China_Roadside_WithResponses
	SET		ConvertedVehicleRegistrationDate = CONVERT( DATETIME, VehicleRegistrationDate, 103)
	WHERE	NULLIF(VehicleRegistrationDate, '') IS NOT NULL

	
	---------------------------------------------------------------------------------------------------------
	-- Convert the Delivery Date 
	---------------------------------------------------------------------------------------------------------

	UPDATE	Stage.Global_China_Roadside_WithResponses
	SET		ConvertedVehicleDeliveryDate = CONVERT( DATETIME, VehicleDeliveryDate, 103)
	WHERE	NULLIF(VehicleDeliveryDate, '') IS NOT NULL
	

	---------------------------------------------------------------------------------------------------------
	-- Convert the VehiclePurchaseDate  -- this is Sales Event Date
	---------------------------------------------------------------------------------------------------------

	UPDATE	Stage.Global_China_Roadside_WithResponses
	SET		ConvertedVehiclePurchaseDate = CONVERT( DATETIME, VehiclePurchaseDate, 103)
	WHERE	NULLIF(VehiclePurchaseDate, '') IS NOT NULL

	---------------------------------------------------------------------------------------------------------
	-- Convert the BreakdownDate  -- this is the Roadside Event Date
	---------------------------------------------------------------------------------------------------------

	UPDATE	Stage.Global_China_Roadside_WithResponses
	SET		ConvertedBreakdownDate = CONVERT ( DATETIME, BreakdownDate, 103 )
	WHERE	NULLIF(BreakdownDate, '') IS NOT NULL
	
	---------------------------------------------------------------------------------------------------------
	-- Convert the CarHireStartDate  -- This is the Roadside Event Date if BreakdownDate is blank
	---------------------------------------------------------------------------------------------------------
	
	UPDATE	Stage.Global_China_Roadside_WithResponses
	SET		ConvertedCarHireStartDate = CONVERT ( DATETIME, CarHireStartDate, 103 )
	WHERE	NULLIF(CarHireStartDate, '') IS NOT NULL

	---------------------------------------------------------------------------------------------------------
	-- Convert the CarHireStartDate  -- This is the Roadside Event Date if BreakdownDate is blank
	---------------------------------------------------------------------------------------------------------
	UPDATE	Stage.Global_China_Roadside_WithResponses
	SET		ConvertedCarHireStartTime = CONVERT(TIME, carhirestarttime)
	where	NULLIF(CarHireStartTime, '') IS NOT NULL
	

	---------------------------------------------------------------------------------------------------------
	-- Update (cleardown) the TelephoneNumbers, if a Dummy one is supplied
	---------------------------------------------------------------------------------------------------------
	  
	DECLARE @FieldNameForDummyTN				NVARCHAR(200)=''
	DECLARE @FieldValueForDummyTN   			NVARCHAR(200)=''
		
	SELECT DISTINCT	@FieldNameForDummyTN	= ColumnFormattingIdentifier,
					@FieldValueForDummyTN	= ColumnFormattingValue
	FROM			[$(SampleDB)].dbo.SampleFileSpecialFormatting			SF
	INNER JOIN		[$(SampleDB)].dbo.vwBrandMarketQuestionnaireSampleMetadata	SM ON SF.SampleFileID = SM.SampleFileID
	  
	
	WHERE			(@SampleFileName LIKE SampleFileNamePrefix + '%')	AND 
					ColumnFormattingIdentifier = 'clearDummyTelephoneNumber'
		
	IF @FieldNameForDummyTN = 'clearDummyTelephoneNumber'		
	BEGIN	
		
		UPDATE GS
		SET
				GS.HomeTelephoneNumber		=	Lookup.udfClearDummyTelephoneNumbers(GS.HomeTelephoneNumber,@FieldValueForDummyTN)
				,GS.BusinessTelephoneNumber =	Lookup.udfClearDummyTelephoneNumbers(GS.BusinessTelephoneNumber,@FieldValueForDummyTN)
				,GS.MobileTelephoneNumber	=	Lookup.udfClearDummyTelephoneNumbers(GS.MobileTelephoneNumber,@FieldValueForDummyTN)
		FROM	Stage.Global_China_Roadside_WithResponses GS
	
			
	END	

	
	
	---------------------------------------------------------------------------------------------------------
	-- Set any blank Model Years to NULL 
	---------------------------------------------------------------------------------------------------------

	UPDATE	Stage.Global_China_Roadside_WithResponses
	SET		ModelYear = NULL
	WHERE	LEN(LTRIM(RTRIM(ModelYear))) = 0
	


	---------------------------------------------------------------------------------------------------------
	-- Update the preferred LanguageID, if a Preferred language supplied
	---------------------------------------------------------------------------------------------------------
	
	--V1.5 (See Comments above)
	--UPDATE GS
	--SET	LanguageId = 	CASE 
	--						--IF PREFERRED LANGUAGE ISN'T PERMITTED, SET LANGUAGE TO A DESIGNATED DEFAULT LANGUAGE
	--						WHEN [dbo].[udfIsLanguageExcluded](DL.CountryID,GS.PreferredLanguage) = 1 THEN DL.DefaultLanguageID

	--						--IF THERE IS A PREFERRED LANGUAGE, FIND THE CORRESPONDING LANGUAGEID
	--						ELSE LA.LanguageID		
									
	--					END
																	
	--FROM		stage.Global_China_Roadside_WithResponses						GS
	--INNER JOIN	#Completed									CM ON GS.ID = CM.ID
	--LEFT JOIN	[$(SampleDB)].DBO.Languages						LA ON GS.PreferredLanguage =	CASE
	--																							WHEN LEN(LTRIM(RTRIM(GS.PreferredLanguage))) = 2 THEN LA.ISOAlpha2
	--																							WHEN LEN(LTRIM(RTRIM(GS.PreferredLanguage))) = 3 THEN LA.ISOAlpha3
	--																							ELSE LA.Language
	--																						END
	
	--LEFT JOIN	[$(SampleDB)].ContactMechanism.Countries	DL ON DL.CountryID = GS.CountryID	-- V1.9

	--WHERE		GS.PreferredLanguage <> ''
	

	
	
	--WE MAY NOT HAVE A DEFAULT LANGUAGE SET UP FOR THE LOADER, USE THE DEFAULT LANGUAGE FOR THE MARKET
	UPDATE	gs
	SET		LanguageID = C.DefaultLanguageID
	FROM	stage.Global_China_Roadside_WithResponses gs
	JOIN	[$(SampleDB)].ContactMechanism.Countries C ON C.CountryID = gs.CountryID
	WHERE	GS.LanguageID IS NULL
	-- V1.5 (See Comments above) 
	 

	---- Then, if not found, set using default language for country  
	--UPDATE s
	--SET s.PreferredLanguageID = c.DefaultLanguageID 
	--FROM stage.Combined_Roadside_Service s
	--INNER JOIN [$(SampleDB)].ContactMechanism.Countries c on c.ISOAlpha2 = COALESCE(NULLIF(s.CountryCodeISOAlpha2, ''), NULLIF(s.BreakdownCountryISOAlpha2, ''))    -- Use the original country code (or breakdown country) supplied to determine preferred language
	--WHERE s.PreferredLanguageID IS NULL
	
	-- Failing that default to English
	UPDATE	stage.Global_China_Roadside_WithResponses
	SET		LanguageID = (SELECT LanguageID FROM [$(SampleDB)].dbo.Languages WHERE Language = 'English')
	WHERE	LanguageID IS NULL	


	UPDATE		s
	SET			s.BreakdownCountry = CASE c.ISOAlpha3 WHEN 'LUX' THEN 'BEL' ELSE c.ISOAlpha3 END
	FROM		Stage.Global_China_Roadside_WithResponses s
	INNER JOIN	[$(SampleDB)].ContactMechanism.Countries c on c.ISOAlpha2 = s.[Address8]

	--v1.2
	UPDATE  s
    SET     s.[Address8] =	CASE c.ISOAlpha3
										WHEN 'LUX' THEN 'BEL'
                                        ELSE c.ISOAlpha3
                                    END
    FROM    Stage.Global_China_Roadside_WithResponses s
    INNER JOIN [$(SampleDB)].ContactMechanism.Countries c ON c.ISOAlpha2 =	CASE
																			WHEN s.[Address8] = 'Japan'	-- V1.3 Japan sent instead of ISOalpha2
																				THEN s.CountryCode
																			WHEN s.[Address8] IS NULL
																				OR s.[Address8] = ''
																				THEN s.CountryCode
																			ELSE s.[Address8]
																		END

	


	-----------------------------------------------------------------------------------------------------------
	----Set CustomIdentifierFlag									--V1.3 
	-----------------------------------------------------------------------------------------------------------
	--DECLARE @FieldName				NVARCHAR(200)=''
	--DECLARE @FieldValue				NVARCHAR(200)=''
	
	----Dynamic formatting of special fields
	--SET @FieldValue		=''
	
	--SELECT			DISTINCT @FieldValue = ColumnFormattingValue
	
	--FROM			[$(SampleDB)].dbo.SampleFileSpecialFormatting			SF
	--INNER JOIN		[$(SampleDB)].dbo.vwBrandMarketQuestionnaireSampleMetadata	SM ON SF.SampleFileID = SM.SampleFileID
	--WHERE			(@SampleFileName LIKE SampleFileNamePrefix + '%') AND	
	--				(ColumnFormattingIdentifier = 'CustomerIdentifierUsable')

	
	----BY DEFAULT CUSTOMERIDENTIFIER MATCHING IS DISABLED
	--UPDATE	GS 
	--SET		CustomerIdentifierUsable =  CAST(0 AS BIT)
	--FROM	stage.Global_China_Roadside_WithResponses GS
	--INNER JOIN	#Completed			C ON GS.ID = C.ID	
	
	--IF   CAST(@FieldValue AS BIT) = 'True'	
	--BEGIN	
	--		UPDATE	GS
					
	--		SET		CustomerIdentifier	=	CASE
	--										 		WHEN LEN(LTRIM(RTRIM(ISNULL(GS.CustomerUniqueID,'')))) > 0 THEN LTRIM(RTRIM(ISNULL(GS.CustomerUniqueID,''))) + '_GSL_' + LTRIM(RTRIM(ISNULL(GS.CountryCode,'')))
	--										 		ELSE ''
	--											END, 
							
	--				CustomerIdentifierUsable =	 CAST(@FieldValue AS BIT)
	--		FROM	stage.Global_China_Roadside_WithResponses	GS		
	--		INNER JOIN	#Completed			C ON GS.ID = C.ID						
	--END	
	--ELSE BEGIN 
	--	UPDATE GS
	--		SET CustomerIdentifier = ISNULL(GS.CustomerUniqueID,'')
	--		FROM	stage.Global_China_Roadside_WithResponses	GS		
	--		INNER JOIN	#Completed			C ON GS.ID = C.ID					
	--END		
	

	---------------------------------------------------------------------------------------------------------
	-- Update SurnameField1 or CompanyName to CustomerIdentifier					-- v1.10	
	---------------------------------------------------------------------------------------------------------
	UPDATE GS
	SET GS.SurnameField1 = CASE WHEN GS.PrivateOwner = 'C' THEN '' ELSE GS.CustomerUniqueID END,
	GS.CompanyName = CASE WHEN GS.PrivateOwner = 'C' THEN GS.CustomerUniqueID ELSE '' END
	FROM Stage.Global_China_Roadside_WithResponses GS
	---------------------------------------------------------------------------------------------------------

	
	---------------------------------------------------------------------------------------------------------
	-- Remove NoEmail@Contact.com email addresses					-- v1.4	
	---------------------------------------------------------------------------------------------------------
	
	UPDATE gs
	SET		EmailAddress1 = NULL
	from	Stage.Global_China_Roadside_WithResponses gs
	WHERE	gs.EmailAddress1 IN ('noemail@contact.com',
							  'noemail@contract.com',
							  'noemail@jlr.com',
							  'noemail@nocontact.com')

	UPDATE	gs
	SET		EmailAddress2 = NULL
	from	Stage.Global_China_Roadside_WithResponses gs
	WHERE	gs.EmailAddress2 IN ('noemail@contact.com',
							  'noemail@contract.com',
							  'noemail@jlr.com',
							  'noemail@nocontact.com')
	
	---------------------------------------------------------------------------------------------------------
	--Validate for all records that require metadata fields to be populated. Raise an error otherwise.
	---------------------------------------------------------------------------------------------------------
	IF Exists( 
				SELECT	ID 
				FROM	[Stage].[Global_China_Roadside_WithResponses] 
				WHERE	(ManufacturerPartyID		IS NULL OR
						SampleSupplierPartyID	IS NULL OR
						CountryID				IS NULL OR 
						EventTypeID				IS NULL OR	
						DealerCodeOriginatorPartyID IS NULL OR
						SetNameCapitalisation  IS NULL OR
						LanguageID				IS NULL)
			)			 
			
			RAISERROR(	N'Data in Stage.Global_China_Roadside_WithResponses has missing Meta-Data.', 
						16,
						1
					 )
					 
	---------------------------------------------------------------------------------------------------------
	--Verify that dupes don't exist in current sample and that we haven't received the same responses before
	---------------------------------------------------------------------------------------------------------
		
	IF Exists( 		
				SELECT		COUNT(ResponseID), ResponseID
				FROM		[Stage].[Global_China_Roadside_WithResponses] 
				GROUP BY	ResponseID
				HAVING		COUNT(ResponseID) > 1		 
			 )		 
				
			RAISERROR(	N'Duplicate ResponseID(s) in Stage.Global_China_Roadside_WithResponses.', 
						16,
						1
					 )
				
	IF Exists(			
				SELECT		gsc.ResponseID
				FROM		[Stage].[Global_China_Roadside_WithResponses] gsc
				INNER JOIN	[China].[Roadside_WithResponses] cr ON gsc.ResponseID = cr.ResponseID
			 )
				
			RAISERROR(	N'Non-unique ResponseID(s) in Stage.Global_China_Roadside_WithResponses; Possible repeat of previous loaded cases.', 
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
		INTO [$(ErrorDB)].Stage.Global_China_Roadside_WithResponses_' + @TimestampString + '
		FROM Stage.Global_China_Roadside_WithResponses
	')
	
	-- FINALLY RAISE THE ERROR
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH
