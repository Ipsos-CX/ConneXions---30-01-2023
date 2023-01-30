CREATE PROCEDURE [CRM].[uspCalculateOutputBatches] 
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
		Purpose:	Calculates batches of CaseIDs for output to CRM
		
		Version		Date				Developer			Comment
LIVE	1.0			20/08/2015			Chris Ross			Created
LIVE	1.1			05/07/2015			Chris Ross			BUG 12777 - Additional code to include Unsubscribes
LIVE	1.2			12/07/2016			Chris Ross			BUG 12777 - Additional code to include Bouncebacks
LIVE	1.3			28/09/2016			Chris Ross			BUG 13081 - Split batches by new column NSCRef (keep them sequential by file)
LIVE	1.4			07/11/2016			Chris Ross			BUG 13302 - Write any missing reference table lookups to the CRM Output Errors table
																		and remove the Cases from the output.
LIVE	1.5			10/02/2017			Chris Ross			BUG 13424 - Pre-Check output fields and remove any Cases where size limits are exceeded.
																		Record these and ensure that they are not selected in future.  This 
																		is temporary funtionality until we have a solution to oversized field values.
LIVE	1.6			16/02/2017			Chris Ross			BUG 13567 - Remove check on OrgName size of 40, as we are now splitting this over two columns
																		Also, allow MENA names of over 40 chars to get through.
LIVE	1.7			03/05/2017			Chris Ross			Fix to remove Error records for any Cases being processed, prior to error checks being processed
															this in effect means we only have records we have been unable to output in the errors table, it also
															stops the system erroring as we are not trying to insert the sames CaseID more than once.
LIVE	1.8			10/05/2017			Chris Ross			BUG 13907 - Add in code to check CampaignIDs present in originating CRM data as well as	CRM.XMLOutputValues_MarketQuestionnaire table.
LIVE	1.9			07/06/2017			Chris Ross			Increased the Manufacturer column size to 510 due to very strange bug caused by truncation even though the MAX len is only 10 chars.
LIVE	1.10		24/08/2017			Chris Ross			BUG14205 - Verify that all records actually got through into the check temp file #T_CampaignResponsesCustomerInfo. Error, if not.
																		Change lookup on CRM.XMLOutputValues_MarketQuestionnaire to LEFT join as per CRM.uspOutputXMLForBatch
																		Add in ISNULLs on the LEN comparison checks so that NULLs don't cause rec's to drop out of test.
LIVE	1.11		11/10/2017			Chris Ross			BUG 14299 - Additional checks to ensure Red Flag and Gold star not supplied at the same time and also that no AnonymityManufacturer has not been set.
LIVE	1.12		05/12/2017			Chris Ledger		BUG 13373 - Add PreOwned
LIVE	1.13		29/01/2018			Chris Ross			BUG 14506 - Add in constraints to ensure we only retrieve the CRM staging records associated with the PartyID used in the Event or CaseID
LIVE	1.14		28/02/2018			Chris Ross			BUG 14506 - Removed filter on UncodedDealer from the additional AuditItemID lookup as not required.
LIVE	1.15		22/03/2018			Chris Ross			BUG 14413 - Ignore "Sent" statuses when testing for Anonymity flag set on outgoing status rows. 
LIVE	1.16		19/04/2018			Chris Ledger		BUG 14621 - Check for Cross-Border Cases (i.e. Country of Market different to Country of Case).
LIVE	1.17		06/07/2018			Chris Ross			BUG 14741 - Update Unsubscribe/Permissions code to match uspOutputXMLForBatch.
LIVE	1.18		02/08/2018			Chris Ledger		BUG 14890 - Only Check "Completed" statuses when testing for Anonymity flag set on outgoing status rows.  
LIVE	1.19		21/08/2018			Chris Ross			BUG 14941 - Bug clear down step moved before the Cross-border check to prevent dupe errors.
LIVE	1.20		23/11/2018			Chris Ross			BUG 15118 - Add in Dealer Code column code 
LIVE	1.21		05/12/2018			Chris Ross			BUG 15149 - Update check on CampaignID as only applies to CaseID and not EventID outputs.
LIVE	1.22		19/03/2019			Chris Ross			BUG 15234 - Update CRM and Organisation columns and queries to match uspOutputXMLForBatch.
LIVE	1.23		29/10/2019			Chris Ledger		BUG 15490 - Add PreOwned LostLeads
LIVE	1.25		15/01/2020			Chris Ledger		BUG 15372 - Fix Hard coded references to databases
LIVE	1.26        18/02/2021          Chris Ledger        BUG 18110 - SV-CRM Feed Changes
LIVE	1.27		25/03/2021			Chris Ledger		TASK 299 - Add General Enquiry
LIVE	1.28		21/04/2021			Chris Ledger		TASK 400 - Amend AccountType setting Organization to Individual and change ACCT_ACCT_TYPE values from Individual to Person
LIVE	1.29		01/06/2021			Chris Ledger		TASK 411 - Add CQI
LIVE	1.30		10/06/2021			Chris Ledger		TASK 467 - Exclude records without matching CRM data
LIVE	1.31		10/06/2021			Chris Ledger		TASK 451 - Pre-Check output fields and remove any Events where size limits are exceeded
LIVE	1.32		17/06/2021			Chris Ledger		TASK 505 - Stop checking for missing XMLOutputValues_MarketQuestionnaire record
LIVE	1.33		17/06/2021			Chris Ledger		TASK 505 - Stop using XMLOutputValues_MarketQuestionnaire to get CmpgnID
LIVE	1.34		23/08/2021			Chris Ledger		TASK 567 - Add LostLeads
LIVE	1.35		21/09/2021			Chris Ledger		TASK 604 - Set CountryID to sampled CountryID for NCSRef
LIVE	1.36		05/10/2021			Chris Ledger		TASK 604 - Exclude from NCSRef records with EventID = 0 and CaseID = 0
LIVE	1.37		15/10/2021			Chris Ledger		TASK 604 - Tidy up #CasesWithNSCRef update query to speed up LOAD
LIVE	1.38		14/01/2022			Chris Ledger		TASK 755 - Set NSCRef based on country of market
LIVE	1.39		08/06/2022			Ben King			TASK 881 - Land Rover Experience - Selection Feedback SVCRM
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
	-- V1.37 Populate the pre-pass table
	----------------------------------------------------
	INSERT INTO #CasesWithNSCRef (CaseID, EventID)
	SELECT DISTINCT CaseID,											-- V1.1
		EventID														-- V1.1
	FROM CRM.CaseResponseStatuses CRT
	WHERE OutputToCRMDate IS NULL
		AND (CRT.CaseID <> 0 OR CRT.EventID <> 0)
		AND NOT EXISTS (	SELECT RHB.CaseID, 
								RHB.EventID 
							FROM CRM.ResponsesHeldBackDueToSizeLimits RHB 
							WHERE RHB.CaseID = CRT.CaseID
								AND RHB.EventID = CRT.EventID )		-- V1.5
	
	UPDATE C 
	SET C.NSCRef = M.NSCRef,
		C.CountryID = SL.CountryID			-- V1.35
	FROM #CasesWithNSCRef C
		INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL ON C.CaseID = SL.CaseID				-- V1.35
		LEFT JOIN CRM.XMLOutputValues_Market M ON M.CountryID = SL.CountryID											-- V1.35
	WHERE C.CaseID <> 0 	
	
	UPDATE C 
	SET C.NSCRef = M.NSCRef,
		C.CountryID = SL.CountryID
	FROM #CasesWithNSCRef C
		INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL ON SL.MatchedODSEventID = C.EventID
		LEFT JOIN CRM.XMLOutputValues_Market M ON M.CountryID = SL.CountryID		
	WHERE  C.CaseID = 0
		AND C.EventID <> 0					-- V1.36
	


	---------------------------------------------------------------------------------------------------------------------------------------------
	-- Remove any existing errors for the cases we are about to output.  We then add anew if an error still persists.      -- V1.7 -- V1.19
	---------------------------------------------------------------------------------------------------------------------------------------------
	DELETE FROM OE
	FROM #CasesWithNSCRef N
		INNER JOIN CRM.OutputErrors OE ON OE.CaseID = N.CaseID	
	WHERE N.EventID = 0	

	DELETE FROM OE
	FROM #CasesWithNSCRef N
		INNER JOIN CRM.OutputErrors OE ON OE.EventID = N.EventID	
	WHERE N.EventID <> 0	

	

	------------------------------------------------------------------------------------------------------------------------------------
	---- Check for Cross-Border Cases (i.e. Country of Market different to Country of Case) -- V1.16
	------------------------------------------------------------------------------------------------------------------------------------
	INSERT INTO CRM.OutputErrors (CaseID, EventID, AttemptedOutputDate, ErrorDescription)
	SELECT DISTINCT N.CaseID, 
		N.EventID, 
		@SysDate AS AttemptedOutputDate, 
		'Sampled market CountryID: ' + CAST(ISNULL(M.CountryID,0) AS VARCHAR(5)) + ' does not match NSCRef CountryID: ' + CAST(ISNULL(N.CountryID,0) AS VARCHAR(5)) AS ErrorDescription
	FROM #CasesWithNSCRef N
		LEFT JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL ON SL.CaseID = N.CaseID
		LEFT JOIN [$(SampleDB)].dbo.Markets M ON SL.Market = M.Market
		LEFT JOIN [$(SampleDB)].ContactMechanism.Countries C ON N.CountryID = C.CountryID
	WHERE N.CaseID <> 0
		AND ISNULL(M.CountryID,0) <> ISNULL(N.CountryID,0)

	DELETE FROM N
	FROM #CasesWithNSCRef N
		LEFT JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL ON SL.CaseID = N.CaseID
		LEFT JOIN [$(SampleDB)].dbo.Markets M ON SL.Market = M.Market
		LEFT JOIN [$(SampleDB)].ContactMechanism.Countries C ON N.CountryID = C.CountryID
	WHERE N.CaseID <> 0
		AND ISNULL(M.CountryID,0) <> ISNULL(N.CountryID,0)
	
	

	---------------------------------------------------------------------------------------------------------------------------------------------
	-- Check for missing  XMLOutputValues_Market record (NSCRef lookup) and save to Missing Ref table for email alert output  -- V1.4 -- V1.16 MOVED
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
	-- Pre-Check output fields and remove any Cases where size limits are exceeded. (Code cribbed from OutputXMLforBatch proc.)	--  V1.5
	----------------------------------------------------------------------------------------------------------------------------------

	DROP TABLE IF EXISTS #T_AllCases

	CREATE TABLE #T_AllCases
	(
		CaseID		BIGINT,
		EventID		BIGINT,
		NSCRef		NVARCHAR(255)						-- V1.38	
	)

	INSERT INTO #T_AllCases (CaseID, EventID, NSCRef)	-- V1.38
	SELECT CaseID, 
		EventID,
		NSCRef											-- V1.38
	FROM #CasesWithNSCRef



	-------------------------------------------------------------------------------------------------------------------
	-- We run the same code as the output XML output proc to build up the output values so we can check field sizes.
	-- This code is big and really should only be in one place and run once per output.  I have created bug 13867 to 
	-- address this.
	--
	-- The following code is taken from [CRM].[uspOutputXMLForBatch] proc.
	-------------------------------------------------------------------------------------------------------------------

	--- Get the latest AuditItemID for the CaseIDs and EventIDs provided ------------------------------------------------------------------------
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
																					AND AC.CaseID <> 0 
		INNER JOIN [$(SampleDB)].Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = SL.CaseID				-- V1.13 - Link to ensure we only bring back the AuditItemIDs relevant to the actual selected party
																			AND AEBI.PartyID = COALESCE(NULLIF(MatchedODSPersonID, 0), NULLIF(MatchedODSOrganisationID, 0), NULLIF(MatchedODSPartyID, 0)) 
	GROUP BY SL.MatchedODSEventID
	UNION 
	SELECT SL.MatchedODSEventID AS EventID, 
		MAX(SL.AuditItemID) AS AuditItemID
	FROM #T_AllCases AC
		INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL ON SL.MatchedODSEventID = AC.EventID 
																					AND AC.CaseID = 0				-- V1.19
		INNER JOIN [$(SampleDB)].Meta.vwVehicleEvents VE ON VE.EventID = SL.MatchedODSEventID						-- V1.13 - Link to ensure we only bring back the AuditItemIDs relevant to the actual selected party
															AND VE.PartyID = COALESCE(NULLIF(MatchedODSPersonID, 0), NULLIF(MatchedODSOrganisationID, 0), NULLIF(MatchedODSPartyID, 0)) 
	GROUP BY SL.MatchedODSEventID


	-- Now pick up any UncodedDealer Recs as they won't have an entry in Meta.vwVehicleEvents table   -- V1.13 
	-- (We will leave any other type recs to error further down - so we can see if there are any other issues)
	INSERT INTO #T_LatestAuditItemIDForEvent (EventID, AuditItemID)
	SELECT SL.MatchedODSEventID AS EventID, 
		MAX(SL.AuditItemID) AS AuditItemID
	FROM #T_AllCases AC
		INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL ON SL.MatchedODSEventID = AC.EventID 
																					AND AC.CaseID = 0				-- V1.19
																					-- AND SL.UncodedDealer = 1 	-- V1.14 
	WHERE EventID NOT IN (SELECT EventID FROM #T_LatestAuditItemIDForEvent)
	GROUP BY  SL.MatchedODSEventID

							
							
	/* V1.26 Not collected now
	--  Get any postal address updates ----------------------------------------------------------------------------------
	DROP TABLE IF EXISTS #T_AddressUpdates

	CREATE TABLE #T_AddressUpdates
	(
		CaseID				BIGINT,			
		EventID				BIGINT,
		DateProcessed		DATETIME2,
		StreetNumber		NVARCHAR(400),
		BuildingName		NVARCHAR(400),
		SubStreet		    NVARCHAR(400),
		Street				NVARCHAR(400),
		SubLocality			NVARCHAR(400),
		Locality			NVARCHAR(400),
		Town				NVARCHAR(400),
		Region				NVARCHAR(400),
		PostCode			NVARCHAR(60),
		Country			    NVARCHAR(200)
	)
					
	INSERT INTO #T_AddressUpdates (
		CaseID,
		EventID,
		DateProcessed,
		StreetNumber,
		BuildingName,
		SubStreet,
		Street,
		SubLocality,
		Locality,
		Town,
		Region,
		PostCode,
		Country							
	)
	SELECT	CD.CaseID,
		AC.EventID,
		CUPA.DateProcessed,			-- ???
		PA.StreetNumber,
		PA.BuildingName,
		LTRIM(PA.SubStreetNumber + '' + PA.SubStreet) AS SubStreet,
		PA.Street,
		PA.SubLocality,
		PA.Locality,
		PA.Town,	
		PA.Region,
		PA.PostCode,
		CL.Country		
	FROM #T_AllCases AC
		INNER JOIN [$(SampleDB)].Meta.CaseDetails CD ON AC.CaseID = CD.CaseID
		INNER JOIN [$(AuditDB)].Audit.CustomerUpdate_PostalAddress CUPA ON CUPA.CaseID = CD.CaseID
																		AND CUPA.DateProcessed IS NOT NULL				-- Include only current
																		AND CUPA.CasePartyCombinationValid = 1
		INNER JOIN [$(SampleDB)].ContactMechanism.PostalAddresses PA ON PA.ContactMechanismID = CUPA.ContactMechanismID 
		INNER JOIN [$(SampleDB)].dbo.Markets M ON M.CountryID = PA.CountryID											-- V1.7 
		INNER JOIN [$(SampleDB)].dbo.Regions R ON R.RegionID = M.RegionID AND R.Region <> 'MENA'						-- V1.7 Filter out MENA addresses
		INNER JOIN [$(SampleDB)].ContactMechanism.Countries C ON C.CountryID = PA.CountryID									
		INNER JOIN CRM.CountryLookup CL ON CL.ISOAlpha2 = C.ISOAlpha2 --  <<<< Country name needs to match the list provided by JLR (e.g. Russia NOT Russian Federation)
	WHERE AC.CaseID <> 0				-- V1.19
	*/

					

	/* V1.26 Not collected now
	-- Get any email address updates ----------------------------------------------------------------------------------
	DROP TABLE IF EXISTS #T_EmailUpdates

	CREATE TABLE #T_EmailUpdates
	(
		CaseID				BIGINT,			
		EventID				BIGINT,
		EmailAddr			NVARCHAR(510)
	)
						
						
	INSERT INTO #T_EmailUpdates (CaseID, EventID, EmailAddr)
	SELECT	CD.CaseID,
		AC.EventID,						-- V1.19
		EA.EmailAddress	AS EmailAddr
	FROM #T_AllCases AC
		INNER JOIN [$(SampleDB)].Meta.CaseDetails CD ON AC.CaseID = CD.CaseID
		INNER JOIN [$(AuditDB)].Audit.CustomerUpdate_EmailAddress CUEA ON CUEA.CaseID = CD.CaseID
																		AND CUEA.DateProcessed IS NOT NULL				--- Include only current
																		AND CUEA.CasePartyCombinationValid = 1
		INNER JOIN [$(SampleDB)].ContactMechanism.EmailAddresses EA ON EA.ContactMechanismID = CUEA.ContactMechanismID 
	WHERE AC.CaseID <> 0			-- V1.19
	*/


					
	--  Get any bouncebacks  ----------------------------------------------------------------------------------			
	DROP TABLE IF EXISTS #T_BounceBacks

	CREATE TABLE #T_BounceBacks
	(
		CaseID		BIGINT,			
		EmailAddr	NVARCHAR(510),
		HrdBncCntr	INT,
		SftBncCntr	INT
	)
						
	INSERT INTO #T_BounceBacks (
		CaseID,
		EmailAddr,
		HrdBncCntr,
		SftBncCntr
	)
	SELECT	CD.CaseID,
		CUCO.EmailAddress AS EmailAddr,
		CASE	WHEN CUCO.OutcomeCode IN (	SELECT OutcomeCode 
											FROM [$(SampleDB)].ContactMechanism.OutcomeCodes OC
											WHERE ISNULL(OC.HardBounce, 0) = 1 ) THEN 1 
				ELSE NULL END AS HrdBncCntr,
		CASE	WHEN CUCO.OutcomeCode IN (	SELECT OutcomeCode 
											FROM [$(SampleDB)].ContactMechanism.OutcomeCodes OC
											WHERE ISNULL(OC.SoftBounce, 0) = 1) THEN 1 
				ELSE NULL END AS SftBncCntr
	FROM #T_AllCases AC
		INNER JOIN [$(SampleDB)].Meta.CaseDetails CD ON AC.CaseID = CD.CaseID
		INNER JOIN [$(AuditDB)].Audit.CustomerUpdate_ContactOutcome CUCO ON CUCO.CaseID = CD.CaseID
																	AND CUCO.DateProcessed IS NOT NULL				--- Include only current
																	AND CUCO.DateProcessed > '2016-12-01'			--  V1.6 - Filter out old pre-3.0 release updates
																	AND CUCO.OutcomeCode IN (	SELECT OC.OutcomeCode 
																								FROM [$(SampleDB)].ContactMechanism.OutcomeCodes OC
																								WHERE ISNULL(OC.HardBounce, 0) = 1 
																									OR ISNULL(OC.SoftBounce, 0) = 1 )
																	AND CUCO.AuditItemID = (	SELECT MAX(AuditItemID)				-- V1.6b - Only use the latest supplied bounceback record 
																								FROM [$(AuditDB)].Audit.CustomerUpdate_ContactOutcome CUCO2
																								WHERE CUCO2.CaseID = CUCO.CaseID 
																									AND CUCO2.DateProcessed IS NOT NULL
																									AND CUCO2.OutcomeCode IN (	SELECT OC.OutcomeCode 
																																FROM [$(SampleDB)].ContactMechanism.OutcomeCodes OC
																																WHERE ISNULL(OC.HardBounce, 0) = 1 
																																	OR ISNULL(OC.SoftBounce, 0) = 1 ) )
		INNER JOIN [$(SampleDB)].Party.Organisations O ON O.PartyID = CD.ManufacturerPartyID
	WHERE AC.CaseID <> 0				-- V1.19



	/* V1.26 Not collected now
	--  Get any Person Updates ----------------------------------------------------------------------------------
	DROP TABLE IF EXISTS #T_PersonUpdates

	CREATE TABLE #T_PersonUpdates
	(
		CaseID		BIGINT,			
		Ttl			NVARCHAR(200),
		AuditItemID	BIGINT
	)
						
	INSERT INTO #T_PersonUpdates (CaseID, Ttl, AuditItemID)
	SELECT	CD.CaseID,
		CD.Title AS Ttl,
		CUPA.AuditItemID				-- Added in AuditItemID in case Person Updates supplied more than once for the Case (shouldn't happen but possible) 
	FROM #T_AllCases AC
		INNER JOIN [$(SampleDB)].Meta.CaseDetails CD ON AC.CaseID = CD.CaseID
		INNER JOIN [$(AuditDB)].Audit.CustomerUpdate_Person CUPA ON CUPA.CaseID = CD.CaseID
																	AND CUPA.DateProcessed IS NOT NULL				-- Include only current
																	AND CUPA.CasePartyCombinationValid = 1
	WHERE AC.CaseID <> 0				-- V1.19
	*/



	/* V1.26 Not collected now
	-- Get any Registration Updates ----------------------------------------------------------------------------------
	DROP TABLE IF EXISTS #T_RegistrationUpdates

	CREATE TABLE #T_RegistrationUpdates
	(
		CaseID	BIGINT,			
		RegNum	NVARCHAR(100)
	)
						
	INSERT INTO #T_RegistrationUpdates (CaseID, RegNum)
	SELECT	AC.CaseID,
		CURN.RegNumber AS RegNum
	FROM #T_AllCases AC
		INNER JOIN [$(SampleDB)].Meta.CaseDetails CD ON AC.CaseID = CD.CaseID
		INNER JOIN [$(AuditDB)].Audit.CustomerUpdate_RegistrationNumber CURN ON CURN.CaseID = CD.CaseID
																				AND CURN.DateProcessed IS NOT NULL				-- Include only current
	WHERE AC.CaseID <> 0 -- V1.19
	*/


	/* V1.26 Not collected now
	-- Get any associated Red Flag / Gold Star response -- V1.14 ----------------------------------------------------------
	DROP TABLE IF EXISTS #T_SurveyFlags

	CREATE TABLE #T_SurveyFlags
	(
		CaseID			BIGINT,			
		FlgTyp			NVARCHAR(100),
		ResponseDate	DATETIME
	)
		
	INSERT INTO #T_SurveyFlags (CaseID, FlgTyp, ResponseDate)
	SELECT	AC.CaseID,
		CASE	WHEN CC.RedFlag = 1 THEN 'Red Flag' 
				WHEN CC.GoldFlag = 1 THEN 'Gold Star'
				ELSE 'Error: Unknown' END AS FlgTyp,
		CC.ResponseDate
	FROM #T_AllCases AC
		INNER JOIN [$(SampleDB)].Event.CaseCRM CC ON CC.CaseID = AC.CaseID
	WHERE AC.CaseID <> 0
		AND (   ISNULL(CC.RedFlag, 0) = 1
			OR  ISNULL(CC.GoldFlag, 0) = 1 )	
	*/



	-- Get any associated CRM data  ----------------------------------------------------------------------------------
	DROP TABLE IF EXISTS #T_CRM_Data

	CREATE TABLE #T_CRM_Data
	(
		EventID					BIGINT,
		AuditItemID				BIGINT,
		RESPONSE_ID				NVARCHAR(20),
		CAMPAIGN_CAMPAIGN_ID	NVARCHAR(100),
		ACCT_ACCT_ID			NVARCHAR(20),
		ACCT_ACCT_TYPE			NVARCHAR(60)		-- V1.22
	)
						
	INSERT INTO #T_CRM_Data (
		EventID,
		AuditItemID,
		RESPONSE_ID,
		CAMPAIGN_CAMPAIGN_ID,
		ACCT_ACCT_ID, 
		ACCT_ACCT_TYPE								-- V1.22									
	)
	SELECT LE.EventID,
		LE.AuditItemID,
		C.RESPONSE_ID,
		C.CAMPAIGN_CAMPAIGN_ID,
		C.ACCT_ACCT_ID,
		C.ACCT_ACCT_TYPE							-- V1.22
	FROM  #T_LatestAuditItemIDForEvent LE 
		INNER JOIN [$(ETLDB)].CRM.Vista_Contract_Sales C ON C.AuditItemID = LE.AuditItemID
	UNION 
	SELECT LE2.EventID,
		LE2.AuditItemID,
		C2.RESPONSE_ID,
		C2.CAMPAIGN_CAMPAIGN_ID,
		C2.ACCT_ACCT_ID ,
		C2.ACCT_ACCT_TYPE							-- V1.22
	FROM  #T_LatestAuditItemIDForEvent LE2 
		INNER JOIN [$(ETLDB)].CRM.CRCCall_Call C2 ON C2.AuditItemID = LE2.AuditItemID
	UNION 
	SELECT LE3.EventID,
		LE3.AuditItemID,
		C3.RESPONSE_ID,
		C3.CAMPAIGN_CAMPAIGN_ID,
		C3.ACCT_ACCT_ID,
		C3.ACCT_ACCT_TYPE							-- V1.22  
	FROM  #T_LatestAuditItemIDForEvent LE3 
		INNER JOIN [$(ETLDB)].CRM.DMS_Repair_Service C3 ON C3.AuditItemID = LE3.AuditItemID
	UNION 
	SELECT	LE4.EventID,
		LE4.AuditItemID,
		C4.RESPONSE_ID,
		C4.CAMPAIGN_CAMPAIGN_ID,
		C4.ACCT_ACCT_ID,
		C4.ACCT_ACCT_TYPE							-- V1.22 
	FROM #T_LatestAuditItemIDForEvent LE4 
		INNER JOIN [$(ETLDB)].CRM.RoadsideIncident_Roadside C4 ON C4.AuditItemID = LE4.AuditItemID
	UNION 
	SELECT	LE5.EventID,
		LE5.AuditItemID,
		C5.RESPONSE_ID,
		C5.CAMPAIGN_CAMPAIGN_ID,
		C5.ACCT_ACCT_ID,
		C5.ACCT_ACCT_TYPE							-- V1.22 
	FROM #T_LatestAuditItemIDForEvent LE5 
		INNER JOIN [$(ETLDB)].CRM.PreOwned C5 ON C5.AuditItemID = LE5.AuditItemID	
	UNION 
	SELECT	LE6.EventID,
		LE6.AuditItemID,
		C6.RESPONSE_ID,
		C6.CAMPAIGN_CAMPAIGN_ID,
		C6.ACCT_ACCT_ID,
		C6.ACCT_ACCT_TYPE							-- V1.27 
	FROM #T_LatestAuditItemIDForEvent LE6 
		INNER JOIN [$(ETLDB)].CRM.General_Enquiry C6 ON C6.AuditItemID = LE6.AuditItemID	
	UNION 
	SELECT	LE7.EventID,
		LE7.AuditItemID,
		C7.RESPONSE_ID,
		C7.CAMPAIGN_CAMPAIGN_ID,
		C7.ACCT_ACCT_ID,
		C7.ACCT_ACCT_TYPE							-- V1.29 
	FROM #T_LatestAuditItemIDForEvent LE7 
		INNER JOIN [$(ETLDB)].CRM.CQI C7 ON C7.AuditItemID = LE7.AuditItemID
	UNION 
	SELECT	LE8.EventID,
		LE8.AuditItemID,
		C8.RESPONSE_ID,
		C8.CAMPAIGN_CAMPAIGN_ID,
		C8.ACCT_ACCT_ID,
		C8.ACCT_ACCT_TYPE							-- V1.34
	FROM #T_LatestAuditItemIDForEvent LE8 
		INNER JOIN [$(ETLDB)].CRM.Lost_Leads C8 ON C8.AuditItemID = LE8.AuditItemID
	UNION 
	SELECT	LE9.EventID,
		LE9.AuditItemID,
		C9.RESPONSE_ID,
		C9.CAMPAIGN_CAMPAIGN_ID,
		C9.ACCT_ACCT_ID,
		C9.ACCT_ACCT_TYPE							-- V1.39
	FROM #T_LatestAuditItemIDForEvent LE9 
		INNER JOIN [$(ETLDB)].CRM.LandRover_Experience C9 ON C9.AuditItemID = LE9.AuditItemID
			
	-- Add an index to speed up access later on 
	CREATE INDEX IDX_T_CRM_Data ON #T_CRM_Data (EventID)
	INCLUDE (
		AuditItemID,
		RESPONSE_ID,
		CAMPAIGN_CAMPAIGN_ID,
		ACCT_ACCT_ID,
		ACCT_ACCT_TYPE								-- V1.22				
	)
	

						
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
		NSCRef					NVARCHAR(255)			-- V1.38		
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
		NSCRef											-- V1.38
	)
	SELECT AC.CaseID,
		AC.EventID,																-- Keep key value (zero) for matching back to CaseResponseStatuses table ETC.
		CASE	WHEN CRM.ACCT_ACCT_TYPE = 'Person' THEN NULL					-- V1.28
				ELSE CD.OrganisationPartyID	END AS OrganisationPartyID,			-- V1.22
		CD.PartyID,
		CD.ManufacturerPartyID,
		CD.FirstName,
		CD.LastName,
		CD.SecondLastName,
		CASE	WHEN CRM.ACCT_ACCT_TYPE = 'Person' THEN NULL					-- V1.28
				ELSE CD.OrganisationName END AS OrganisationName,				-- V1.22
		CD.EventTypeID,
		CD.CountryID,
		CD.CountryISOAlpha2,
		CD.Country,
		CD.EventID AS ODSEventID,
		AC.NSCRef																-- V1.38
	FROM #T_AllCases AC 
		LEFT JOIN [$(SampleDB)].Meta.CaseDetails CD ON CD.CaseID = AC.CaseID  
		LEFT JOIN #T_CRM_Data CRM ON CRM.EventID = CD.EventID					-- V1.22
	WHERE AC.CaseID <> 0														-- V1.19
	UNION
	SELECT AC.CaseID,
		AC.EventID,
		CASE	WHEN CRM.ACCT_ACCT_TYPE = 'Person' THEN NULL																	-- V1.28 
				ELSE NULLIF(SL.MatchedODSOrganisationID, 0) END AS OrganisationPartyID,											-- V1.22
		COALESCE(NULLIF(SL.MatchedODSPersonID, 0), NULLIF(SL.MatchedODSOrganisationID, 0), SL.MatchedODSPartyID ) AS PartyID,
		SL.ManufacturerID,
		P.FirstName,
		P.LastName, 
		P.SecondLastName,
		CASE	WHEN CRM.ACCT_ACCT_TYPE = 'Person' THEN NULL					-- V1.28
				ELSE O.OrganisationName END AS OrganisationName,				-- V1.22
		SL.ODSEventTypeID,
		SL.CountryID,
		C.ISOAlpha2,
		C.Country,
		AC.EventID AS ODSEventID,
		AC.NSCRef																-- V1.38
	FROM #T_AllCases AC 
		LEFT JOIN #T_LatestAuditItemIDForEvent LAI ON LAI.EventID = AC.EventID 
		LEFT JOIN #T_CRM_Data CRM ON CRM.EventID = AC.EventID																	-- V1.22
		LEFT JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL ON SL.AuditItemID = LAI.AuditItemID
		LEFT JOIN [$(SampleDB)].Party.Organisations O ON O.PartyID = SL.MatchedODSOrganisationID
		LEFT JOIN [$(SampleDB)].Party.People P ON P.PartyID = SL.MatchedODSPersonID 
		LEFT JOIN [$(SampleDB)].ContactMechanism.Countries C ON C.CountryID = SL.CountryID
	WHERE AC.CaseID = 0															-- V1.19




	---- TEMP fix to set the Org PartyID to NULL, if the PartyID is actually a person
	UPDATE CB															--  <<<<<<<<<<<<<<<<<<<<<<<<<<< TEMP - TO BE REMOVED ONCE CASEDETAILS PROC IS CORRECTED <<<<<<<<<<<<<<<<<<<<<<<<
	SET CB.OrganisationPartyID = NULL
	FROM #T_CollatedCommonBaseData CB
		INNER JOIN [$(SampleDB)].Party.People P ON P.PartyID = CB.OrganisationPartyID   	



	--  Get the permissions ----------------------------------------------------------------------------------  V1.17
	DROP TABLE IF EXISTS #T_Permissions

	CREATE TABLE #T_Permissions
	(
		CaseID				BIGINT,			
		PrmssnSupprType		NVARCHAR(700),
		DtOfCnsnt			DATETIME2,
		Cnsnt				NVARCHAR(10),
		FrmOfCnsnt			NVARCHAR(30)
	)

	;WITH CTE_Unsubscribes	AS 
	(	
		SELECT DISTINCT																											-- V1.6b Added DISTINCT 
			CD.CaseID,
			O.OrganisationName,
			CUCO.DateProcessed AS DtOfCnsnt,
			'No' AS Cnsnt
		FROM #T_AllCases AC
			INNER JOIN [$(SampleDB)].Meta.CaseDetails CD ON AC.CaseID = CD.CaseID
			INNER JOIN [$(AuditDB)].Audit.CustomerUpdate_ContactOutcome CUCO ON CUCO.CaseID = CD.CaseID
																				AND CUCO.DateProcessed IS NOT NULL				-- Include only current
																				AND CUCO.DateProcessed > '2016-12-01'			-- V1.6 - Filter out old pre-3.0 release updates
																				AND CUCO.OutcomeCode = 90 
			INNER JOIN [$(SampleDB)].Party.Organisations O ON O.PartyID = CD.ManufacturerPartyID
		WHERE AC.CaseID <> 0																									-- V1.19
	)
	, CTE_OutputTypes AS 
	(
		SELECT	U.CaseID, 
			CASE CT.CaseOutputType	WHEN 'Postal' THEN 'Post' 
									WHEN 'Online' THEN 'Email'
									WHEN 'CATI'   THEN 'Phone'
									WHEN 'SMS'    THEN 'SMS'
									ELSE 'Unknown' END AS FrmOfCnsnt,
			ROW_NUMBER() OVER (PARTITION BY U.CaseID ORDER BY CO.AuditItemID DESC) AS RowID
		FROM CTE_Unsubscribes U
			INNER JOIN [$(SampleDB)].Event.CaseOutput CO ON CO.CaseID = U.CaseID
			INNER JOIN [$(SampleDB)].Event.CaseOutputTypes CT ON CT.CaseOutputTypeID = CO.CaseOutputTypeID
	)
	INSERT INTO #T_Permissions  
	(
		CaseID,
		PrmssnSupprType,
		DtOfCnsnt,
		Cnsnt,
		FrmOfCnsnt
	)
	SELECT CU.CaseID,
		CU.OrganisationName + ' E-mail' AS PrmssnSupprType,
		CU.DtOfCnsnt,
		CU.Cnsnt,
		COP.FrmOfCnsnt
	FROM CTE_Unsubscribes CU
		INNER JOIN CTE_OutputTypes COP ON CU.CaseID = COP.CaseID 
											AND RowID = 1
	UNION
	SELECT CU.CaseID,
		CU.OrganisationName + ' Telephone' AS PrmssnSupprType,
		CU.DtOfCnsnt,
		CU.Cnsnt,
		COP.FrmOfCnsnt
	FROM CTE_Unsubscribes CU
		INNER JOIN CTE_OutputTypes COP ON CU.CaseID = COP.CaseID 
											AND RowID = 1
	UNION
	SELECT	CU.CaseID,
		CU.OrganisationName + ' SMS' AS PrmssnSupprType,
		CU.DtOfCnsnt,
		CU.Cnsnt,
		COP.FrmOfCnsnt
	FROM CTE_Unsubscribes CU
		INNER JOIN CTE_OutputTypes COP ON CU.CaseID = COP.CaseID 
											AND RowID = 1
	UNION
	SELECT	CU.CaseID,
		CU.OrganisationName + ' Post' AS PrmssnSupprType,
		CU.DtOfCnsnt,
		CU.Cnsnt,
		COP.FrmOfCnsnt
	FROM CTE_Unsubscribes CU
		INNER JOIN CTE_OutputTypes COP ON CU.CaseID = COP.CaseID 
											AND RowID = 1

	

	--  Create common base data for both Event and Case derived data ----------------------------------------------------------------------
	DROP TABLE IF EXISTS #T_CampaignResponsesCustomerInfo

	CREATE TABLE #T_CampaignResponsesCustomerInfo
	(
		CaseID					BIGINT,
		EventID					BIGINT,	
		PartyID					BIGINT,
		OrganisationPartyID		BIGINT,
		RspnseID				NVARCHAR(20),
		Status					NVARCHAR(50),				-- CGR
		ResponseStatusID		INT,						-- CGR - for Auditing
		LoadedToConnexions		DATETIME2,					-- CGR - for Auditing
		CmpgnID					NVARCHAR(255),
		NSCRef					NVARCHAR(255),
		Manufacturer			VARCHAR(510),				-- V1.9
		Questionnaire			VARCHAR(255),
		Role					VARCHAR(255),
		FstNm					NVARCHAR(100),				
		LstNm					NVARCHAR(100),			
		AddLstNm				NVARCHAR(100),
		OrgName1				NVARCHAR(510),	
		OrgName2				NVARCHAR(510),	
		Cntry					VARCHAR(200),		
		ACCT_ACCT_ID			NVARCHAR(20),
		ACCT_ACCT_TYPE			NVARCHAR(60),				-- V1.22
		CRM_CustID_Individual	VARCHAR(60),				-- Updated in later step
		CRM_CustID_Organisation	VARCHAR(60),				-- Updated in later step
		CRMCustomer				CHAR(1),					-- Updated in later step
		ReturnIndividual		CHAR(1),					-- Updated in later step
		VsbltyStts				NVARCHAR(100),				-- V1.14
		DlrCd					VARCHAR(60)					-- V1.20
	)

	;WITH CTE_ResponseStatusOrdered AS				-- In case more than one status gets triggered at the same time we will take them in the precedence order set in the ResponseStatuses table
	(
		SELECT  ROW_NUMBER() OVER (PARTITION BY CBX.CaseID, CBX.EventID ORDER BY RS.Precedence) AS RowID,  
			CBX.CaseID, 
			CBX.EventID, 
			RS.ResponseStatusCRMOutputValue, 
			CRS.ResponseStatusID, 
			CRS.LoadedToConnexions
		FROM #T_CollatedCommonBaseData CBX
			INNER JOIN CRM.CaseResponseStatuses CRS ON CRS.CaseID = CBX.CaseID
														AND CRS.EventID = CBX.EventID
			INNER JOIN CRM.ResponseStatuses RS ON RS.ResponseStatusID = CRS.ResponseStatusID 
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
		ACCT_ACCT_TYPE,			-- V1.22
		VsbltyStts,				-- V1.14
		DlrCd					-- V1.20
	)
	SELECT	CB.CaseID,
		CB.EventID,
		CASE	WHEN CB.OrganisationPartyID IS NOT NULL AND CB.PartyID = CB.OrganisationPartyID THEN NULL 
				ELSE CB.PartyID END AS PartyID,
		CB.OrganisationPartyID,
		C.RESPONSE_ID AS RspnseID,
		RSO.ResponseStatusCRMOutputValue AS Status,				-- V1.19
		RSO.ResponseStatusID,									-- V1.19 - for Auditing
		RSO.LoadedToConnexions,									-- V1.19 - for Auditing
		CAMPAIGN_CAMPAIGN_ID AS CmpgnID,						-- V1.33
		--ISNULL(CASE	WHEN C.EventID IS NOT NULL THEN C.CAMPAIGN_CAMPAIGN_ID 
		--			ELSE MQ.CRMCampaignID END , '') AS CmpgnID,
		CB.NSCRef,												-- V1.38
		O.OrganisationName AS Manufacturer, 
		EC.EventCategory AS Questionnaire,
		CASE	WHEN EXISTS (	SELECT * 
								FROM [$(SampleDB)].Party.PartyClassifications PC 
									INNER JOIN [$(SampleDB)].Party.PartyTypes PT ON PT.PartyTypeID = PC.PartyTypeID
																			AND PT.PartyType = 'Vehicle Leasing Company'
								WHERE PC.PartyID = CB.OrganisationPartyID) THEN 'Fleet Account' 
				ELSE 'Account'	END AS Role,
		CASE	WHEN R.Region = 'MENA' THEN (SELECT FirstName FROM dbo.udfCRM_MENA_Format_Name(CB.FirstName, CB.LastName))				-- V1.8
				ELSE CB.FirstName END AS FstNm,				
		CASE	WHEN R.Region = 'MENA' THEN (SELECT LastName FROM dbo.udfCRM_MENA_Format_Name(CB.FirstName, CB.LastName)) 				-- V1.8
				ELSE CB.LastName END AS LstNm,
		NULLIF(CB.SecondLastName, '') AS AddLstNm,
		NULLIF((SELECT Column1 FROM dbo.udfSplitColumnIntoTwo(CB.OrganisationName, 40, 40)), '') AS OrgName1,					-- V1.8			
		NULLIF((SELECT Column2 FROM dbo.udfSplitColumnIntoTwo(CB.OrganisationName, 40, 40)), '') AS OrgName2,					-- V1.8		
		COALESCE(CCL.Country, CB.Country) AS Cntry,				-- V1.5		--<<<< Country name needs to match the list provided by JLR (e.g. Russia NOT Russian Federation)
		C.ACCT_ACCT_ID,											-- AccountID as supplied in sample
		C.ACCT_ACCT_TYPE,										-- Account Type as supplied in sample										-- V1.21 
		CASE	WHEN ISNULL(CSE.AnonymityDealer, 0) = 1 THEN 'JLR Only' 
				ELSE 'All' END AS VsbltyStts,					-- V1.14  (prev V1.13) - Note that only valid recs will get though to this proc, so we only need to check AnonymityDealer flag
		CASE	WHEN D.OutletCode IS NOT NULL AND B.Brand = 'Land Rover' THEN 'LR' + CB.CountryISOAlpha2 + D.OutletCode						-- V1.20 V1.26
				WHEN D.OutletCode IS NOT NULL AND B.Brand = 'Jaguar' THEN 'J' + CB.CountryISOAlpha2 + D.OutletCode							-- V1.26
				ELSE NULL END AS DlrCd
	FROM #T_CollatedCommonBaseData CB																										-- V1.19
		INNER JOIN [$(SampleDB)].Event.EventTypeCategories ETC ON ETC.EventTypeID = CB.EventTypeID
		INNER JOIN [$(SampleDB)].Event.EventCategories EC ON EC.EventCategoryID = ETC.EventCategoryID
		INNER JOIN [$(SampleDB)].Party.Organisations O ON O.PartyID = CB.ManufacturerPartyID 
		INNER JOIN [$(SampleDB)].dbo.Markets MKT ON MKT.CountryID = CB.CountryID															-- V1.8
		INNER JOIN [$(SampleDB)].dbo.Regions R ON R.RegionID = MKT.RegionID																	-- V1.8
		INNER JOIN [$(SampleDB)].dbo.Brands B ON B.ManufacturerPartyID = CB.ManufacturerPartyID 
		--INNER JOIN CRM.XMLOutputValues_Market M ON M.CountryID = CB.CountryID																-- V1.38
		--LEFT JOIN CRM.XMLOutputValues_MarketQuestionnaire MQ ON MQ.CountryID = CB.CountryID 
		--														AND MQ.EventCategoryID = ETC.EventCategoryID 
		--														AND MQ.BrandID = B.BrandID													-- V1.10 V1.33
		INNER JOIN CTE_ResponseStatusOrdered RSO ON RSO.CaseID = CB.CaseID 
													AND RSO.EventID = CB.EventID 
													AND RSO.RowID = 1  --CGR
		LEFT JOIN CRM.CountryLookup CCL ON CCL.ISOAlpha2 = CB.CountryISOAlpha2																-- V1.5
		LEFT JOIN #T_CRM_Data C ON C.EventID = CB.ODSEventID 
		LEFT JOIN [$(SampleDB)].Event.Cases CSE ON CSE.CaseID = CB.CaseID						-- V1.14
		LEFT JOIN [$(SampleDB)].Event.EventPartyRoles EPR ON EPR.EventID = CB.ODSEventID													-- V1.19
		LEFT JOIN [$(SampleDB)].dbo.DW_JLRCSPDealers D ON D.OutletPartyID = EPR.PartyID														-- V1.19
													AND D.OutletFunction = (CASE	WHEN EC.EventCategory = 'Service' THEN 'AfterSales' 
																					WHEN EC.EventCategory = 'LostLeads' THEN 'Sales'
																					WHEN EC.EventCategory = 'PreOwned LostLeads' THEN 'PreOwned'		-- V1.23
																					ELSE EC.EventCategory END)
							


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
					


	/* V1.28 Code updated
	--  Add in IDs and whether Individual/Org or CRM cust for output ----------------------------------------------------------------------------------
	UPDATE CI
	SET CI.CRM_CustID_Individual = COALESCE(NULLIF(CI.ACCT_ACCT_ID, ''), PCI.AcctID),					-- NOTE: the Organization and Individual Cust ID columns get COALESCED so OK to use ACCT_ACCT_ID as primary value on both.
		CI.CRM_CustID_Organisation = COALESCE(NULLIF(CI.ACCT_ACCT_ID, ''), OCI.AcctID),
		CI.CRMCustomer = CASE	WHEN ((ISNULL(CI.PartyID, 0) <> 0 AND ISNULL(PCI.AcctID, '') <> '' )	-- An indiviudal exists and an associated CRM ID is present - THEN IS A CRM CUSTOMER
									OR (ISNULL(CI.PartyID, 0) = 0 AND ISNULL(OCI.AcctID, '') <> '' )	-- OR: No individual exists and the Organization has a CRM ID present - THEN IS A CRM CUSTOMER
									OR NULLIF(CI.ACCT_ACCT_ID, '') IS NOT NULL	) THEN 'Y'				-- Or we have a CRM account ID present in the staging tables   -- V1.2
								ELSE 'N' END,
		CI.ReturnIndividual	= CASE	WHEN (ISNULL(CI.OrgName1, '') = '' 
										OR PCI.AcctID IS NOT NULL										-- When the organisation name is blank OR we have an CRM CustID for the individual OR ...
										OR CI.ACCT_ACCT_TYPE = 'Person' ) THEN 'Y'						-- OR when the customer was received via CRM as "Person", then we return highest level as Person -- V1.21
									ELSE 'N' END
	FROM #T_CampaignResponsesCustomerInfo CI
		LEFT JOIN #T_PersonCustomerID PCI ON PCI.PartyID = CI.PartyID
		LEFT JOIN #T_OrgCustomerID OCI ON OCI.PartyID = CI.OrganisationPartyID
	*/
	--  V1.28 Add in IDs and whether Individual/Org or CRM cust for output ----------------------------------------------------------------------------------
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



	/* V1.26 Not collected now
	-- Combine the Postal Addresses into a single temp table for lookup ----------------------------------------------------------------------------------
	DROP TABLE IF EXISTS #T_CustomerAddressCombined

	CREATE TABLE #T_CustomerAddressCombined
	(
		CaseID					BIGINT,
		EventID					BIGINT,
		StrtDt					DATETIME,
		POBox					NVARCHAR(1) DEFAULT '',
		PremNum					NVARCHAR(40),
		Prfx1					NVARCHAR(400),
		Prfx2					NVARCHAR(400),
		Street					NVARCHAR(400),
		Suppl1					NVARCHAR(400),
		Suppl2					NVARCHAR(400),
		Suppl3					NVARCHAR(1) DEFAULT '',
		CityTown				NVARCHAR(400),			--<<< See JLR feedback email (around) 01-06-2015 : note that out city/region data incorrect (mapping issues with JLR?)
		RegState				NVARCHAR(400),
		PostCdZIP				NVARCHAR(60),
		Cntry					NVARCHAR(200),
		CofName					NVARCHAR(1) DEFAULT '',
		City2					NVARCHAR(1) DEFAULT '',
		HomeCity				NVARCHAR(1) DEFAULT '',
		POBoxPostCode			NVARCHAR(1) DEFAULT '',
		CmpnyPostCode			NVARCHAR(1) DEFAULT '',
		CityPostCodeExt			NVARCHAR(1) DEFAULT '',
		POBoxPostCodeExt		NVARCHAR(1) DEFAULT '',
		MajCustPostCodeExt		NVARCHAR(1) DEFAULT '',
		POBoxCity				NVARCHAR(1) DEFAULT '',
		CityPOBoxCode			NVARCHAR(1) DEFAULT '',
		POBoxRegState			NVARCHAR(1) DEFAULT '',
		POBoxCntry				NVARCHAR(1) DEFAULT '',
		PremNum2				NVARCHAR(1) DEFAULT '',
		PremNumRange			NVARCHAR(1) DEFAULT '',
		Location				NVARCHAR(1) DEFAULT '',
		BldngFloor				NVARCHAR(1) DEFAULT '',
		RoomNo					NVARCHAR(1) DEFAULT '',
		County					NVARCHAR(1) DEFAULT '',
		Township				NVARCHAR(1) DEFAULT '',
		POBoxLobby				NVARCHAR(1) DEFAULT ''
	)
						
	;WITH CTE_NonCRM_CustomerAddress AS		-- CGRCGR -- Get the customer addresses for all Non-CRM ID records (where we haven't got a customer updated address either)
	(
		SELECT	CR.CaseID,
			CR.EventID,
			PA.StreetNumber,
			PA.BuildingName,
			LTRIM(PA.SubStreetNumber + '' + PA.SubStreet) AS SubStreet,
			PA.Street,
			PA.SubLocality,
			PA.Locality,
			PA.Town,		
			PA.Region,
			PA.PostCode,
			CL.Country				
		FROM #T_CampaignResponsesCustomerInfo CR
			INNER JOIN [$(SampleDB)].Meta.CaseDetails CD ON CR.CaseID = CD.CaseID
			INNER JOIN [$(SampleDB)].ContactMechanism.PostalAddresses PA ON PA.ContactMechanismID = CD.PostalAddressContactMechanismID
			INNER JOIN [$(SampleDB)].dbo.Markets M ON M.CountryID = PA.CountryID											-- V1.7 
			INNER JOIN [$(SampleDB)].dbo.Regions R ON R.RegionID = M.RegionID 
														AND R.Region <> 'MENA'						-- V1.7 Filter out MENA addresses
			INNER JOIN [$(SampleDB)].ContactMechanism.Countries C ON C.CountryID = PA.CountryID									
			INNER JOIN CRM.CountryLookup CL ON CL.ISOAlpha2 = C.ISOAlpha2
		WHERE CR.CRMCustomer = 'N'
			AND CR.CaseID <> 0		--CGR
			AND NOT EXISTS (	SELECT CTAU.CaseID 
								FROM #T_AddressUpdates CTAU 
								WHERE CTAU.CaseID = CR.CaseID)  -- check no customer update address present
	)
	, CTE_NonCRM_EventIDCustomerAddress	AS		-- V1.19 -- Get the customer addresses for all Non-CRM ID records which dont have a CASEID 
	(
		SELECT	DISTINCT 
			CR.CaseID,
			CR.EventID,
			PA.StreetNumber,
			PA.BuildingName,
			LTRIM(PA.SubStreetNumber + '' + PA.SubStreet) AS SubStreet,
			PA.Street,
			PA.SubLocality,
			PA.Locality,
			PA.Town,		
			PA.Region,
			PA.PostCode,
			CL.Country	
		FROM #T_CampaignResponsesCustomerInfo CR
			INNER JOIN #T_LatestAuditItemIDForEvent LAI ON LAI.EventID = CR.EventID
			INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL ON SL.AuditItemID = LAI.AuditItemID
			INNER JOIN [$(SampleDB)].ContactMechanism.PostalAddresses PA ON PA.ContactMechanismID = SL.MatchedODSAddressID
			INNER JOIN [$(SampleDB)].dbo.Markets M ON M.CountryID = PA.CountryID											-- V1.7 
			INNER JOIN [$(SampleDB)].dbo.Regions R ON R.RegionID = M.RegionID 
														AND R.Region <> 'MENA'						-- V1.7 Filter out MENA addresses
			INNER JOIN [$(SampleDB)].ContactMechanism.Countries C ON C.CountryID = PA.CountryID									
			INNER JOIN CRM.CountryLookup CL ON CL.ISOAlpha2 = C.ISOAlpha2
		WHERE CR.CRMCustomer = 'N'
			AND CR.CaseID = 0 	
	)
	INSERT INTO #T_CustomerAddressCombined (
		CaseID,
		EventID,
		StrtDt,
		PremNum,
		Prfx1,
		Prfx2,
		Street,
		Suppl1,
		Suppl2,
		CityTown,	
		RegState,
		PostCdZIP,
		Cntry		
	)
	SELECT CaseID,
		EventID,
		DateProcessed AS StrtDt,
		StreetNumber AS PremNum,
		BuildingName AS Prfx1,
		SubStreet AS Prfx2,
		Street AS Street,
		SubLocality	AS Suppl1,
		Locality AS Suppl2,
		Town AS CityTown,			-- <<< See JLR feedback email (around) 01-06-2015 : note that out city/region data incorrect (mapping issues with JLR?)
		Region AS RegState,
		PostCode AS PostCdZIP,
		Country	AS Cntry				
	FROM #T_AddressUpdates
	UNION 
	SELECT CaseID,
		EventID,
		NULL AS StrtDt,
		StreetNumber AS PremNum,
		BuildingName AS Prfx1,
		SubStreet AS Prfx2,
		Street AS Street,
		SubLocality AS Suppl1,
		Locality AS Suppl2,
		Town AS CityTown,			-- <<< See JLR feedback email (around) 01-06-2015 : note that out city/region data incorrect (mapping issues with JLR?)
		Region AS RegState,
		PostCode AS PostCdZIP,
		Country	AS Cntry
	FROM CTE_NonCRM_CustomerAddress
	UNION 
	SELECT CaseID,
		EventID,
		NULL AS StrtDt,
		StreetNumber AS PremNum,
		BuildingName AS Prfx1,
		SubStreet AS Prfx2,
		Street AS Street,
		SubLocality AS Suppl1,
		Locality AS Suppl2,
		Town AS CityTown,			-- <<< See JLR feedback email (around) 01-06-2015 : note that out city/region data incorrect (mapping issues with JLR?)
		Region AS RegState,
		PostCode AS PostCdZIP,
		Country AS Cntry
	FROM CTE_NonCRM_EventIDCustomerAddress						-- V1.19
	*/



	/* V1.26 Not collected now
	-- Combine the Email Addresses into a single temp table for lookup ----------------------------------------------------------------------------------
	DROP TABLE IF EXISTS #T_CustomerEmailCombined

	CREATE TABLE #T_CustomerEmailCombined
	(
		CaseID		BIGINT,
		EventID		BIGINT,
		EmailAddr	NVARCHAR(510)
	)
					
	;WITH CTE_NonCRM_CustomerEmail AS			-- V1.19 -- Get the customer email address for all Non-CRM ID records (where we haven't got a customer update email either)
	(
		SELECT	CR.CaseID,
			CR.EventID,
			EA.EmailAddress AS EmailAddr
		FROM #T_CampaignResponsesCustomerInfo CR
			INNER JOIN [$(SampleDB)].Meta.CaseDetails CD ON CR.CaseID = CD.CaseID
			INNER JOIN [$(SampleDB)].ContactMechanism.EmailAddresses EA ON EA.ContactMechanismID = CD.EmailAddressContactMechanismID
		WHERE CR.CRMCustomer = 'N'
			AND CR.CaseID <> 0		-- V1.19
			AND NOT EXISTS (SELECT CTEU.CaseID FROM #T_EmailUpdates CTEU WHERE CTEU.CaseID = CR.CaseID)  -- check no customer update emails present
			AND NOT EXISTS (SELECT CTEB.CaseID FROM #T_BounceBacks  CTEB WHERE CTEB.CaseID = CR.CaseID)  -- check no customer update email bouncebacks present
	)
	,CTE_NonCRM_EventIDCustomerEmail AS			-- V1.19 -- Get the customer email address for all Non-CRM ID records where there is an EventID 
	(
		SELECT	CR.CaseID,
			CR.EventID,
			EA.EmailAddress	AS EmailAddr
		FROM #T_CampaignResponsesCustomerInfo CR
			INNER JOIN #T_LatestAuditItemIDForEvent LAI ON LAI.EventID = CR.EventID
			INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL ON SL.AuditItemID = LAI.AuditItemID
			INNER JOIN [$(SampleDB)].ContactMechanism.EmailAddresses EA ON EA.ContactMechanismID = COALESCE(SL.MatchedODSPrivEmailAddressID, SL.MatchedODSEmailAddressID)
		WHERE CR.CRMCustomer = 'N'
			AND CR.CaseID = 0 		-- V1.19
	)
	INSERT INTO #T_CustomerEmailCombined (CaseID, EventID, EmailAddr)
	SELECT CaseID,
		EventID,
		EmailAddr
	FROM #T_EmailUpdates
	UNION 
	SELECT CaseID,
		EventID,
		EmailAddr
	FROM CTE_NonCRM_CustomerEmail
	UNION 
	SELECT CaseID,
		EventID,
		EmailAddr
	FROM CTE_NonCRM_EventIDCustomerEmail			-- V1.19
	*/



	/* V1.26 Not collected now
	-- Combine the Mobile Phone Numbers into a single temp table for lookup ----------------------------------------------------------------------------------
	DROP TABLE IF EXISTS #T_CustomerMobileCombined

	CREATE TABLE #T_CustomerMobileCombined
	(
		CaseID		BIGINT,
		EventID		BIGINT,
		PhNum		NVARCHAR(70)
	)

	;WITH CTE_CustomerMobileNumber AS				-- We only show phone number for non-CRM records to help with matching (- we don't do telephone number customer updates currently) 
	(
		SELECT CD.CaseID,
			CR.EventID,
			TN.ContactNumber AS PhNum
		FROM #T_CampaignResponsesCustomerInfo CR
			INNER JOIN [$(SampleDB)].Meta.CaseDetails CD ON CR.CaseID = CD.CaseID
			INNER JOIN [$(SampleDB)].Event.CaseContactMechanisms CCM ON CCM.CaseID = CD.CaseID 
																		AND CCM.ContactMechanismTypeID = (	SELECT ContactMechanismTypeID 
																											FROM [$(SampleDB)].ContactMechanism.ContactMechanismTypes 
																											WHERE ContactMechanismType = 'Phone (mobile)')
			INNER JOIN [$(SampleDB)].ContactMechanism.TelephoneNumbers TN ON TN.ContactMechanismID = CCM.ContactMechanismID 
																			AND TN.ContactNumber <> ''
		WHERE CR.CRMCustomer = 'N'
		AND CR.CaseID <> 0		--CGR
	)
	,CTE_CustomerMobileNumberEventID			-- We only show phone number for non-CRM records to help with matching (- we don't do telephone number customer updates currently) 
	AS (
		SELECT CR.CaseID,
			CR.EventID,
			TN.ContactNumber AS PhNum
		FROM #T_CampaignResponsesCustomerInfo CR
			INNER JOIN #T_LatestAuditItemIDForEvent LAI ON LAI.EventID = CR.EventID
			INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL ON SL.AuditItemID = LAI.AuditItemID
			INNER JOIN [$(SampleDB)].ContactMechanism.TelephoneNumbers TN ON TN.ContactMechanismID = COALESCE(SL.MatchedODSPrivMobileTelID, SL.MatchedODSMobileTelID) 
																			AND TN.ContactNumber <> ''
		WHERE CR.CRMCustomer = 'N'
			AND CR.CaseID = 0 		-- V1.19
	)
	INSERT INTO #T_CustomerMobileCombined (CaseID, EventID, PhNum)
	SELECT CaseID,
		EventID,
		PhNum
	FROM CTE_CustomerMobileNumber
	UNION 
	SELECT CaseID,
		EventID,
		PhNum
	FROM CTE_CustomerMobileNumberEventID
	*/



	-------------------------------------------------------------------------------------------------------------------
	-- ... END OF CODE from [CRM].[uspOutputXMLForBatch] proc.
	-------------------------------------------------------------------------------------------------------------------



	-----------------------------------------------------------------------------------------------------------------------------------------------
	-- Ensure that all of the Cases have made it into the checking file, if not then we have a logic issue which will hit the main output as well -- V1.10 
	-----------------------------------------------------------------------------------------------------------------------------------------------
	IF (SELECT COUNT(*) FROM #CasesWithNSCRef) <> (SELECT COUNT(*) FROM #T_CampaignResponsesCustomerInfo)
	RAISERROR ('uspCalculateOutputBatches - Count of recs in #CasesWithNSCRef NOT EQUAL to #T_CampaignResponsesCustomerInfo',
		16,		-- Severity
		1		-- State 
	) 
	-----------------------------------------------------------------------------------------------------------------------------------------------



	-----------------------------------------------------------------------------------------------------------------------------------------------
	-- Check that Red Flag and Gold star not supplied at the same time																	-- V1.11
	-----------------------------------------------------------------------------------------------------------------------------------------------
	/* V1.26 Not collected now
	IF (	SELECT COUNT(*)
			FROM #T_AllCases AC
				INNER JOIN [$(SampleDB)].Event.CaseCRM CC ON CC.CaseID = AC.CaseID
			WHERE AC.CaseID <> 0 
				AND ISNULL(CC.RedFlag, 0) = 1 
				AND ISNULL(CC.GoldFlag, 0) = 1 ) <> 0
	RAISERROR ('uspCalculateOutputBatches - CaseIDs for output with both Red Flag AND Gold Star set',
		16,		-- Severity
		1		-- State 
	) 
	*/

	
	-----------------------------------------------------------------------------------------------------------------------------------------------
	-- Check that AnonymityManufacturer has not been set.																				-- V1.11
	-----------------------------------------------------------------------------------------------------------------------------------------------
	IF (
		SELECT	COUNT(*)
		FROM #T_AllCases AC
			INNER JOIN [$(SampleDB)].Event.Cases C ON C.CaseID = AC.CaseID
			INNER JOIN CRM.CaseResponseStatuses CRT	ON CRT.CaseID = AC.CaseID			  
													AND CRT.EventID = AC.EventID
													--AND CRT.ResponseStatusID <> (	SELECT ResponseStatusID 
													--									FROM CRM.ResponseStatuses 
													--									WHERE ResponseStatus IN ('Sent'))	-- V1.15 -- Ignore "Sent" statuses
													AND CRT.ResponseStatusID = (	SELECT ResponseStatusID 
																					FROM CRM.ResponseStatuses 
																					WHERE ResponseStatus IN ('Completed'))	-- V1.18 Only Check "Completed" statuses
													AND CRT.OutputToCRMDate IS NULL
		WHERE AC.CaseID <> 0 
			AND C.AnonymityManufacturer = 1) <> 0
	RAISERROR ('uspCalculateOutputBatches - CaseIDs for output with Manufacturer Anonymity set TRUE',
		16,		-- Severity
		1		-- State 
	) 	



	---------------------------------------------------------------------------------------------------------------------------------------------
	-- Remove any existing Size limit errors for the cases we are about to output.  We then add anew if an error still persists.      -- V1.7
	---------------------------------------------------------------------------------------------------------------------------------------------
	
	-- Remove any current Cases from the ResponsesHeldBackDueToSizeLimits prior to checking as they may now be OK
	DELETE SL
	FROM #CasesWithNSCRef N
		INNER JOIN CRM.ResponsesHeldBackDueToSizeLimits SL ON SL.CaseID = N.CaseID	
	WHERE N.EventID = 0


	-- NOW RUN CHECKS ON FIELD SIZES
	INSERT INTO CRM.ResponsesHeldBackDueToSizeLimits (CaseID, EventID, ACCT_ACCT_ID, FstNm, LstNm, AddLstNm, Cntry, OrgName1, DateAdded)
	--Ttl, RegNum, PhNum, EmailAddr,	EmailAddrBB, PremNum, Prfx1, Prfx2, Street, Suppl1, Suppl2, CityTown, RegState, PostCdZIP,		-- V1.26
	SELECT CR.CaseID,
		0 AS EventID,
		CR.ACCT_ACCT_ID,
		--CASE	WHEN LEN(ISNULL(PU.Ttl, 0)) > 30 THEN PU.Ttl							-- V1.26
		--		ELSE '' END AS Ttl,				-- V1.10 - Add ISNULLs to all checks
		CASE	WHEN LEN(ISNULL(CR.FstNm, 0)) > 40 THEN CR.FstNm
				ELSE '' END AS FstNm,		
		CASE	WHEN LEN(ISNULL(CR.LstNm, 0)) > 40 THEN CR.LstNm
				ELSE '' END AS LstNm,
		CASE	WHEN LEN(ISNULL(CR.AddLstNm, 0)) > 40 THEN CR.AddLstNm		
				ELSE '' END AS AddLstNm,
		CASE	WHEN LEN(ISNULL(CR.Cntry, 0)) > 50 THEN CR.Cntry		
				ELSE '' END AS Cntry,
		CASE WHEN LEN(CR.OrgName1) > 40 THEN CR.OrgName1								-- V1.6
		ELSE '' END AS OrgName1,														-- V1.6 
		/*	-- V1.26
		CASE	WHEN LEN(ISNULL(RN.RegNum, 0)) > 30 THEN RN.RegNum
				ELSE '' END AS RegNum,
		CASE	WHEN LEN(ISNULL(CM.PhNum, 0)) > 30 THEN CM.PhNum
				ELSE '' END AS PhNum,
		CASE	WHEN LEN(ISNULL(EM.EmailAddr, 0)) > 241 THEN EM.EmailAddr	
				ELSE '' END AS EmailAddr,
		CASE	WHEN LEN(ISNULL(BB.EmailAddr, 0)) > 241 THEN BB.EmailAddr	
				ELSE '' END AS EmailAddrBB,
		CASE	WHEN LEN(ISNULL(CAC.PremNum, 0)) > 10 THEN CAC.PremNum		
				ELSE '' END AS PremNum,
		CASE	WHEN LEN(ISNULL(CAC.Prfx1, 0)) > 20 THEN CAC.Prfx1	
				ELSE '' END AS Prfx1,
		CASE	WHEN LEN(ISNULL(CAC.Prfx2, 0)) > 10 THEN CAC.Prfx2		
				ELSE '' END AS Prfx2,
		CASE	WHEN LEN(ISNULL(CAC.Street, 0)) > 60 THEN CAC.Street		
				ELSE '' END AS Street,
		CASE	WHEN LEN(ISNULL(CAC.Suppl1, 0)) > 40 THEN CAC.Suppl1		
				ELSE '' END AS Suppl1,
		CASE	WHEN LEN(ISNULL(CAC.Suppl2, 0)) > 40 THEN CAC.Suppl2		
				ELSE '' END AS Suppl2,
		CASE	WHEN LEN(ISNULL(CAC.CityTown, 0)) > 40 THEN CAC.CityTown
				ELSE '' END AS CityTown,
		CASE	WHEN LEN(ISNULL(CAC.RegState, 0)) > 30 THEN CAC.RegState	
				ELSE '' END AS RegState,
		CASE	WHEN LEN(ISNULL(CAC.PostCdZIP, 0)) > 10 THEN  CAC.PostCdZIP
				ELSE '' END AS PostCdZIP,
		*/
		@SysDate AS DateAdded
	FROM #T_CampaignResponsesCustomerInfo CR
		/*	-- V1.26
		LEFT JOIN #T_CustomerAddressCombined CAC ON CAC.CaseID = CR.CaseID
													AND CAC.EventID = CR.EventID 
		LEFT JOIN #T_PersonUpdates PU ON PU.CaseID = CR.CaseID	
		LEFT JOIN #T_CustomerMobileCombined CM ON CM.CaseID = CR.CaseID
													AND CM.EventID = CR.EventID
		LEFT JOIN #T_RegistrationUpdates RN	ON RN.CaseID = CR.CaseID
		LEFT JOIN #T_CustomerEmailCombined EM ON EM.CaseID = CR.CaseID	  
												AND EM.EventID = CR.EventID
		*/
		LEFT JOIN #T_BounceBacks BB	ON BB.CaseID = CR.CaseID	 
	WHERE --LEN(ISNULL(PU.Ttl, 0)) > 30							-- V1.10 - Add ISNULLs to all checks V1.26
		LEN(ISNULL(CR.FstNm, 0)) > 40							-- V1.6
		OR LEN(ISNULL(CR.LstNm, 0)) > 40						-- V1.6
		OR LEN(ISNULL(CR.AddLstNm, 0)) > 40
		OR LEN(ISNULL(CR.Cntry, 0)) > 50
		--  OR LEN(CR.OrganisationName1) > 40					-- V1.6 
		/*	-- V1.26
		OR LEN(ISNULL(RN.RegNum, 0)) > 30
		OR LEN(ISNULL(CM.PhNum, 0)) > 30 
		OR LEN(ISNULL(EM.EmailAddr, 0)) > 241
		OR LEN(ISNULL(BB.EmailAddr, 0)) > 241
		OR LEN(ISNULL(CAC.PremNum, 0))	> 10
		OR LEN(ISNULL(CAC.Prfx1, 0)) > 20 
		OR LEN(ISNULL(CAC.Prfx2, 0)) > 10 
		OR LEN(ISNULL(CAC.Street, 0)) > 60 
		OR LEN(ISNULL(CAC.Suppl1, 0)) > 40 
		OR LEN(ISNULL(CAC.Suppl2, 0)) > 40 
		OR LEN(ISNULL(CAC.CityTown, 0)) > 40 
		OR LEN(ISNULL(CAC.RegState, 0)) > 30 
		OR LEN(ISNULL(CAC.PostCdZIP, 0)) > 10
		*/
	


	-- Remove from the #CasesWithNSCRef temp table so that they are not output
	DELETE FROM #CasesWithNSCRef
	WHERE CaseID IN (	SELECT CaseID 
						FROM CRM.ResponsesHeldBackDueToSizeLimits)	
		AND EventID = 0



	---------------------------------------------------------------------------------------------------------------------------------------------
	-- Remove any existing Size limit errors for the events we are about to output.  We then add anew if an error still persists.      -- V1.30
	---------------------------------------------------------------------------------------------------------------------------------------------
	
	-- Remove any current Events from the ResponsesHeldBackDueToSizeLimits prior to checking as they may now be OK
	DELETE SL
	FROM #CasesWithNSCRef N
		INNER JOIN CRM.ResponsesHeldBackDueToSizeLimits SL ON SL.EventID = N.EventID	
	WHERE N.CaseID = 0


	-- NOW RUN CHECKS ON FIELD SIZES
	INSERT INTO CRM.ResponsesHeldBackDueToSizeLimits (CaseID, EventID, ACCT_ACCT_ID, FstNm, LstNm, AddLstNm, Cntry, OrgName1, DateAdded)
	SELECT 0 AS CaseID,
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
		CASE WHEN LEN(CR.OrgName1) > 40 THEN CR.OrgName1								-- V1.6
		ELSE '' END AS OrgName1,														-- V1.6 
		@SysDate AS DateAdded
	FROM #T_CampaignResponsesCustomerInfo CR
	WHERE LEN(ISNULL(CR.FstNm, 0)) > 40													-- V1.6
		OR LEN(ISNULL(CR.LstNm, 0)) > 40												-- V1.6
		OR LEN(ISNULL(CR.AddLstNm, 0)) > 40
		OR LEN(ISNULL(CR.Cntry, 0)) > 50


	-- Remove from the #CasesWithNSCRef temp table so that they are not output
	DELETE FROM #CasesWithNSCRef
	WHERE EventID IN (	SELECT EventID 
						FROM CRM.ResponsesHeldBackDueToSizeLimits)	
		AND CaseID = 0	



	/*	
	---------------------------------------------------------------------------------------------------------------------------------------------
	-- Check for missing  XMLOutputValues_Market record (NSCRef lookup) and save to Missing Ref table for email alert output  -- V1.4 -- V1.16 MOVED
	---------------------------------------------------------------------------------------------------------------------------------------------
	INSERT INTO CRM.OutputErrors (CaseID, EventID, AttemptedOutputDate, ErrorDescription)
	SELECT N.CaseID, 
		N.EventID, 
		@SysDate, 
		'Missing XMLOutputValues_Market record (NSCRef lookup) for CountryID: ' + CAST(N.CountryID AS VARCHAR(5))
	FROM #CasesWithNSCRef N
	WHERE NSCRef IS NULL

	DELETE 
	FROM #CasesWithNSCRef
	WHERE NSCRef IS NULL
	*/


	/* V1.32 XMLOutputValues_MarketQuestionnaire not used anymore
	---------------------------------------------------------------------------------------------------------------------------------------------
	-- Check for missing XMLOutputValues_MarketQuestionnaire record (CampaignID lookup) and save to Missing Ref table for email alert output -- V1.4
	---------------------------------------------------------------------------------------------------------------------------------------------
	INSERT INTO CRM.OutputErrors (CaseID, EventID, AttemptedOutputDate, ErrorDescription)
	SELECT N.CaseID, 
		N.EventID, 
		@SysDate AS AttemptedOutputDate, 
		'Missing XMLOutputValues_MarketQuestionnaire record (CampaignID lookup) for CountryID: ' + CAST(CD.CountryID AS VARCHAR(5)) + ', EventCategoryID: ' + CAST(ETC.EventCategoryID AS VARCHAR(3)) + ', BrandID: ' + CAST(B.BrandID AS VARCHAR(2)) AS ErrorDescription
	FROM #CasesWithNSCRef N
		INNER JOIN #T_CollatedCommonBaseData CD ON CD.CaseID = N.CaseID 
													AND CD.EventID = N.EventID
		INNER JOIN [$(SampleDB)].Event.EventTypeCategories ETC ON ETC.EventTypeID = CD.EventTypeID
		INNER JOIN [$(SampleDB)].Event.EventCategories EC ON EC.EventCategoryID = ETC.EventCategoryID
		INNER JOIN [$(SampleDB)].Party.Organisations O ON O.PartyID = CD.ManufacturerPartyID 
		INNER JOIN [$(SampleDB)].dbo.Brands B ON B.ManufacturerPartyID = CD.ManufacturerPartyID 
		LEFT JOIN CRM.XMLOutputValues_MarketQuestionnaire MQ ON MQ.CountryID = CD.CountryID 
																AND MQ.EventCategoryID = ETC.EventCategoryID 
																AND MQ.BrandID = B.BrandID
		LEFT JOIN #T_CRM_Data CRMD ON CRMD.EventID = CD.ODSEventID		-- V1.8 
	WHERE MQ.CountryID IS NULL											-- Check whether XMLOutputValues_MarketQuestionnaire is present 
		AND NULLIF(CRMD.CAMPAIGN_CAMPAIGN_ID, '') IS NULL				-- V1.8

	-- delete from output
	DELETE N
	FROM #CasesWithNSCRef N
		INNER JOIN CRM.OutputErrors OE ON OE.CaseID = N.CaseID
										AND OE.EventID = N.EventID		-- V1.21
										AND OE.ErrorDescription LIKE 'Missing XMLOutputValues_MarketQuestionnaire record%'
	*/


	---------------------------------------------------------------------------------------------------------------------------------------------
	-- Check for missing CRM Data and save to Missing Ref table for email alert output -- V1.30
	---------------------------------------------------------------------------------------------------------------------------------------------
	INSERT INTO CRM.OutputErrors (CaseID, EventID, AttemptedOutputDate, ErrorDescription)
	SELECT N.CaseID, 
		N.EventID, 
		@SysDate AS AttemptedOutputDate, 
		'Missing CRM data' AS ErrorDescription
	FROM #CasesWithNSCRef N
		INNER JOIN #T_CollatedCommonBaseData CD ON CD.CaseID = N.CaseID 
													AND CD.EventID = N.EventID
		LEFT JOIN #T_CRM_Data CRMD ON CRMD.EventID = CD.ODSEventID		-- V1.8 
	WHERE CRMD.ACCT_ACCT_ID IS NULL										-- Check whether CRM data is present 


	-- delete from output
	DELETE N
	FROM #CasesWithNSCRef N
		INNER JOIN CRM.OutputErrors OE ON OE.CaseID = N.CaseID
										AND OE.EventID = N.EventID		-- V1.21
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
		SELECT NSCRef, Batch, ROW_NUMBER() OVER (ORDER BY NSCRef, Batch) AS BatchSeq
		FROM (	SELECT DISTINCT NSCRef, 
					Batch
				FROM CTE_BatchesWithinNSCRef) AS C
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