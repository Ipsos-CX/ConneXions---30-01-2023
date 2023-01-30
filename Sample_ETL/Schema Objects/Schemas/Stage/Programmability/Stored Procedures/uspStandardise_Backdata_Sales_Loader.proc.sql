CREATE PROCEDURE [Stage].[uspStandardise_Backdata_Sales_Loader]
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
	;WITH RecordsToUpdate	(ID, Manufacturer, Country, CountryID) 
		--CountryCode, EventType, 

	AS

	(
	--Add In CountryID
	SELECT		GS.ID, GS.[Brand_Name], C.Country, C.CountryID

	FROM		[Stage].[Backdata_Sales_Loader]		GS
	INNER JOIN	[$(SampleDB)].ContactMechanism.Countries	C  ON GS.[Vista_Market_Desc] = C.Country	
	)
	--Retrieve Metadata values for each event in the table
	SELECT	DISTINCT	RU.*, MD.ManufacturerPartyID, MD.EventTypeID, MD.LanguageID, MD.SetNameCapitalisation,
						MD.DealerCodeOriginatorPartyID 

	INTO	#Completed							
	FROM	RecordsToUpdate RU
	INNER JOIN 
	(
		SELECT DISTINCT M.ManufacturerPartyID, M.CountryID, ET.EventTypeID,  
						C.DefaultLanguageID AS LanguageID, M.SetNameCapitalisation, M.DealerCodeOriginatorPartyID,
						M.Brand, M.Questionnaire
						
		FROM			[$(SampleDB)].dbo.vwBrandMarketQuestionnaireSampleMetadata	M
		INNER JOIN		[$(SampleDB)].Event.EventTypes								ET ON ET.EventType = M.Questionnaire
		INNER JOIN		[$(SampleDB)].ContactMechanism.Countries						C ON C.CountryID = M.CountryID
		
		WHERE			(M.Questionnaire	= 'Sales') AND
						(M.SampleLoadActive = 1	) AND
						(M.SampleFileNamePrefix <>'0')	

	)	MD				ON	RU.Manufacturer = MD.Brand AND
							RU.CountryID	= MD.CountryID
							
							
	--Populate the meta data fields for each record
	UPDATE		GS
	SET			ManufacturerPartyID			= C.ManufacturerPartyID,	 
				SampleSupplierPartyID		= C.ManufacturerPartyID,
				CountryID					= C.CountryID,
				EventTypeID					= C.EventTypeID,
				LanguageID					= C.LanguageID,
				DealerCodeOriginatorPartyID	= C.DealerCodeOriginatorPartyID
	
	FROM 		[Stage].[Backdata_Sales_Loader]		GS
	INNER JOIN	#Completed					C ON GS.ID =C.ID	
	
	
	

	
	---------------------------------------------------------------------------------------------------------
	-- Convert the Customer Handover Date
	---------------------------------------------------------------------------------------------------------

	UPDATE	[Stage].[Backdata_Sales_Loader]
	SET		[ConvertedCustomerHandoverDate] = CONVERT( DATETIME, [Customer_Handover_Date], 103)
	WHERE	NULLIF([Customer_Handover_Date], '') IS NOT NULL
	
	
	
	---------------------------------------------------------------------------------------------------------
	-- Convert the Converted Order Created Date
	---------------------------------------------------------------------------------------------------------

	UPDATE	[Stage].[Backdata_Sales_Loader]
	SET		[ConvertedOrderCreatedDate] = CONVERT( DATETIME, [Order_Created_Date], 103)
	WHERE	NULLIF([Order_Created_Date], '') IS NOT NULL
	

	---------------------------------------------------------------------------------------------------------
	--Validate for all records that require metadata fields to be populated. Raise an error otherwise.
	---------------------------------------------------------------------------------------------------------
	IF Exists( 
				SELECT	ID 
				FROM	[Stage].[Backdata_Sales_Loader] 
				WHERE	(ManufacturerPartyID		IS NULL OR
						SampleSupplierPartyID	IS NULL OR
						CountryID				IS NULL OR 
						EventTypeID				IS NULL OR	
						DealerCodeOriginatorPartyID IS NULL OR
						LanguageID				IS NULL)
			)			 
			
			RAISERROR(	N'Data in Stage.Backdata_Sales_Loader is missing Meta-Data.', 
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
		INTO [$(ErrorDB)].Stage.Backdata_Sales_Loader_' + @TimestampString + '
		FROM Stage.Backdata_Sales_Loader
	')
	
	-- FINALLY RAISE THE ERROR
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH
