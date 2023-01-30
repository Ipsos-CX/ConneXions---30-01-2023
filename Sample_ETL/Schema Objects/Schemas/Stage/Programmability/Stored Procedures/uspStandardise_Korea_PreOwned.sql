CREATE PROCEDURE [Stage].[uspStandardise_Korea_PreOwned]
/*
	Purpose:		(I)		Convert the supplied dates from a text string to a valid DATETIME type
					(II)	Populate mandatory meta data
	
	Version			Date			Developer			Comment
	1.0				08/03/2021		Eddie Thomas		Created from [Sample_ETL].Stage.uspStandardise_Global_PreOwned_Sales

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
	SELECT		ID,	CASE
							WHEN ManufacturerCode ='JG' THEN 'Jaguar'
							WHEN ManufacturerCode ='LR' THEN 'Land Rover'
						END AS Manufacturer, 
				'KOR', 'Korea', 
				(SELECT CountryID FROM [$(SampleDB)].ContactMechanism.Countries WHERE CountryShortName = 'Korea')
	FROM		[Stage].[Korea_PreOwned]
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
		
		WHERE			(M.Questionnaire	= 'PreOwned') AND
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
	
	FROM 		Stage.Korea_PreOwned		GS
	INNER JOIN	#Completed					C ON GS.ID =C.ID	
	



	---------------------------------------------------------------------------------------------------------
	-- Convert the Used Car Sales Event Date
	---------------------------------------------------------------------------------------------------------

	UPDATE	Stage.Korea_PreOwned
	SET		ConvertedSalesEventDate = CAST(SalesEventDate AS DATETIME2)
	WHERE	NULLIF(SalesEventDate, '') IS NOT NULL AND
			ISDATE(SalesEventDate) = 1
	

	
	---------------------------------------------------------------------------------------------------------
	-- Update the preferred LanguageID, if a Preferred language supplied
	---------------------------------------------------------------------------------------------------------
	
	--WE MAY NOT HAVE A DEFAULT LANGUAGE SET UP FOR THE LOADER, USE THE DEFAULT LANGUAGE FOR THE MARKET
	UPDATE	Stage.Korea_PreOwned
	SET		LanguageID = (SELECT DefaultLanguageID FROM [$(SampleDB)].ContactMechanism.Countries WHERE CountryShortName = 'Korea')

			
	
	
	---------------------------------------------------------------------------------------------------------
	-- Remove NoEmail@Contact.com email addresses					-- v1.4	
	---------------------------------------------------------------------------------------------------------
	
	UPDATE	Stage.Korea_PreOwned 
	SET		EmailAddress = NULL
	WHERE	EmailAddress IN ('noemail@contact.com',
							  'noemail@contract.com',
							  'noemail@jlr.com',
							  'noemail@nocontact.com')


	
	
	---------------------------------------------------------------------------------------------------------
	--Validate for all records that require metadata fields to be populated. Raise an error otherwise.
	---------------------------------------------------------------------------------------------------------
	IF Exists( 
				SELECT	ID 
				FROM	[Stage].[Korea_PreOwned] 
				WHERE	(ManufacturerPartyID		IS NULL OR
						SampleSupplierPartyID	IS NULL OR
						CountryID				IS NULL OR 
						EventTypeID				IS NULL OR	
						DealerCodeOriginatorPartyID IS NULL OR
						SetNameCapitalisation  IS NULL OR
						LanguageID				IS NULL)
			)			 
			
			RAISERROR(	N'Data in Stage.Korea_PreOwned has missing Meta-Data.', 
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
		INTO [Sample_Errors].Stage.Korea_PreOwned_' + @TimestampString + '
		FROM Stage.Korea_PreOwned
	')
	
	-- FINALLY RAISE THE ERROR
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH
GO


