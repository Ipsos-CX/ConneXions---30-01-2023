CREATE PROCEDURE [Stage].[uspStandardise_China_WithResponses_CRC]
/*
	Purpose:		(I)		Convert supplied dates from a text string to a valid DATETIME type
					(II)	Populate mandatory meta data
	
	Version			Date			Developer			Comment
	1.0				16/03/2018		Eddie Thomas		Created from [Sample_ETL].dbo.uspStandardise_Global_Service 
	1.1				10/01/2020		Chris Ledger		BUG 15372 - Fix Hard coded references to databases
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
	;WITH RecordsToUpdate	(ID, Manufacturer, CountryCode, Country, CountryID)

	AS

	(
	--Add In CountryID
	SELECT		GS.ID, GS.sType, GS.CRCCode, C.Country,C.CountryID
	FROM		[Stage].[China_CRC_WithResponses]		GS
	INNER JOIN	[$(SampleDB)].ContactMechanism.Countries	C  ON GS.CRCCode =	(  
																						Case
																							WHEN LEN(GS.CRCCode) = 2 THEN ISOAlpha2
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
		
		WHERE			(M.Questionnaire	= 'CRC') AND
						(M.SampleLoadActive = 1	) AND
						(@SampleFileName LIKE SampleFileNamePrefix + '%')	

	)	MD				ON	RU.Manufacturer = MD.Brand AND
							RU.CountryID	= MD.CountryID
							
							
	--Populate the meta data fields for each record
	UPDATE	GS
	SET			ManufacturerPartyID				= C.ManufacturerPartyID,	 
					SampleSupplierPartyID			= C.ManufacturerPartyID,
					CountryID								= C.CountryID,
					EventTypeID								= C.EventTypeID,
					DealerCodeOriginatorPartyID	= C.DealerCodeOriginatorPartyID,
					SetNameCapitalisation			= C.SetNameCapitalisation,
					SampleTriggeredSelectionReqID = (
													Case
														WHEN	C.CreateSelection = 1 AND 
																C.SampleTriggeredSelection = 1 THEN C.QuestionnaireRequirementID
														ELSE	0
													END
												)
	
	FROM 		Stage.China_CRC_WithResponses		GS
	INNER JOIN	#Completed					C ON GS.ID =C.ID	
	
	
	

	
	---------------------------------------------------------------------------------------------------------
	-- Convert the CRC Event Date 
	---------------------------------------------------------------------------------------------------------

	UPDATE	Stage.China_CRC_WithResponses
	SET		ConvertedEventDate = CONVERT( DATETIME, EventDate, 102)
	WHERE	NULLIF(EventDate, '') IS NOT NULL
	

	---------------------------------------------------------------------------------------------------------
	-- Update (cleardown) the TelephoneNumbers, if a Dummy one is supplied
	---------------------------------------------------------------------------------------------------------
	  
	DECLARE @FieldNameForDummyTN				NVARCHAR(200)=''
	DECLARE @FieldValueForDummyTN   			NVARCHAR(200)=''
		
	SELECT DISTINCT	@FieldNameForDummyTN	= ColumnFormattingIdentifier,
					@FieldValueForDummyTN = ColumnFormattingValue
		FROM			[$(SampleDB)].dbo.SampleFileSpecialFormatting			SF
		INNER JOIN		[$(SampleDB)].dbo.vwBrandMarketQuestionnaireSampleMetadata	SM 
							ON SF.SampleFileID = SM.SampleFileID
	  
	  WHERE			(@SampleFileName LIKE SampleFileNamePrefix + '%')	
		and ColumnFormattingIdentifier = 'clearDummyTelephoneNumber'
		
		IF @FieldNameForDummyTN = 'clearDummyTelephoneNumber'		
		BEGIN	
			
			UPDATE GS
			SET
				 GS.Tel_1 =		Lookup.udfClearDummyTelephoneNumbers(GS.Tel_1,@FieldValueForDummyTN)
				,GS.Tel_2 =	Lookup.udfClearDummyTelephoneNumbers(GS.Tel_2,@FieldValueForDummyTN)
				--,GS.MobileTelephoneNumber =		Lookup.udfClearDummyTelephoneNumbers(GS.MobileTelephoneNumber,@FieldValueForDummyTN)
			FROM stage.China_CRC_WithResponses GS
		
				
		END	

	
	
	--WE MAY NOT HAVE A DEFAULT LANGUAGE SET UP FOR THE LOADER, USE THE DEFAULT LANGUAGE FOR THE MARKET
	UPDATE	gs
	SET		LanguageID = C.DefaultLanguageID
	FROM	stage.China_CRC_WithResponses gs
	JOIN	[$(SampleDB)].ContactMechanism.Countries C ON C.CountryID = gs.CountryID
	WHERE	GS.LanguageID IS NULL
	
	 
	-- Failing that default to English
	UPDATE	stage.China_CRC_WithResponses
	SET		LanguageID = (SELECT LanguageID FROM [$(SampleDB)].dbo.Languages WHERE Language = 'English')
	WHERE	LanguageID IS NULL	


	UPDATE  s
    SET     s.[Add8] =	CASE c.ISOAlpha3
										WHEN 'LUX' THEN 'BEL'
                                        ELSE c.ISOAlpha3
                                    END
    FROM    Stage.China_CRC_WithResponses s
    INNER JOIN [$(SampleDB)].ContactMechanism.Countries c ON c.ISOAlpha2 =	CASE
																			WHEN s.[Add8] = 'Japan'	-- V1.3 Japan sent instead of ISOalpha2
																				THEN s.CCode
																			WHEN s.[Add8] IS NULL
																				OR s.[Add8] = ''
																				THEN s.CCode
																			ELSE s.[Add8]
																		END


	---------------------------------------------------------------------------------------------------------
	-- Remove NoEmail@Contact.com email addresses					-- v1.4	
	---------------------------------------------------------------------------------------------------------
	
	UPDATE gs
	SET		EmailAddress = NULL
	from	Stage.China_CRC_WithResponses gs
	WHERE	gs.EmailAddress IN ('noemail@contact.com',
							  'noemail@contract.com',
							  'noemail@jlr.com',
							  'noemail@nocontact.com')

	
	---------------------------------------------------------------------------------------------------------
	--Validate for all records that require metadata fields to be populated. Raise an error otherwise.
	---------------------------------------------------------------------------------------------------------
	IF Exists( 
				SELECT	ID 
				FROM	[Stage].[China_CRC_WithResponses] 
				WHERE	(ManufacturerPartyID		IS NULL OR
						SampleSupplierPartyID	IS NULL OR
						CountryID				IS NULL OR 
						EventTypeID				IS NULL OR	
						DealerCodeOriginatorPartyID IS NULL OR
						SetNameCapitalisation  IS NULL OR
						LanguageID				IS NULL)
			)			 
			
			RAISERROR(	N'Data in Stage.China_CRC_WithResponses has missing Meta-Data.', 
						16,
						1
					 )
					 
	---------------------------------------------------------------------------------------------------------
	--Verify that dupes don't exist in current sample and that we haven't received the same responses before
	---------------------------------------------------------------------------------------------------------
		
	IF Exists( 		
				SELECT		COUNT(Respondent_Serial), Respondent_Serial
				FROM		[Stage].[China_CRC_WithResponses] 
				GROUP BY	Respondent_Serial
				HAVING		COUNT(Respondent_Serial) > 1		 
			 )		 
				
			RAISERROR(	N'Duplicate ResponseID(s) in Stage.China_CRC_WithResponses.', 
						16,
						1
					 )
				
	IF Exists(			
				SELECT		gsc.Respondent_Serial
				FROM		[Stage].[China_CRC_WithResponses] gsc
				INNER JOIN	[China].[CRC_WithResponses] cr ON gsc.Respondent_Serial = cr.Respondent_Serial
			 )
				
			RAISERROR(	N'Non-unique ResponseID(s) in Stage.China_CRC_WithResponses; Possible repeat of previous loaded cases.', 
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
		INTO [$(ErrorDB)].Stage.China_CRC_WithResponses_' + @TimestampString + '
		FROM Stage.China_CRC_WithResponses
	')
	
	-- FINALLY RAISE THE ERROR
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH