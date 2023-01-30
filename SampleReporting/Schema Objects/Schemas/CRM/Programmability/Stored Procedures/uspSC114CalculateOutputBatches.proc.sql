CREATE PROCEDURE CRM.uspSC114CalculateOutputBatches 
	@BatchSize	INT
AS 
SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)


BEGIN TRY


/*
		Purpose:	Calculates batches of CaseIDs for SC114 output to CRM
		
		Version		Date				Developer			Comment
LIVE	1.0			2021-12-08			Chris Ledger		Created from uspCalculateOutputBatches
LIVE	1.1			2022-05-23		Chris Ledger		Task 530 - Exclude Comments temporarily
LIVE	1.2			2022-05-23		Chris Ledger		Task 530 - Map LEAD_ORIGIN Third Party to 3rd Party
LIVE	1.3			2022-05-24		Chris Ledger		Task 530 - reinstate Comments and remove invalid XML characters
*/

	----------------------------------------------------
	-- Set single date for all updates
	----------------------------------------------------
	DECLARE @SysDate DATETIME
	SET @SysDate = GETDATE()



	----------------------------------------------------
	-- Clear down the output batch table
	----------------------------------------------------
	TRUNCATE TABLE CRM.OutputBatches



	----------------------------------------------------
	-- Create temp table for pre-pass
	----------------------------------------------------
    DROP TABLE IF EXISTS #CasesWithNSCRef

	CREATE TABLE #CasesWithNSCRef
	(
		CaseID		INT,
		EventID		BIGINT,
		NSCRef		NVARCHAR(255),
		CountryID	INT
	)


	----------------------------------------------------
	-- Populate the pre-pass table
	----------------------------------------------------
	INSERT INTO #CasesWithNSCRef (CaseID, EventID)
	SELECT LLRS.CaseID,
		LLRS.EventID
	FROM CRM.LostLeadResponseStatuses LLRS
	WHERE LLRS.OutputToCRMDate IS NULL
		AND LLRS.CaseID <> 0 
		AND LLRS.EventID <> 0
		AND NOT EXISTS (	SELECT RHB.CaseID, 
								RHB.EventID 
							FROM CRM.ResponsesHeldBackDueToSizeLimits RHB 
							WHERE RHB.CaseID = LLRS.CaseID
								AND RHB.EventID = LLRS.EventID )
	GROUP BY LLRS.CaseID,
		LLRS.EventID

	
	UPDATE C 
	SET C.NSCRef = M.NSCRef,
		C.CountryID = SL.CountryID
	FROM #CasesWithNSCRef C
		INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL ON C.CaseID = SL.CaseID
																					AND SL.MatchedODSEventID = C.EventID
		LEFT JOIN CRM.XMLOutputValues_Market M ON M.CountryID = SL.CountryID
	WHERE C.CaseID <> 0
		AND C.EventID <> 0


	---------------------------------------------------------------------------------------------------------------------------------------------
	-- Remove any existing errors for the cases we are about to output.  We then add anew if an error still persists
	---------------------------------------------------------------------------------------------------------------------------------------------
	DELETE FROM OE
	FROM #CasesWithNSCRef N
		INNER JOIN CRM.OutputErrors OE ON OE.CaseID = N.CaseID
											AND OE.EventID = N.EventID
	

	------------------------------------------------------------------------------------------------------------------------------------
	---- Check for Cross-Border Cases (i.e. Country of Market different to Country of Case)
	------------------------------------------------------------------------------------------------------------------------------------
	INSERT INTO CRM.OutputErrors (CaseID, EventID, AttemptedOutputDate, ErrorDescription)
	SELECT DISTINCT N.CaseID, 
		N.EventID, 
		@SysDate AS AttemptedOutputDate, 
		'Sampled market CountryID: ' + CAST(ISNULL(M.CountryID,0) AS VARCHAR(5)) + ' does not match NSCRef CountryID: ' + CAST(ISNULL(N.CountryID,0) AS VARCHAR(5)) AS ErrorDescription
	FROM #CasesWithNSCRef N
		LEFT JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL ON SL.CaseID = N.CaseID
																					AND SL.MatchedODSEventID = N.EventID
		LEFT JOIN [$(SampleDB)].dbo.Markets M ON SL.Market = M.Market
		LEFT JOIN [$(SampleDB)].ContactMechanism.Countries C ON N.CountryID = C.CountryID
	WHERE ISNULL(M.CountryID,0) <> ISNULL(N.CountryID,0)

	DELETE FROM N
	FROM #CasesWithNSCRef N
		LEFT JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL ON SL.CaseID = N.CaseID
																					AND SL.MatchedODSEventID = N.EventID
		LEFT JOIN [$(SampleDB)].dbo.Markets M ON SL.Market = M.Market
		LEFT JOIN [$(SampleDB)].ContactMechanism.Countries C ON N.CountryID = C.CountryID
	WHERE ISNULL(M.CountryID,0) <> ISNULL(N.CountryID,0)
	
	

	---------------------------------------------------------------------------------------------------------------------------------------------
	-- Check for missing  XMLOutputValues_Market record (NSCRef lookup) and save to Missing Ref table for email alert output
	---------------------------------------------------------------------------------------------------------------------------------------------
	INSERT INTO CRM.OutputErrors (CaseID, EventID, AttemptedOutputDate, ErrorDescription)
	SELECT N.CaseID, 
		N.EventID, 
		@SysDate AS AttemptedOutputDate, 
		'Missing XMLOutputValues_Market record (NSCRef lookup) for CountryID: ' + CAST(N.CountryID AS VARCHAR(5)) AS ErrorDescription
	FROM #CasesWithNSCRef N
	WHERE N.NSCRef IS NULL

	DELETE
	FROM #CasesWithNSCRef
	WHERE NSCRef IS NULL
				

	----------------------------------------------------------------------------------------------------------------------------------
	-- Pre-Check output fields and remove any Cases where size limits are exceeded. (Code cribbed from OutputXMLforBatch proc.)
	----------------------------------------------------------------------------------------------------------------------------------
	DROP TABLE IF EXISTS #T_AllCases

	CREATE TABLE #T_AllCases
	(
		CaseID		BIGINT,
		EventID		BIGINT,
		NSCRef		NVARCHAR(255)	
	)

	INSERT INTO #T_AllCases (CaseID, EventID, NSCRef)
	SELECT CaseID, 
		EventID,
		NSCRef
	FROM #CasesWithNSCRef


	-------------------------------------------------------------------------------------------------------------------
	-- The following code is taken from [CRM].[uspOutputXMLForBatch] proc.
	-------------------------------------------------------------------------------------------------------------------
	
	--- Get the latest AuditItemID for the CaseIDs and EventIDs provided ----------------------------------------------
	DROP TABLE IF EXISTS #T_LatestAuditItemIDForEvent

	CREATE TABLE #T_LatestAuditItemIDForEvent
	(
		EventID				BIGINT, 
		AuditItemID			BIGINT 
	)
					
	INSERT INTO #T_LatestAuditItemIDForEvent (EventID, AuditItemID)
	SELECT SL.MatchedODSEventID AS EventID, 
		MAX(SL.AuditItemID) AS AuditItemID
	FROM #T_AllCases AC
		INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL ON AC.CaseID = SL.CaseID 
																					AND AC.EventID = SL.MatchedODSEventID
		INNER JOIN [$(SampleDB)].Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = SL.CaseID
																			AND AEBI.PartyID = COALESCE(NULLIF(SL.MatchedODSPersonID, 0), NULLIF(SL.MatchedODSOrganisationID, 0), NULLIF(SL.MatchedODSPartyID, 0)) 
	GROUP BY SL.MatchedODSEventID
				
							
	DROP TABLE IF EXISTS #T_CRM_Data

	CREATE TABLE #T_CRM_Data
	(
		EventID						BIGINT,
		AuditItemID					BIGINT,
		RESPONSE_ID					NVARCHAR(20),
		CAMPAIGN_CAMPAIGN_ID		NVARCHAR(100),
		ACCT_ACCT_ID				NVARCHAR(20),
		ACCT_ACCT_TYPE				NVARCHAR(60),
		LEAD_LEAD_ID				NVARCHAR(10),
		LEAD_BRAND					NVARCHAR(40),
		LEAD_SECON_DEALER_CODE		NVARCHAR(60),
		LEAD_LEAD_CATEGORY			NVARCHAR(30),
		LEAD_LEAD_TRANSACTION_TYPE	NVARCHAR(20),
		LEAD_VEH_SALE_TYPE			NVARCHAR(20),
		LEAD_ENQUIRY_TYPE			NVARCHAR(40),
		LEAD_ORIGIN					NVARCHAR(40),
		LEAD_OWNERSHIP_TYPE			NVARCHAR(60),
		LEAD_QUALIFY_STATUS			NVARCHAR(11),
		LEAD_MODEL_OF_INTEREST		NVARCHAR(40),
		LEAD_MODEL_OF_INTEREST_CODE	NVARCHAR(40)
	)
						
	INSERT INTO #T_CRM_Data (
		EventID,
		AuditItemID,
		RESPONSE_ID,
		CAMPAIGN_CAMPAIGN_ID,
		ACCT_ACCT_ID, 
		ACCT_ACCT_TYPE,									
		LEAD_LEAD_ID,
		LEAD_BRAND,
		LEAD_SECON_DEALER_CODE,
		LEAD_LEAD_CATEGORY,
		LEAD_LEAD_TRANSACTION_TYPE,
		LEAD_VEH_SALE_TYPE,
		LEAD_ENQUIRY_TYPE,
		LEAD_ORIGIN,
		LEAD_OWNERSHIP_TYPE,
		LEAD_QUALIFY_STATUS,
		LEAD_MODEL_OF_INTEREST,
		LEAD_MODEL_OF_INTEREST_CODE)
	SELECT LE.EventID,
		LE.AuditItemID,
		LL.RESPONSE_ID,
		LL.CAMPAIGN_CAMPAIGN_ID,
		LL.ACCT_ACCT_ID,
		LL.ACCT_ACCT_TYPE,
		LL.LEAD_LEAD_ID,
		LL.LEAD_BRAND,
		LL.LEAD_SECON_DEALER_CODE,
		LL.LEAD_LEAD_CATEGORY,
		'Vehicle Sale' AS LEAD_LEAD_TRANSACTION_TYPE,
		LL.LEAD_VEH_SALE_TYPE,
		'Request for Retailer Contact' AS LEAD_ENQUIRY_TYPE,
		CASE WHEN LL.LEAD_ORIGIN = 'Third Party' THEN '3rd Party'			-- V1.2
			 ELSE LL.LEAD_ORIGIN END AS LEAD_ORIGIN,						-- V1.2
		'Retail' AS LEAD_OWNERSHIP_TYPE,
		CASE LL.LEAD_QUALIFY_STATUS	WHEN 'QUALI' THEN 'Qualified'
									ELSE LL.LEAD_QUALIFY_STATUS END AS LEAD_QUALIFY_STATUS,
		LL.LEAD_MODEL_OF_INTEREST,
		LL.LEAD_MODEL_OF_INTEREST_CODE
	FROM #T_LatestAuditItemIDForEvent LE 
		INNER JOIN [$(ETLDB)].CRM.Lost_Leads LL ON LL.AuditItemID = LE.AuditItemID
			
	-- Add an index to speed up access later on 
	CREATE INDEX IDX_T_CRM_Data ON #T_CRM_Data (EventID)
	INCLUDE (
		AuditItemID,
		RESPONSE_ID,
		CAMPAIGN_CAMPAIGN_ID,
		ACCT_ACCT_ID,
		ACCT_ACCT_TYPE,			
		LEAD_LEAD_ID,
		LEAD_BRAND,
		LEAD_SECON_DEALER_CODE,
		LEAD_LEAD_CATEGORY,
		LEAD_LEAD_TRANSACTION_TYPE,
		LEAD_VEH_SALE_TYPE,
		LEAD_ENQUIRY_TYPE,
		LEAD_ORIGIN,
		LEAD_OWNERSHIP_TYPE,
		LEAD_QUALIFY_STATUS,
		LEAD_MODEL_OF_INTEREST,
		LEAD_MODEL_OF_INTEREST_CODE)	

						
	--  Create common base data for both Event and Case derived data ----------------------------------------------------------------------
	DROP TABLE IF EXISTS #T_CollatedCommonBaseData

	CREATE TABLE #T_CollatedCommonBaseData
	(
		CaseID					BIGINT,
		EventID 				BIGINT,					-- This is the key value for lookup and maybe zero
		OrganisationPartyID		BIGINT,
		PartyID					BIGINT,
		ManufacturerPartyID		BIGINT,
		FirstName				NVARCHAR(100),
		LastName				NVARCHAR(100),
		SecondLastName			NVARCHAR(100),
		OrganisationName		NVARCHAR(510),
		EventTypeID				INT,
		CountryID				INT,
		CountryISOAlpha2		CHAR(2),
		Country					VARCHAR(200),
		ODSEventID 				BIGINT,					-- This is the EventID for either CaseID or EventID base data
		NSCRef					NVARCHAR(255)
	)
						
	INSERT INTO #T_CollatedCommonBaseData (
		CaseID,
		EventID,
		OrganisationPartyID,
		PartyID,
		ManufacturerPartyID,
		FirstName,
		LastName,
		SecondLastName,
		OrganisationName,
		EventTypeID,
		CountryID,
		CountryISOAlpha2,
		Country, 
		ODSEventID,	
		NSCRef
	)
	SELECT AC.CaseID,
		AC.EventID,																-- Keep key value (zero) for matching back to CaseResponseStatuses table ETC.
		CASE	WHEN CRM.ACCT_ACCT_TYPE = 'Person' THEN NULL
				ELSE CD.OrganisationPartyID	END AS OrganisationPartyID,
		CD.PartyID,
		CD.ManufacturerPartyID,
		CD.FirstName,
		CD.LastName,
		CD.SecondLastName,
		CASE	WHEN CRM.ACCT_ACCT_TYPE = 'Person' THEN NULL
				ELSE CD.OrganisationName END AS OrganisationName,
		CD.EventTypeID,
		CD.CountryID,
		CD.CountryISOAlpha2,
		CD.Country,
		CD.EventID AS ODSEventID,
		AC.NSCRef
	FROM #T_AllCases AC 
		LEFT JOIN [$(SampleDB)].Meta.CaseDetails CD ON CD.CaseID = AC.CaseID  
		LEFT JOIN #T_CRM_Data CRM ON CRM.EventID = CD.EventID
	WHERE AC.CaseID <> 0


	-- TEMP fix to set the Org PartyID to NULL, if the PartyID is actually a person
	UPDATE CB															--  <<<<<<<<<<<<<<<<<<<<<<<<<<< TEMP - TO BE REMOVED ONCE CASEDETAILS PROC IS CORRECTED <<<<<<<<<<<<<<<<<<<<<<<<
	SET CB.OrganisationPartyID = NULL
	FROM #T_CollatedCommonBaseData CB
		INNER JOIN [$(SampleDB)].Party.People P ON P.PartyID = CB.OrganisationPartyID   	


	--  Create common base data for both Event and Case derived data ----------------------------------------------------------------------
	DROP TABLE IF EXISTS #T_CampaignResponsesCustomerInfo

	CREATE TABLE #T_CampaignResponsesCustomerInfo
	(
		CaseID					BIGINT,
		EventID					BIGINT,	
		PartyID					BIGINT,
		OrganisationPartyID		BIGINT,
		RspnseID				NVARCHAR(20),
		Status					NVARCHAR(50),
		ResponseStatusID		INT,
		LoadedToConnexions		DATETIME2,
		CmpgnID					NVARCHAR(255),
		NSCRef					NVARCHAR(255),
		Manufacturer			VARCHAR(510),
		Questionnaire			VARCHAR(255),
		Role					VARCHAR(255),
		FstNm					NVARCHAR(100),				
		LstNm					NVARCHAR(100),			
		AddLstNm				NVARCHAR(100),
		OrgName1				NVARCHAR(510),	
		OrgName2				NVARCHAR(510),	
		Cntry					VARCHAR(200),		
		ACCT_ACCT_ID			NVARCHAR(20),
		ACCT_ACCT_TYPE			NVARCHAR(60),
		CRM_CustID_Individual	VARCHAR(60),				-- Updated in later step
		CRM_CustID_Organisation	VARCHAR(60),				-- Updated in later step
		CRMCustomer				CHAR(1),					-- Updated in later step
		ReturnIndividual		CHAR(1),					-- Updated in later step
		VsbltyStts				NVARCHAR(100),
		DlrCd					VARCHAR(60),
		LdId					NVARCHAR(10),
		ThirdPtyLdId			NVARCHAR(10),
		LdBrand					NVARCHAR(40),
		LdCntry					VARCHAR(50),		
		LdCtgy					NVARCHAR(30),
		LdTxnType				NVARCHAR(20),
		Sts						NVARCHAR(40),
		LdStsRsn1				NVARCHAR(40),
		LdStsRsn2				NVARCHAR(40),
		LdStsRsn3				NVARCHAR(40),
		LdTrnfSts				NVARCHAR(40),
		VhcleSalesType			NVARCHAR(20),
		EnqType					NVARCHAR(40),
		LdOrgn					NVARCHAR(40),
		OwnshipType				NVARCHAR(60),
		LLAgncyNm				NVARCHAR(30),
		QlfctnStts				NVARCHAR(11),
		PartyType				NVARCHAR(30),
		MiscVhcleType			NVARCHAR(40),
		Brand					NVARCHAR(40),
		Model					NVARCHAR(40),
		Note					NVARCHAR(MAX),
		RecontactDate			DATETIME2,
		OtherBrand				NVARCHAR(40),
		OtherModel				NVARCHAR(40)
	)

	;WITH CTE_ResponseStatusOrdered AS				-- In case more than one status gets triggered at the same time we will take them in the precedence order set in the ResponseStatuses table
	(
		SELECT ROW_NUMBER() OVER (PARTITION BY CBX.CaseID, CBX.EventID ORDER BY RS.Precedence) AS RowID,  
			CBX.CaseID, 
			CBX.EventID, 
			RS.ResponseStatusCRMOutputValue, 
			LLRS.ResponseStatusID, 
			LLRS.LoadedToConnexions
		FROM #T_CollatedCommonBaseData CBX
			INNER JOIN CRM.LostLeadResponseStatuses LLRS ON LLRS.CaseID = CBX.CaseID
															AND LLRS.EventID = CBX.EventID
			INNER JOIN CRM.ResponseStatuses RS ON RS.ResponseStatusID = LLRS.ResponseStatusID 
	)	
	INSERT INTO #T_CampaignResponsesCustomerInfo 
	(
		CaseID,
		EventID,
		PartyID,
		OrganisationPartyID,
		RspnseID,
		Status,
		ResponseStatusID,
		LoadedToConnexions,
		CmpgnID,
		NSCRef,
		Manufacturer,
		Questionnaire,
		Role,
		FstNm,
		LstNm,
		AddLstNm,
		OrgName1,
		OrgName2,
		Cntry,
		ACCT_ACCT_ID,
		ACCT_ACCT_TYPE,
		VsbltyStts,
		DlrCd,
		LdId,
		ThirdPtyLdId,
		LdBrand,
		LdCntry,		
		LdCtgy,
		LdTxnType,
		Sts,
		LdStsRsn1,
		LdStsRsn2,
		LdStsRsn3,
		LdTrnfSts,
		VhcleSalesType,
		EnqType,
		LdOrgn,
		OwnshipType,
		LLAgncyNm,
		QlfctnStts,
		PartyType,
		MiscVhcleType,
		Brand,
		Model,
		Note,
		RecontactDate,
		OtherBrand,
		OtherModel
	)
	SELECT CB.CaseID,
		CB.EventID,
		CASE	WHEN CB.OrganisationPartyID IS NOT NULL AND CB.PartyID = CB.OrganisationPartyID THEN NULL 
				ELSE CB.PartyID END AS PartyID,
		CB.OrganisationPartyID,
		LL.RESPONSE_ID AS RspnseID,
		RSO.ResponseStatusCRMOutputValue AS Status,
		RSO.ResponseStatusID,
		RSO.LoadedToConnexions,
		CAMPAIGN_CAMPAIGN_ID AS CmpgnID,
		CB.NSCRef,
		O.OrganisationName AS Manufacturer, 
		EC.EventCategory AS Questionnaire,
		CASE	WHEN EXISTS (	SELECT * 
								FROM [$(SampleDB)].Party.PartyClassifications PC 
									INNER JOIN [$(SampleDB)].Party.PartyTypes PT ON PT.PartyTypeID = PC.PartyTypeID
																			AND PT.PartyType = 'Vehicle Leasing Company'
								WHERE PC.PartyID = CB.OrganisationPartyID) THEN 'Fleet Account' 
				ELSE 'Account'	END AS Role,
		CASE	WHEN R.Region = 'MENA' THEN (SELECT FirstName FROM dbo.udfCRM_MENA_Format_Name(CB.FirstName, CB.LastName))
				ELSE CB.FirstName END AS FstNm,				
		CASE	WHEN R.Region = 'MENA' THEN (SELECT LastName FROM dbo.udfCRM_MENA_Format_Name(CB.FirstName, CB.LastName))
				ELSE CB.LastName END AS LstNm,
		NULLIF(CB.SecondLastName, '') AS AddLstNm,
		NULLIF((SELECT Column1 FROM dbo.udfSplitColumnIntoTwo(CB.OrganisationName, 40, 40)), '') AS OrgName1,		
		NULLIF((SELECT Column2 FROM dbo.udfSplitColumnIntoTwo(CB.OrganisationName, 40, 40)), '') AS OrgName2,	
		COALESCE(CCL.Country, CB.Country) AS Cntry,						-- Country name needs to match the list provided by JLR (e.g. Russia NOT Russian Federation)
		LL.ACCT_ACCT_ID,												-- AccountID as supplied in sample
		LL.ACCT_ACCT_TYPE,												-- Account Type as supplied in sample
		CASE	WHEN ISNULL(CSE.AnonymityDealer, 0) = 1 THEN 'JLR Only' 
				ELSE 'All' END AS VsbltyStts,							-- Note that only valid recs will get though to this proc, so we only need to check AnonymityDealer flag
		CASE	WHEN D.OutletCode IS NOT NULL AND B.Brand = 'Land Rover' THEN 'LR' + CB.CountryISOAlpha2 + D.OutletCode
				WHEN D.OutletCode IS NOT NULL AND B.Brand = 'Jaguar' THEN 'J' + CB.CountryISOAlpha2 + D.OutletCode
				ELSE NULL END AS DlrCd,
		LL.LEAD_LEAD_ID AS LdId,
		'' AS ThirdPtyLdId,
		LL.LEAD_BRAND AS LdBrand,
		COALESCE(CCL.Country, CB.Country) AS LdCntry,
		LL.LEAD_LEAD_CATEGORY AS LdCtgy,
		LL.LEAD_LEAD_TRANSACTION_TYPE AS LdTxnType,
		LLR.[SV-CRM Lead Status] AS Sts,
		LLR.[SV-CRM Lead Status Reason 1] AS LdStsRsn1,
		LLR.[SV-CRM Lead Status Reason 2] AS LdStsRsn2,
		LLR.[SV-CRM Lead Status Reason 3] AS LdStsRsn3,
		'' AS LdTrnfSts,
		LL.LEAD_VEH_SALE_TYPE AS VhcleSalesType,
		LL.LEAD_ENQUIRY_TYPE AS EnqType,
		LL.LEAD_ORIGIN AS LdOrgn,
		LL.LEAD_OWNERSHIP_TYPE AS OwnshipType,
		'Central' AS LLAgncyNm,
		LL.LEAD_QUALIFY_STATUS AS QlfctnStts,
		'Sales Prospect' AS PartyType,
		'Model of Interest' AS MiscVhcleType,
		LL.LEAD_BRAND AS Brand,
		LL.LEAD_MODEL_OF_INTEREST_CODE AS Model,		
		LLR.Notes AS Note,
		LLR.RecontactDate,
		LLM.LEAD_BRAND AS OtherBrand,
		LLM.LEAD_MODEL_OF_INTEREST_CODE AS OtherModel
	FROM #T_CollatedCommonBaseData CB
		INNER JOIN [$(SampleDB)].Event.EventTypeCategories ETC ON ETC.EventTypeID = CB.EventTypeID
		INNER JOIN [$(SampleDB)].Event.EventCategories EC ON EC.EventCategoryID = ETC.EventCategoryID
		INNER JOIN [$(SampleDB)].Party.Organisations O ON O.PartyID = CB.ManufacturerPartyID 
		INNER JOIN [$(SampleDB)].dbo.Markets MKT ON MKT.CountryID = CB.CountryID
		INNER JOIN [$(SampleDB)].dbo.Regions R ON R.RegionID = MKT.RegionID
		INNER JOIN [$(SampleDB)].dbo.Brands B ON B.ManufacturerPartyID = CB.ManufacturerPartyID 
		INNER JOIN CTE_ResponseStatusOrdered RSO ON RSO.CaseID = CB.CaseID 
													AND RSO.EventID = CB.EventID 
													AND RSO.RowID = 1
		LEFT JOIN CRM.CountryLookup CCL ON CCL.ISOAlpha2 = CB.CountryISOAlpha2
		LEFT JOIN #T_CRM_Data LL ON LL.EventID = CB.ODSEventID 
		LEFT JOIN [$(SampleDB)].Event.Cases CSE ON CSE.CaseID = CB.CaseID
		LEFT JOIN [$(SampleDB)].Event.EventPartyRoles EPR ON EPR.EventID = CB.ODSEventID
		LEFT JOIN [$(SampleDB)].dbo.DW_JLRCSPDealers D ON D.OutletPartyID = EPR.PartyID
													AND D.OutletFunction = (CASE	WHEN EC.EventCategory = 'Service' THEN 'AfterSales' 
																					WHEN EC.EventCategory = 'LostLeads' THEN 'Sales'
																					WHEN EC.EventCategory = 'PreOwned LostLeads' THEN 'PreOwned'
																					ELSE EC.EventCategory END)
		LEFT JOIN [$(SampleDB)].Event.CRMLostLeadReasons LLR ON LLR.CaseID	= CB.CaseID	
		LEFT JOIN [$(SampleDB)].Event.CRMLostLeadResponses LLRS ON LLRS.CaseID = CB.CaseID
																	AND LLRS.Question = 'S3'
		LEFT JOIN CRM.LostLeadModels LLM ON LLRS.Response = LLM.OtherModel



	--  Get associated CRM Customer ID (Person)----------------------------------------------------------------------------------
	DROP TABLE IF EXISTS #T_PersonCustomerID

	CREATE TABLE #T_PersonCustomerID
	(
		PartyID		BIGINT,
		AcctID		VARCHAR(60)
	)
						
	INSERT INTO #T_PersonCustomerID (PartyID, AcctID)
	SELECT RSP.PartyID,  
		MAX(REPLACE(CR.CustomerIdentifier, 'CRM_', '')) AS AcctID
	FROM #T_CampaignResponsesCustomerInfo RSP
		INNER JOIN [$(SampleDB)].Party.CustomerRelationships CR ON CR.PartyIDFrom = RSP.PartyID 
																	AND CR.CustomerIdentifier LIKE 'CRM_%'	
																	AND CR.CustomerIdentifierUsable = 1
	GROUP BY RSP.PartyID


	--  Get associated CRM Customer ID (Organization)----------------------------------------------------------------------------------
	DROP TABLE IF EXISTS #T_OrgCustomerID

	CREATE TABLE #T_OrgCustomerID
	(
		PartyID		BIGINT ,
		AcctID		VARCHAR(60)
	)
						
	INSERT INTO #T_OrgCustomerID (PartyID, AcctID)
	SELECT RSP.OrganisationPartyID AS PartyID,  
		MAX(REPLACE(CR.CustomerIdentifier, 'CRM_', '')) AS AcctID
	FROM #T_CampaignResponsesCustomerInfo RSP
		INNER JOIN [$(SampleDB)].Party.CustomerRelationships CR ON CR.PartyIDFrom = RSP.OrganisationPartyID 
																	AND CR.CustomerIdentifier LIKE 'CRM_%'	
																	AND CR.CustomerIdentifierUsable = 1
	GROUP BY RSP.OrganisationPartyID
					

	UPDATE CI
	SET CI.CRM_CustID_Individual = CASE WHEN CI.ACCT_ACCT_TYPE = 'Person' THEN CI.ACCT_ACCT_ID			-- NOTE: the Organization and Person Cust ID columns use ACCT_ACCT_ID as primary value on both	-- V1.28
										ELSE PCI.AcctID END,											
		CI.CRM_CustID_Organisation = CASE WHEN CI.ACCT_ACCT_TYPE = 'Organization' THEN CI.ACCT_ACCT_ID
										ELSE OCI.AcctID END,
		CI.CRMCustomer = CASE	WHEN NULLIF(CI.ACCT_ACCT_ID, '') IS NOT NULL THEN 'Y'					-- When we have a CRM account ID present in the staging tables   -- V1.28
								ELSE 'N' END,
		CI.ReturnIndividual	= CASE	WHEN CI.ACCT_ACCT_TYPE = 'Person' THEN 'Y'							-- When the customer was received via CRM as "Person", then we return level as Person -- V1.28
									ELSE 'N' END
	FROM #T_CampaignResponsesCustomerInfo CI
		LEFT JOIN #T_PersonCustomerID PCI ON PCI.PartyID = CI.PartyID
		LEFT JOIN #T_OrgCustomerID OCI ON OCI.PartyID = CI.OrganisationPartyID


	--  Get associated CRM Response Comments----------------------------------------------------------------------------------
	DROP TABLE IF EXISTS #T_Comments

	CREATE TABLE #T_Comments
	(
		CaseID			BIGINT ,
		Comment			NVARCHAR(MAX),
		CommentOrder	TINYINT
	)
						
	INSERT INTO #T_Comments (CaseID, Comment, CommentOrder)
	SELECT CTR.CaseID,
		CTR.Note AS Comment,
		1 AS CommentOrder
	FROM #T_CampaignResponsesCustomerInfo CTR
	WHERE CTR.Note IS NOT NULL
	UNION
	SELECT CB.CaseID,
		Q.MedalliaField + CHAR(10) + SUBSTRING([$(SampleDB)].dbo.udfRemoveInvalidXMLCharacters(LLR.Response),1,6900) AS Comment,	-- V1.3
		2 AS CommentOrder
	FROM #T_CollatedCommonBaseData CB
		INNER JOIN [$(SampleDB)].Event.CRMLostLeadResponses LLR ON CB.CaseID = LLR.CaseID
		INNER JOIN [$(SampleDB)].Event.CRMLostLeadQuestions Q ON LLR.Question = Q.Question
	WHERE Q.QuestionType = 'Verbatim'
		AND LEN(LLR.Response) > 0


	-------------------------------------------------------------------------------------------------------------------
	-- ... END OF CODE from [CRM].[uspOutputXMLForBatch] proc.
	-------------------------------------------------------------------------------------------------------------------


	-----------------------------------------------------------------------------------------------------------------------------------------------
	-- Ensure that all of the Cases have made it into the checking file, if not then we have a logic issue which will hit the main output as well 
	-----------------------------------------------------------------------------------------------------------------------------------------------
	IF (SELECT COUNT(*) FROM #CasesWithNSCRef) <> (SELECT COUNT(*) FROM #T_CampaignResponsesCustomerInfo)
	RAISERROR ('uspSC114CalculateOutputBatches - Count of recs in #CasesWithNSCRef NOT EQUAL to #T_CampaignResponsesCustomerInfo',
		16,		-- Severity
		1		-- State 
	) 
	-----------------------------------------------------------------------------------------------------------------------------------------------


	-----------------------------------------------------------------------------------------------------------------------------------------------
	-- Check that AnonymityManufacturer has not been set.
	-----------------------------------------------------------------------------------------------------------------------------------------------
	IF (	SELECT	COUNT(*)
			FROM #T_AllCases AC
				INNER JOIN [$(SampleDB)].Event.Cases C ON C.CaseID = AC.CaseID
				INNER JOIN CRM.LostLeadResponseStatuses RS ON RS.CaseID = AC.CaseID			  
															AND RS.EventID = AC.EventID
															AND RS.ResponseStatusID = (	SELECT ResponseStatusID 
																						FROM CRM.ResponseStatuses 
																						WHERE ResponseStatus IN ('Completed'))
															AND RS.OutputToCRMDate IS NULL
			WHERE AC.CaseID <> 0 
				AND C.AnonymityManufacturer = 1) <> 0
	RAISERROR ('uspSC114CalculateOutputBatches - CaseIDs for output with Manufacturer Anonymity set TRUE',
		16,		-- Severity
		1		-- State 
	) 	



	---------------------------------------------------------------------------------------------------------------------------------------------
	-- Remove any existing Size limit errors for the cases we are about to output.  We then add anew if an error still persists.
	---------------------------------------------------------------------------------------------------------------------------------------------
	-- Remove any current Cases from the ResponsesHeldBackDueToSizeLimits prior to checking as they may now be OK
	DELETE SL
	FROM #CasesWithNSCRef N
		INNER JOIN CRM.ResponsesHeldBackDueToSizeLimits SL ON SL.CaseID = N.CaseID	


	-- NOW RUN CHECKS ON FIELD SIZES
	INSERT INTO CRM.ResponsesHeldBackDueToSizeLimits (CaseID, EventID, ACCT_ACCT_ID, FstNm, LstNm, AddLstNm, Cntry, OrgName1, DateAdded)
	SELECT CR.CaseID,
		CR.EventID,
		CR.ACCT_ACCT_ID,
		CASE	WHEN LEN(ISNULL(CR.FstNm, 0)) > 40 THEN CR.FstNm
				ELSE '' END AS FstNm,		
		CASE	WHEN LEN(ISNULL(CR.LstNm, 0)) > 40 THEN CR.LstNm
				ELSE '' END AS LstNm,
		CASE	WHEN LEN(ISNULL(CR.AddLstNm, 0)) > 40 THEN CR.AddLstNm		
				ELSE '' END AS AddLstNm,
		CASE	WHEN LEN(ISNULL(CR.Cntry, 0)) > 50 THEN CR.Cntry		
				ELSE '' END AS Cntry,
		CASE WHEN LEN(CR.OrgName1) > 40 THEN CR.OrgName1
		ELSE '' END AS OrgName1,
		@SysDate AS DateAdded
	FROM #T_CampaignResponsesCustomerInfo CR
	WHERE LEN(ISNULL(CR.FstNm, 0)) > 40
		OR LEN(ISNULL(CR.LstNm, 0)) > 40
		OR LEN(ISNULL(CR.AddLstNm, 0)) > 40
		OR LEN(ISNULL(CR.Cntry, 0)) > 50


	-- Remove from the #CasesWithNSCRef temp table so that they are not output
	DELETE FROM #CasesWithNSCRef
	WHERE CaseID IN (	SELECT CaseID 
						FROM CRM.ResponsesHeldBackDueToSizeLimits)	


	---------------------------------------------------------------------------------------------------------------------------------------------
	-- Check for missing CRM Data and save to Missing Ref table for email alert output
	---------------------------------------------------------------------------------------------------------------------------------------------
	INSERT INTO CRM.OutputErrors (CaseID, EventID, AttemptedOutputDate, ErrorDescription)
	SELECT N.CaseID, 
		N.EventID, 
		@SysDate AS AttemptedOutputDate, 
		'Missing CRM data' AS ErrorDescription
	FROM #CasesWithNSCRef N
		INNER JOIN #T_CollatedCommonBaseData CD ON CD.CaseID = N.CaseID 
													AND CD.EventID = N.EventID
		LEFT JOIN #T_CRM_Data CRMD ON CRMD.EventID = CD.ODSEventID		
	WHERE CRMD.ACCT_ACCT_ID IS NULL										-- Check whether CRM data is present 


	-- Delete from output
	DELETE N
	FROM #CasesWithNSCRef N
		INNER JOIN CRM.OutputErrors OE ON OE.CaseID = N.CaseID
										AND OE.EventID = N.EventID
										AND OE.ErrorDescription = 'Missing CRM data'
	

	---------------------------------------------------------------------------------------------------------------------------------------------
	-- Populate the batch table with the batch numbers for each case
	---------------------------------------------------------------------------------------------------------------------------------------------
	;WITH CTE_BatchesWithinNSCRef AS
	(
		SELECT NSCRef, 
			Batch, 
			CaseID, 
			EventID
		FROM (	SELECT	ROW_NUMBER() OVER (PARTITION BY NSCRef, R%@BatchSize ORDER BY NSCRef, CaseID, EventID) AS Batch,
					R%@BatchSize batch_perc,
					*
				FROM (	SELECT ROW_NUMBER() OVER (PARTITION BY NSCRef ORDER BY NSCRef, CaseID, EventID) AS R,
							NSCRef,
							CaseID,
							EventID
						FROM #CasesWithNSCRef 
					) AS T
			) AS B
	)
	,CTE_BatchesSequential AS 
	(
		SELECT NSCRef, 
			Batch, 
			ROW_NUMBER() OVER (ORDER BY NSCRef, Batch) AS BatchSeq
		FROM (	SELECT DISTINCT 
					NSCRef, 
					Batch
				FROM CTE_BatchesWithinNSCRef) C
	)		
	INSERT INTO CRM.OutputBatches (Batch, Row, NSCRef, CaseID, EventID)
	SELECT S.BatchSeq AS Batch,
	     ROW_NUMBER() OVER (ORDER BY BatchSeq) AS Row,
		 S.NSCRef, 
		 BN.CaseID,
		 BN.EventID
	FROM CTE_BatchesWithinNSCRef BN
		INNER JOIN CTE_BatchesSequential S ON S.Batch = BN.Batch 
											AND S.NSCRef = BN.NSCRef
	ORDER BY S.BatchSeq


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
		
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH