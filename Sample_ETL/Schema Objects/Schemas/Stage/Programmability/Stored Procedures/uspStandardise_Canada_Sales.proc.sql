CREATE PROCEDURE [Stage].[uspStandardise_Canada_Sales]
/*
	Purpose:		(I)		Convert the supplied dates from a text string to a valid DATETIME type
					(II)	Populate load variables
	
	Version			Date			Developer			Comment
	1.0				26/01/2017		Chris Ross			Created from [Stage].[uspStandardise_Canada_Service]
	1.1				16/02/2017		Chris Ledger		BUG 13599: Exclude Non Canadian Records
	1.2				27/02/2017		Chris Ross			BUG 13510: Changes to remove Contract Type filter, add more Sale Type filters, and filter out non-"pilot dealer" sample 
																   Plus add in extra reporting columns.	
	1.3				15/03/2017		Chris Ross			BUG 13690: Updated to split out some filtering so invalid country/manufacturer recs are removed but the remainder are kept 
																   just not loaded to the VWT.  Also added in transaction handling to make sure either all updates or non are done.
																   Ensure all updates now use the Canada.Sales table instead of Staging.Canada_Sales.
	1.4				31/03/2017		Chris Ross			BUG 13792: Remove filtering of <blank> Sales Types.
	1.5				03/04/2017		Chris Ross			BUG 13791: Remove Pilot Dealer filtering
														BUG 13795: Update the preferred LanguageID, if a Preferred language supplied
	1.6				06-04-2017		Chris Ross			BUG 13831: Convert ContractDate and populate new column Converted_ContractDate
	1.7				10-01-2020		Chris Ledger		BUG 15372: Fix Hard coded references to databases
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


		-------------------------------------------------------------------------------------------------------------
		-- Remove all records which are not Jaguar/Land Rover, not Canada, and where they are dupes (i.e. Dealer Code not 
		-- found for manufacturer).  Save the rowIds and reasons to the FileRowsRemovedBeforeLoad table
		-------------------------------------------------------------------------------------------------------------

		-- Save the removal reasons first
		INSERT INTO [$(AuditDB)].dbo.FileRowsRemovedBeforeLoad (
														[AuditID]				,
														[PhysicalRow]			,
														[EventDate]				,
														[DealerCode]			,
														[Manufacturer]			,
														[VIN]					,
														[RemovingProcess]		,
														[RemovalReasons]		,
														[FailedValues]
									
													)
		SELECT	DISTINCT AuditID, 
				PhysicalRowID,
				s.PurchaseOrderDate	AS EventDate	,
				s.DealerID			AS DealerCode	,
				s.Make				AS Manufacturer	,
				s.VIN								,
				
				'Sample_ETL.Stage.uspStandardise_Canada_Sales' AS RemovingProcess,
				 (
					( CASE WHEN BuyerHomeAddressCountry NOT IN ('CA')		THEN 'Buyer Home Address Country not Canada; '	ELSE '' END ) +	-- V1.1
					( CASE WHEN Make NOT IN ('Jaguar', 'Land rover')		THEN 'Make not Jaguar or Land Rover; '			ELSE '' END ) +
					( CASE WHEN d.OutletCode IS NULL						THEN 'Dealer Code not found for Manufacturer; '	ELSE '' END )

				) AS RemovalReasons,
			   
				 (  
					( CASE WHEN BuyerHomeAddressCountry NOT IN ('CA')		THEN (BuyerHomeAddressCountry + '; ')	ELSE '' END ) + -- V1.1
					( CASE WHEN Make NOT IN ('Jaguar', 'Land rover')		THEN (Make + '; ')			ELSE '' END ) +
					( CASE WHEN d.OutletCode IS NULL						THEN (s.DealerID + ' ' + s.Make + '; ')	ELSE '' END )
											
				 ) AS FailedValues		
		FROM Canada.Sales s
		LEFT JOIN [$(SampleDB)].[dbo].[DW_JLRCSPDealers] d				-- Check Dealer Code exists for Manufacturer.  (I.e. addresses dupes by manufacturer issue)
											ON (d.OutletCode_GDD = s.DealerID 
													OR d.OutletCode = s.DealerID) 
											AND s.Make = d.Manufacturer
											AND d.Market = 'Canada'
											AND d.OutletFunction = 'Sales'
		WHERE s.DateTransferredToVWT IS NULL 
		AND (      BuyerHomeAddressCountry NOT IN ('CA')	-- V1.1
				OR Make NOT IN ('Jaguar', 'Land rover')
				OR d.OutletCode IS NULL							--v1.2
			)

		-- Now remove the records
		DELETE s
		FROM Canada.Sales s
		INNER JOIN [$(AuditDB)].dbo.FileRowsRemovedBeforeLoad r ON r.AuditID = s.AuditID AND r.PhysicalRow = s.PhysicalRowID

		 
	
	
	---------------------------------------------------------------------------------------------------------
	-- Populate the ContactID and FullName fields from the SalesPeople column
	---------------------------------------------------------------------------------------------------------

	UPDATE  Canada.Sales 
	SET 
			SalesPeople_ContactID = dbo.udfRetrieveColumnFromDelimitedText(dbo.udfRetrieveColumnFromDelimitedText(SalesPeople, 1, '|'), 1, '~') ,
			SalesPeople_FullName = dbo.udfRetrieveColumnFromDelimitedText(dbo.udfRetrieveColumnFromDelimitedText(SalesPeople, 1, '|'), 7, '~')
	FROM Canada.Sales 
	WHERE DateTransferredToVWT IS NULL 
	AND ISNULL(FilteredFlag , 'N') <> 'Y'
	
	
	
	-------------------------------------------------------------------------------------------------------------
	-- Now flag all the records which are going to be filtered out and not loaded into the VWT e.g. where they
	-- do not have the correct SALE TYPE or CONTRACT TYPE.  These are still kept on file for reference.
	-------------------------------------------------------------------------------------------------------------

		-- Save the removal reasons first
		INSERT INTO [Canada].[Sales_FilteredRecords] (
														[AuditID]				,
														[PhysicalRowID]			,
														[FilterReasons]		,
														[FilterFailedValues]
									
													)
		SELECT	DISTINCT AuditID, 
				PhysicalRowID,
				
				 (
				--v1.2 -- ( CASE WHEN ContractType NOT IN ('Purchase', 'Lease')	THEN 'Contract Type not Purchase or Lease; '	ELSE '' END ) +  
					( CASE WHEN SaleType  IN (	 'Wholesale',				--v1.2
												 'Whole Sale',				--v1.2
												 'House',					--v1.2
												 'Fleet',					--v1.2
												 'Dealertrade',				--v1.2
												 'Dealer Trade'				--v1.2
												 )							THEN 'Sale Type IN (WholeSale,Whole Sale,House,Fleet,Dealertrade,Dealer Trade); '	 ELSE '' END ) +
					( CASE WHEN ISNUMERIC(SaleType) = 1						THEN 'Sale Type numeric; '						ELSE '' END ) +    -- v1.2
					( CASE WHEN InventoryType NOT IN ('New')				THEN 'InventoryType not New; '					ELSE '' END )											

				) AS RemovalReasons,
			   
				 (  
					--  v1.2 --( CASE WHEN ContractType NOT IN ('Purchase', 'Lease')	THEN (ContractType + '; ')	ELSE '' END ) +
					( CASE WHEN SaleType IN (	 'Wholesale',				--v1.2
												 'Whole Sale',				--v1.2
												 'House',					--v1.2
												 'Fleet',					--v1.2
												 'Dealertrade',				--v1.2
												 'Dealer Trade'				--v1.2
												 )							THEN (SaleType + '; ')		ELSE '' END ) +
					( CASE WHEN ISNUMERIC(SaleType) = 1						THEN (SaleType + '; ')		ELSE '' END ) +    -- v1.2											 
					( CASE WHEN InventoryType NOT IN ('New')				THEN (InventoryType + '; ')	ELSE '' END )  
											
				 ) AS FailedValues		
		FROM Canada.Sales s
		WHERE s.DateTransferredToVWT IS NULL 
		AND ISNULL(FilteredFlag , 'N') <> 'Y'
		AND (	SaleType IN (	 'WholeSale',				--v1.2
								 'Whole Sale',				--v1.2
								 'House',					--v1.2
								 'Fleet',					--v1.2
								 'Dealertrade',				--v1.2
								 'Dealer Trade'				--v1.2
								 )	
				OR ISNUMERIC(SaleType) = 1						--v1.2
				OR InventoryType NOT IN ('New')
			)

		-- Now flag the records as being filtered so that they are not transferred to the VWT
		UPDATE s
		SET FilteredFlag = 'Y'
		FROM Canada.Sales s
		INNER JOIN [Canada].[Sales_FilteredRecords] r ON r.AuditID = s.AuditID AND r.PhysicalRowID = s.PhysicalRowID
		WHERE s.DateTransferredToVWT IS NULL 
		AND ISNULL(FilteredFlag , 'N') <> 'Y'
		


		 
		 
	----------------------------------------------------------------------------------------------------
	-- Set the BMQ specific load variables 
	----------------------------------------------------------------------------------------------------
	;WITH RecordsToUpdate	(ID, Manufacturer, CountryCode, EventType, Country, CountryID)
	AS

	(
	--Add In CountryID
	SELECT		GS.ID, GS.Make, GS.BuyerHomeAddressCountry, 'Sales' AS EventType, C.Country,C.CountryID
	FROM		Canada.Sales		GS
	INNER JOIN	[$(SampleDB)].ContactMechanism.Countries	C  ON GS.BuyerHomeAddressCountry =	(  
																						Case
																							WHEN LEN(GS.BuyerHomeAddressCountry) = 2 THEN ISOAlpha2
																							ELSE ISOAlpha3
																						End
																					)	
	WHERE GS.DateTransferredToVWT IS NULL 
	AND ISNULL(FilteredFlag , 'N') <> 'Y'
		
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
		
		WHERE			(M.Questionnaire	= 'Sales') AND
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
	
	FROM 		Canada.Sales		GS
	INNER JOIN	#Completed					C ON GS.ID =C.ID	
	WHERE GS.DateTransferredToVWT IS NULL 
	AND ISNULL(FilteredFlag , 'N') <> 'Y'
		
	
	
	---------------------------------------------------------------------------------------------------------
	-- Convert the Purchase Order Date 
	---------------------------------------------------------------------------------------------------------

	UPDATE	Canada.Sales
	SET		Converted_PurchaseOrderDate = CONVERT( DATETIME, PurchaseOrderDate, 101)
	WHERE	NULLIF(PurchaseOrderDate, '') IS NOT NULL
	AND		DateTransferredToVWT IS NULL 
	AND		ISNULL(FilteredFlag , 'N') <> 'Y'
		

	---------------------------------------------------------------------------------------------------------
	-- Convert the Contract Date															-- v1.6
	---------------------------------------------------------------------------------------------------------

	UPDATE	Canada.Sales
	SET		Converted_ContractDate = CONVERT( DATETIME, ContractDate, 101)
	WHERE	NULLIF(ContractDate, '') IS NOT NULL
	AND		DateTransferredToVWT IS NULL 
	AND		ISNULL(FilteredFlag , 'N') <> 'Y'
		

	---------------------------------------------------------------------------------------------------------
	-- Convert the Birth Date 
	---------------------------------------------------------------------------------------------------------

	UPDATE	Canada.Sales
	SET		Converted_BuyerBirthDate = CONVERT( DATETIME, BuyerBirthDate, 101)
	WHERE	NULLIF(BuyerBirthDate, '') IS NOT NULL
	AND		DateTransferredToVWT IS NULL 
	AND ISNULL(FilteredFlag , 'N') <> 'Y'
		

	---------------------------------------------------------------------------------------------------------
	-- Populate the Company Name from the FullName column
	---------------------------------------------------------------------------------------------------------

	UPDATE  Canada.Sales 
	SET Extracted_CompanyName = CASE WHEN COALESCE(NULLIF(BuyerFirstName, ''), NULLIF(BuyerMiddleName, ''), NULLIF(BuyerLastName, '')) IS NULL 
											AND NULLIF(BuyerFullName, '') IS NOT NULL
									THEN BuyerFullName ELSE '' END
	FROM Canada.Sales 
	WHERE DateTransferredToVWT IS NULL 
	AND ISNULL(FilteredFlag , 'N') <> 'Y'
		
	

	---------------------------------------------------------------------------------------------------------
	-- Update the preferred LanguageID, if a Preferred language supplied						-- v1.5
	---------------------------------------------------------------------------------------------------------
	
	
	--- do any language code conversions before doing our language checks
	UPDATE CS
	SET CS.Language = CASE CS.Language	WHEN 'FR' THEN 'FC'
										WHEN 'ZH' THEN 'ZC'
										ELSE 'AE' END
	FROM Canada.Sales	CS
	WHERE	CS.Language IN ('EN', 'FR', 'ZH')
	AND		CS.DateTransferredToVWT IS NULL 
	AND		ISNULL(FilteredFlag , 'N') <> 'Y'


	-- preferred language checks
	UPDATE CS
	SET	LanguageId = 	CASE 
							--IF PREFERRED LANGUAGE ISN'T PERMITTED, SET LANGUAGE TO A DESIGNATED DEFAULT LANGUAGE
							WHEN [dbo].[udfIsLanguageExcluded](DL.CountryID,CS.Language) = 1 THEN DL.DefaultLanguageID

							--IF THERE IS A PREFERRED LANGUAGE, FIND THE CORRESPONDING LANGUAGEID
							ELSE LA.LanguageID		
									
						END
																	
	FROM		Canada.Sales							CS
	INNER JOIN	#Completed									CM ON CS.ID = CM.ID
	LEFT JOIN	[$(SampleDB)].DBO.Languages						LA ON CS.Language =	CASE
																						WHEN LEN(LTRIM(RTRIM(CS.Language))) = 2 THEN LA.ISOAlpha2
																						WHEN LEN(LTRIM(RTRIM(CS.Language))) = 3 THEN LA.ISOAlpha3
																						ELSE LA.Language
																					END
	
	LEFT JOIN	[$(SampleDB)].ContactMechanism.Countries	DL ON DL.CountryID = CS.CountryID	-- V1.10

	WHERE	CS.Language <> ''
	AND		CS.DateTransferredToVWT IS NULL 
	AND		ISNULL(FilteredFlag , 'N') <> 'Y'
	


	--WE MAY NOT HAVE A DEFAULT LANGUAGE SET UP FOR THE LOADER, USE THE DEFAULT LANGUAGE FOR THE MARKET
	UPDATE gs
	SET gs.LanguageID = C.DefaultLanguageID
	FROM Canada.Sales gs
	JOIN [$(SampleDB)].ContactMechanism.Countries C ON C.CountryID = gs.CountryID
	WHERE GS.LanguageID IS NULL
	AND gs.DateTransferredToVWT IS NULL 
	AND ISNULL(FilteredFlag , 'N') <> 'Y'
			
	 
	 
	---------------------------------------------------------------------------------------------------------
	-- Set CustomIdentifierFlag 
	---------------------------------------------------------------------------------------------------------
	
	UPDATE	GS 
	SET		CustomerIdentifierUsable =  CAST(0 AS BIT)
	FROM	Canada.Sales	GS
	WHERE	GS.DateTransferredToVWT IS NULL 
	AND		ISNULL(FilteredFlag , 'N') <> 'Y'
		
	
	---------------------------------------------------------------------------------------------------------
	-- Set any blank Model Years to NULL 
	---------------------------------------------------------------------------------------------------------

	UPDATE	Canada.Sales
	SET		ModelYear = NULL
	WHERE	LEN(ModelYear) = 0
	AND		DateTransferredToVWT IS NULL 
	AND		ISNULL(FilteredFlag , 'N') <> 'Y'
	
	
	---------------------------------------------------------------------------------------------------------
	--Validate for all records that require metadata fields to be populated. Raise an error otherwise.
	---------------------------------------------------------------------------------------------------------
	IF Exists( 
				SELECT	ID 
				FROM	Canada.Sales 
				WHERE	DateTransferredToVWT IS NULL 
				  AND	ISNULL(FilteredFlag , 'N') <> 'Y'
				  AND	(ManufacturerPartyID		IS NULL OR
						 SampleSupplierPartyID	IS NULL OR
						 CountryID				IS NULL OR 
						 EventTypeID				IS NULL OR	
						 DealerCodeOriginatorPartyID IS NULL OR
						 SetNameCapitalisation  IS NULL OR
						 LanguageID				IS NULL )
			)			 
			
			RAISERROR(	N'Data in Canada.Sales has missing Meta-Data.', 
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
		INTO [$(ErrorDB)].Canada.Sales_' + @TimestampString + '
		FROM Canada.Sales
		WHERE DateTransferredToVWT IS NULL 
		AND ISNULL(FilteredFlag , ''N'') <> ''Y''
	')
	
	-- FINALLY RAISE THE ERROR
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH