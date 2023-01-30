CREATE PROCEDURE [Stage].[uspStandardise_Canada_Service]
/*
	Purpose:		(I)		Convert the supplied dates from a text string to a valid DATETIME type
					(II)	Populate load variables
	
	Version			Date			Developer			Comment
	1.0				19/01/2017		Chris Ross			Created from [Stage].[uspStandardise_Global_Service]
	1.1				15/02/2017		Chris Ross			13598 -	Add an extra layer of extaction to Technician Name so as not to load any pipes and subsequent chars in field.
	1.2				27/02/2017		Chris Ross			BUG 13510: Changes to remove Contract Type filter, add more Sale Type filters, and filter out non-"pilot dealer" sample 
																   Plus add in extra reporting columns.
	1.3				15/03/2017		Chris Ross			BUG 13690: Updated to split out some filtering so invalid country/manufacturer recs are removed but the remainder are kept 
																   just not loaded to the VWT.  Also added in transaction handling to make sure either all updates or non are done.
																   Ensure all updates now use the Canada.Service table instead of Staging.Canada_Sevice.
	1.4				03/04/2017		Chris Ross			BUG 13791: Remove Pilot Dealer filtering
														BUG 13795: Update the preferred LanguageID, if a Preferred language supplied
	1.5				06/09/2017		Chris Ross			BUG 14122: Set the PDI_Flag from the Operations column													
	1.6				10/01/2020		Chris Ledger		BUG 15372: Fix Hard coded references to databases	
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
	-- Remove all records which are not Canada and where they are dupes (i.e. Dealer Code not 
	-- found for manufacturer).  Save the rowIds and reaons to the FileRowsRemovedBeforeLoad table
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
				s.RO_CLOSE_DATE		AS EventDate	,
				s.DEALER_ID			AS DealerCode	,
				s.VEH_MAKE			AS Manufacturer	,
				s.VEH_VIN			AS VIN,
				
				'Sample_ETL.Stage.uspStandardise_Canada_Service' AS RemovingProcess,
				 (
					( CASE WHEN CUST_COUNTRY NOT IN ('CA')				THEN 'Customer Country not Canada; '	ELSE '' END )  +
					( CASE WHEN d.OutletCode IS NULL					THEN 'Dealer Code not found for Manufacturer; '	ELSE '' END ) 
											
				) AS RemovalReasons,
			   
				 (  
					( CASE WHEN CUST_COUNTRY NOT IN ('CA')				THEN (CUST_COUNTRY + '; ')	ELSE '' END ) +
					( CASE WHEN d.OutletCode IS NULL					THEN (s.DEALER_ID + ' ' + s.VEH_MAKE + '; ')	ELSE '' END ) 
				 ) AS FailedValues		
		FROM Canada.Service s
		LEFT JOIN [$(SampleDB)].[dbo].[DW_JLRCSPDealers] d				-- Check Dealer Code exists for Manufacturer.  (I.e. addresses dupes by manufacturer issue)
											ON (d.OutletCode_GDD = s.DEALER_ID 
													OR d.OutletCode = s.DEALER_ID) 
											AND s.VEH_MAKE = d.Manufacturer
											AND d.Market = 'Canada'
											AND d.OutletFunction = 'Aftersales'
		WHERE s.DateTransferredToVWT IS NULL 
		AND (   CUST_COUNTRY NOT IN ('CA')	
			 OR d.OutletCode IS NULL							--v1.2
			)
		
		-- Now remove the records
		DELETE s
		FROM Canada.Service s
		INNER JOIN [$(AuditDB)].dbo.FileRowsRemovedBeforeLoad r ON r.AuditID = s.AuditID AND r.PhysicalRow = s.PhysicalRowID



	---------------------------------------------------------------------------------------------------------
	-- Populate the TECHNICIAN and OPERATION_PAY_TYPE fields from the OPERATIONS column
	---------------------------------------------------------------------------------------------------------

	UPDATE  Canada.Service 
	SET 
			TECHNICIAN_CONTACT_ID = dbo.udfRetrieveColumnFromDelimitedText(dbo.udfRetrieveColumnFromDelimitedText(operations, 18, '~'), 2, '^')  ,
			TECHNICIAN_FULL_NAME = dbo.udfRetrieveColumnFromDelimitedText(dbo.udfRetrieveColumnFromDelimitedText(dbo.udfRetrieveColumnFromDelimitedText(operations, 1, '|'), 18, '~'), 8, '^'),
			OPERATION_PAY_TYPE = dbo.udfRetrieveColumnFromDelimitedText(operations, 5, '~')   -- v1.3
	FROM Canada.Service
	WHERE DateTransferredToVWT IS NULL 
	AND ISNULL(FilteredFlag , 'N') <> 'Y'
	

	---------------------------------------------------------------------------------------------------------
	-- Populate the PDI_Flag column from the OPERATIONS column
	---------------------------------------------------------------------------------------------------------

	UPDATE  Canada.Service 
	SET PDI_Flag = 'Y'
	FROM Canada.Service
	WHERE DateTransferredToVWT IS NULL 
	AND ISNULL(FilteredFlag , 'N') <> 'Y'
	and (	operations like '%PDI%' 
		 OR operations like '%Pre-Delivery Inspect%'
		 OR operations like '%Predelivery inspect%'
		 OR operations like '%Pre delivery inspect%'
		 OR operations like '%Prep for deliv%'
		 OR operations like '%Clean for deliv%'
		 OR operations like '%Prepare for deliv%'
		)



	-------------------------------------------------------------------------------------------------------------
	-- Now flag all the records which are going to be filtered out and not loaded into the VWT e.g. where they
	-- do not have the correct OPERATION_PAY_TYPE.  These are still kept on file for reference.
	-------------------------------------------------------------------------------------------------------------




		-- Save the removal reasons first
		INSERT INTO [Canada].[Service_FilteredRecords] (
														[AuditID]				,
														[PhysicalRowID]			,
														[FilterReasons]		,
														[FilterFailedValues]
									
													)
		SELECT	DISTINCT AuditID, 
				PhysicalRowID,
				
				 (
					( CASE WHEN s.OPERATION_PAY_TYPE IN ('I')			THEN 'OPERATION_PAY_TYPE = I; '	ELSE '' END )  
											
				) AS RemovalReasons,
			   
				 (  
					( CASE WHEN s.OPERATION_PAY_TYPE IN ('I')			THEN 'I; '	ELSE '' END )  
					
				 ) AS FailedValues		
		FROM Canada.Service s
		WHERE DateTransferredToVWT IS NULL  
		AND ISNULL(FilteredFlag , 'N') <> 'Y'
		AND (s.OPERATION_PAY_TYPE IN ('I') -- v1.3 -- OPERATION_PAY_TYPE
		    )
		

		-- Now flag the records as being filtered so that they are not transferred to the VWT
		UPDATE s
		SET FilteredFlag = 'Y'
		FROM Canada.Service s
		INNER JOIN [Canada].[Service_FilteredRecords] r ON r.AuditID = s.AuditID AND r.PhysicalRowID = s.PhysicalRowID
		WHERE s.DateTransferredToVWT IS NULL 
		AND ISNULL(FilteredFlag , 'N') <> 'Y'
	
		 


	----------------------------------------------------------------------------------------------------
	-- Set the BMQ specific load variables 
	----------------------------------------------------------------------------------------------------
	;WITH RecordsToUpdate	(ID, Manufacturer, CountryCode, EventType, Country, CountryID)
	AS

	(
	--Add In CountryID
	SELECT		GS.ID, GS.VEH_MAKE, GS.CUST_COUNTRY, 'Service' AS EventType, C.Country,C.CountryID
	FROM		Canada.Service		GS
	INNER JOIN	[$(SampleDB)].ContactMechanism.Countries	C  ON GS.CUST_COUNTRY =	(  
																						Case
																							WHEN LEN(GS.CUST_COUNTRY) = 2 THEN ISOAlpha2
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
		
		WHERE			(M.Questionnaire	= 'Service') AND
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
	
	FROM 		Canada.Service		GS
	INNER JOIN	#Completed					C ON GS.ID =C.ID	
	WHERE GS.DateTransferredToVWT IS NULL 
	AND ISNULL(FilteredFlag , 'N') <> 'Y'
	
	
	
	---------------------------------------------------------------------------------------------------------
	-- Convert the Service Date 
	---------------------------------------------------------------------------------------------------------

	UPDATE	Canada.Service
	SET		Converted_RO_CLOSE_DATE = CONVERT( DATETIME, RO_CLOSE_DATE, 101)
	WHERE	NULLIF(RO_CLOSE_DATE, '') IS NOT NULL
	AND DateTransferredToVWT IS NULL 
	AND ISNULL(FilteredFlag , 'N') <> 'Y'
	

	---------------------------------------------------------------------------------------------------------
	-- Convert the Birth Date 
	---------------------------------------------------------------------------------------------------------

	UPDATE	Canada.Service
	SET		Converted_CUST_BIRTH_DATE = CONVERT( DATETIME, CUST_BIRTH_DATE, 101)
	WHERE	NULLIF(CUST_BIRTH_DATE, '') IS NOT NULL
	AND DateTransferredToVWT IS NULL 
	AND ISNULL(FilteredFlag , 'N') <> 'Y'
	


	---------------------------------------------------------------------------------------------------------
	-- Update the preferred LanguageID, if a Preferred language supplied			-- v1.4
	---------------------------------------------------------------------------------------------------------


	--- do any language code conversions before doing our language checks
	UPDATE CS
	SET CS.Language = CASE CS.Language	WHEN 'FR' THEN 'FC'
										WHEN 'ZH' THEN 'ZC'
										ELSE 'AE' END
	FROM Canada.Service	CS
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
																	
	FROM		Canada.Service								CS
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
	FROM Canada.Service gs
	JOIN [$(SampleDB)].ContactMechanism.Countries C ON C.CountryID = gs.CountryID
	WHERE GS.LanguageID IS NULL
	AND gs.DateTransferredToVWT IS NULL 
	AND ISNULL(FilteredFlag , 'N') <> 'Y'
	
	 
	 
	---------------------------------------------------------------------------------------------------------
	-- Set CustomIdentifierFlag 
	---------------------------------------------------------------------------------------------------------
	
	UPDATE	GS 
	SET		CustomerIdentifierUsable =  CAST(0 AS BIT)
	FROM	Canada.Service	GS
	WHERE	DateTransferredToVWT IS NULL 
	AND ISNULL(FilteredFlag , 'N') <> 'Y'
	
	
	---------------------------------------------------------------------------------------------------------
	-- Set any blank Model Years to NULL 
	---------------------------------------------------------------------------------------------------------

	UPDATE	Canada.Service
	SET		VEH_MODEL_YEAR = NULL
	WHERE	LEN(VEH_MODEL_YEAR) = 0
	AND		DateTransferredToVWT IS NULL 
	AND ISNULL(FilteredFlag , 'N') <> 'Y'
	
	
	---------------------------------------------------------------------------------------------------------
	--Validate for all records that require metadata fields to be populated. Raise an error otherwise.
	---------------------------------------------------------------------------------------------------------
	IF Exists( 
				SELECT	ID 
				FROM	Canada.Service 
				WHERE	DateTransferredToVWT IS NULL 
				  AND	ISNULL(FilteredFlag , 'N') <> 'Y'
				  AND	(ManufacturerPartyID		IS NULL OR
						 SampleSupplierPartyID	IS NULL OR
						 CountryID				IS NULL OR 
						 EventTypeID				IS NULL OR	
						 DealerCodeOriginatorPartyID IS NULL OR
						 SetNameCapitalisation  IS NULL OR
						 LanguageID				IS NULL OR
						 (VEH_MODEL_YEAR is not null AND isnumeric(VEH_MODEL_YEAR)=0)
						)
			)			 
			
			RAISERROR(	N'Data in Canada.Service has missing Meta-Data.', 
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
		INTO [$(ErrorDB)].Canada.Service_' + @TimestampString + '
		FROM Canada.Service
		WHERE DateTransferredToVWT IS NULL 
		AND ISNULL(FilteredFlag , ''N'') <> ''Y''
	
	')
	
	-- FINALLY RAISE THE ERROR
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH