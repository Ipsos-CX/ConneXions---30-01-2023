CREATE PROCEDURE CRM.uspSC114OutputXMLForBatch  

@Batch INT

AS

SET NOCOUNT ON;
SET FMTONLY OFF;


DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)


BEGIN TRY


/*
		Purpose:	Outputs the SC114 XML for the cases in the specified batch
		
		Version		Date			Developer			Comment
LIVE	1.0			2021-12-08		Chris Ledger		Created from uspOutputXMLForBatch
LIVE	1.1			2022-05-23		Chris Ledger		Task 530 - Exclude Comments temporarily
LIVE	1.2			2022-05-23		Chris Ledger		Task 530 - Map LEAD_ORIGIN Third Party to 3rd Party
LIVE	1.3			2022-05-24		Chris Ledger		Task 530 - reinstate Comments and remove invalid XML characters
*/


	--------------------------------------------------------------------------------------------------
	-- Create UUID for ContextId element
	--------------------------------------------------------------------------------------------------
	DECLARE @UID UNIQUEIDENTIFIER,						
			@ContextId NVARCHAR(42)

	SET @UID = NEWID()
	SET @ContextId = 'uuid:' + CONVERT(NVARCHAR(40), @UID)


	--------------------------------------------------------------------------------------------------
	-- Set the UUID in the CRM.CaseResponseStatuses table for reference purposes
	--------------------------------------------------------------------------------------------------
	UPDATE C
	SET C.UUID = @UID
	FROM CRM.OutputBatches B 
	INNER JOIN CRM.LostLeadResponseStatuses C ON C.CaseID = B.CaseID
												AND C.EventID = B.EventID
												AND C.OutputToCRMDate IS NULL
	WHERE B.Batch = @Batch
	
	
	------------------------------------------------------------------------------------------------
	-- Variables to hold and convert the XML for output
	------------------------------------------------------------------------------------------------	
	DECLARE @XML_BatchHeader	XML,
			@XML_BatchBody		XML,
			@NVC_BatchHeader	NVARCHAR(MAX),
			@NVC_BatchBody		NVARCHAR(MAX),
			@NVC_FileTop		NVARCHAR(MAX),
			@NVC_FileBottom		NVARCHAR(MAX),
			@NVC_OUTPUT			NVARCHAR(MAX)
		

	------------------------------------------------------------------------------------------------
	-- Get Cases and Events list to output
	------------------------------------------------------------------------------------------------
	DROP TABLE IF EXISTS #T_AllCases

	CREATE TABLE #T_AllCases
	(
		CaseID		BIGINT,
		EventID		BIGINT,
		NSCRef		NVARCHAR(255)
	)

	INSERT INTO #T_AllCases (CaseID, EventID, NSCRef)
	SELECT  DISTINCT
		CaseID, 
		EventID,
		NSCRef
	FROM CRM.OutputBatches 
	WHERE Batch = @Batch



	------------------------------------------------------------------------------------------------
	-- Output the XML for the batch header
	------------------------------------------------------------------------------------------------
	SELECT @XML_BatchHeader = (
		SELECT	
			(
				SELECT 'UsernameTokenProfile' AS SecurityType,
					(
						SELECT I.Username, 
							I.Password 
						FROM [$(ETLDB)].CRM.SecurityHeaderInfo I
						WHERE I.ServerName = @@SERVERNAME
							AND I.Username LIKE 'SC114%'
						FOR XML PATH ('UsernameTokenProfile'), TYPE 
					)
				FOR XML PATH ('JLRSecurityHeader'), TYPE 
			)
			,
			(
				SELECT	@ContextId AS ContextId,				
					CONVERT(NVARCHAR(25), GETDATE(), 127) AS Timestamp,
					I.Logging, 
					I.NullMessage, 
					I.LanguageCode, 
					I.ConsumerRef 
				FROM [$(ETLDB)].CRM.SecurityHeaderInfo I
				WHERE I.ServerName = @@SERVERNAME
					AND I.Username LIKE 'SC114%'
				FOR XML PATH ('JLRCommonHeader'), TYPE 
			)
			,
			(
				SELECT COUNT(*) AS TotalNoOfMsgs
				FROM #T_AllCases 
				FOR XML PATH ('JLRCommonBatchHeader'), TYPE 
			)
		FOR XML PATH ('BatchRequestHeader') , TYPE 
	) 



	--------------------------------------------------------------------------------------------------
	-- Output the XML for the body
	--------------------------------------------------------------------------------------------------

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
				
							
	-- Get any associated CRM data  ----------------------------------------------------------------------------------
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
		CASE WHEN LL.LEAD_QUALIFY_STATUS = 'QUALI' THEN 'Qualified'
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
		RecontactDate			NVARCHAR(25),
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
		CONVERT(NVARCHAR(25), CAST(LLR.RecontactDate AS DATETIMEOFFSET), 127) AS RecontactDate,
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
	--/*	V1.1 - Exclude Comments
	UNION
	SELECT CB.CaseID,
		Q.MedalliaField + CHAR(10) + SUBSTRING([$(SampleDB)].dbo.udfRemoveInvalidXMLCharacters(LLR.Response),1,6900) AS Comment,	-- V1.3
		2 AS CommentOrder
	FROM #T_CollatedCommonBaseData CB
		INNER JOIN [$(SampleDB)].Event.CRMLostLeadResponses LLR ON CB.CaseID = LLR.CaseID
		INNER JOIN [$(SampleDB)].Event.CRMLostLeadQuestions Q ON LLR.Question = Q.Question
	WHERE Q.QuestionType = 'Verbatim'
		AND LEN(LLR.Response) > 0
	--*/

	-------------------------------------------------------------------------------------------------------------------
	-- ... END OF CODE from [CRM].[uspOutputXMLForBatch] proc.
	-------------------------------------------------------------------------------------------------------------------


	-- POPULATE THE XML FIELDS --------------------------------------------------------------------------------------------------------------------
	SELECT @XML_BatchBody = (
		SELECT ( 
			SELECT ( -- BatchRequestBody
				SELECT (  -- BatchMessages
					SELECT (  -- createOrUpdateLeadAndProspect
						SELECT ( -- CRMHeader
							SELECT 'LM' AS BusinessProcessReference,
								CTR.Manufacturer AS Brand,
								CTR.NSCRef
							FOR XML PATH ('CRMHeader'), TYPE 
						),
						( -- Lead
						SELECT 
							CASE WHEN LEN(CTR.LdId)>0 THEN CTR.LdId END AS 'LdId',
							CASE WHEN LEN(CTR.ThirdPtyLdId)>0 THEN CTR.ThirdPtyLdId END AS 'ThirdPtyLdId',
							CASE WHEN LEN(CTR.LdBrand)>0 THEN CTR.LdBrand END AS 'LdBrand',
							CASE WHEN LEN(CTR.LdCntry)>0 THEN CTR.LdCntry END AS 'LdCntry',
							CASE WHEN LEN(CTR.LdCtgy)>0 THEN CTR.LdCtgy END AS 'LdCtgy',
							CASE WHEN LEN(CTR.LdTxnType)>0 THEN CTR.LdTxnType END AS 'LdTxnType',
							CASE WHEN LEN(CTR.Sts)>0 THEN CTR.Sts END AS 'Sts',
							CASE WHEN LEN(CTR.LdStsRsn1)>0 THEN CTR.LdStsRsn1 END AS 'LdStsRsn1',
							CASE WHEN LEN(CTR.LdStsRsn2)>0 THEN CTR.LdStsRsn2 END AS 'LdStsRsn2',
							CASE WHEN LEN(CTR.LdStsRsn3)>0 THEN CTR.LdStsRsn3 END AS 'LdStsRsn3',
							CASE WHEN LEN(CTR.LdTrnfSts)>0 THEN CTR.LdTrnfSts END AS 'LdTrnfSts',
							CASE WHEN LEN(CTR.VhcleSalesType)>0 THEN CTR.VhcleSalesType END AS 'VhcleSalesType',
							CASE WHEN LEN(CTR.EnqType)>0 THEN CTR.EnqType END AS 'EnqType',
							CASE WHEN LEN(CTR.LdOrgn)>0 THEN CTR.LdOrgn END AS 'LdOrgn',
							CASE WHEN LEN(CTR.QlfctnStts)>0 THEN CTR.QlfctnStts END AS 'QlfctnStts',							
							( -- MiscVhcles
							SELECT ( -- MiscVhcle
								SELECT CTR.MiscVhcleType,
									CASE	WHEN CTR.OtherBrand IS NOT NULL THEN CTR.OtherBrand
											ELSE CTR.Brand END AS 'Brand',
									CASE	WHEN CTR.OtherModel IS NOT NULL THEN CTR.OtherModel
											ELSE CTR.Model END AS 'Mdl',
									'true' AS 'PrFlg'
								FOR XML PATH ('MiscVhcle'), TYPE
								)
							FOR XML PATH ('MiscVhcles'), TYPE
							),

							( -- LdDts
							SELECT ( -- LdDt
								SELECT  'Recontact Date' AS 'Type',
									CTR.RecontactDate AS 'Dt'
								FOR XML PATH ('LdDt'), TYPE
								)
							WHERE LEN(CTR.RecontactDate) > 0 
							FOR XML PATH ('LdDts'), TYPE
							),

							( -- LdNotes
							SELECT ( -- LdNote
								SELECT	'Note' AS 'NoteType',
									C.Comment AS 'Note'
								FROM #T_Comments C
								WHERE C.CaseID = CTR.CaseID
								AND LEN(C.Comment) > 0
								ORDER BY C.CommentOrder
								FOR XML PATH ('LdNote'), TYPE
								)									
							FOR XML PATH ('LdNotes'), TYPE
							),
	
							( -- LdPartiesInv
							SELECT ( -- LdParty
								SELECT  CTR.PartyType,
	
								( -- Acct
								SELECT
									CASE	WHEN CTR.CRMCustomer = 'Y' THEN CTR.ACCT_ACCT_ID		-- V1.28
											--WHEN CTR.CRMCustomer = 'Y' THEN COALESCE(CTR.CRM_CustID_Individual, CTR.CRM_CustID_Organisation) 
											ELSE NULL END AS AcctId, 
									CASE	WHEN CTR.ReturnIndividual = 'Y' THEN CTR.FstNm 
											ELSE NULL END AS FstNm,									-- Only display if there is no Org info
									CASE	WHEN CTR.ReturnIndividual = 'Y' THEN CTR.LstNm 
											ELSE NULL END AS LstNm,									-- Only display if there is no Org info
									CASE	WHEN CTR.ReturnIndividual = 'Y' THEN CTR.AddLstNm 
											ELSE NULL END AS AddLstNm,								-- Only display if there is no Org info
									CASE	WHEN CTR.ReturnIndividual = 'Y' THEN NULL 
											ELSE CTR.OrgName1 END AS OrgName1,						-- Only display if there is no Person info,
									CASE	WHEN CTR.ReturnIndividual = 'Y' THEN NULL 
											ELSE CTR.OrgName2 END AS OrgName2,						-- V1.8 added - Only display if there is no Person info,
									CASE	WHEN CTR.ReturnIndividual = 'Y' THEN 'Individual' 
											ELSE 'Organisation' END AS AcctType,
									CTR.Cntry,
									'JLR' AS 'AcctOrgn',
									
									(-- AcctRls		
									SELECT ( -- AcctRl	
										SELECT	
											--'Z2' AS '@ActnCd',
											CTR.Role
										FOR XML PATH ('AcctRl'), TYPE 
										)
									FOR XML PATH ('AcctRls'), TYPE 
									)									
								FOR XML PATH ('Acct'), TYPE
									)
							FOR XML PATH ('LdParty'), TYPE
								)
							FOR XML PATH ('LdPartiesInv'), TYPE
							)
						FOR XML PATH ('Lead'), TYPE
						)
					FROM #T_CampaignResponsesCustomerInfo CTR
					FOR XML PATH ('createOrUpdateLeadAndProspect'), TYPE
					)
				FOR XML PATH ('BatchMessages'), TYPE
				)
			FOR XML PATH ('BatchRequestBody'), TYPE 
			)
		) 
	)

		
	--------------------------------------------------------------------------------------------------
	-- UPDATE the CR.BatchOutput table with the Response Status, Unsubs, Bouncebacks and LoadedToConnexionsDate						
	-- for Auditing purposes in [CRM].[uspSetOutputDatesForBatch]
	--------------------------------------------------------------------------------------------------
	UPDATE B
	SET B.OutputResponseStatusID = CI.ResponseStatusID,
		B.LoadToConnexionsDate = CI.LoadedToConnexions
	FROM #T_CampaignResponsesCustomerInfo CI
		INNER JOIN CRM.OutputBatches B ON B.CaseID = CI.CaseID 
										AND B.EventID = CI.EventID


	--------------------------------------------------------------------------------------------------
	-- Convert and Concatenate the various parts of the XML
	--------------------------------------------------------------------------------------------------
	SET @NVC_BatchHeader =  CONVERT(NVARCHAR(max), @XML_BatchHeader) 
	SET @NVC_BatchBody   =  CONVERT(NVARCHAR(max), @XML_BatchBody) 

	SET @NVC_FileTop = '<?xml version="1.0" encoding="UTF-8"?><mssext:createOrUpdateLeadAndProspectBatch xsi:schemaLocation="http://jlrint.com/mss/message/crmcreateorupdateleadandprospect/2 CreateOrUpdateLeadAndProspectMessages.xsd" xmlns:mssext="http://jlrint.com/mss/message/crmcreateorupdateleadandprospect/2" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'
	SET @NVC_FileBottom = '</mssext:createOrUpdateLeadAndProspectBatch>'
		
	SET @NVC_OUTPUT = @NVC_FileTop + @NVC_BatchHeader + @NVC_BatchBody + @NVC_FileBottom

	SELECT @NVC_OUTPUT  AS XML_COL

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

