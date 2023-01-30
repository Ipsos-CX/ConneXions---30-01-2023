CREATE PROCEDURE [CRM].[uspOutputXMLForBatch]  
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
		Purpose:	Outputs the CRM XML for the cases in the specified batch
		
		Version		Date				Developer			Comment
LIVE	1.0			20/08/2015			Chris Ross			Created 
LIVE	1.1			10/02/2016			Chris Ross			BUG 11448 - Modified to output originally supplied country column (as we convert 
																		Isle of Man, Guernsey, Jersey to United Kingdom.
LIVE	1.2			05/07/2016			Chris Ross			BUG 12777 - Updated to now output unsubscribes and optionally output the repsonse section if no associated responses, 
																		includes updates to Status column and removal of the CustExprScr hardcoded element.
LIVE	1.3			16/07/2016			Chris Ross			BUG 12777 - CRM 3.0 - Add in new account structure for Org Contacts, new account role columns for leasing, etc., 
																		and fix customer ID output to only output CRM IDs.  Plus, updated to now output bouncebacks.   
LIVE	1.4			07/10/2016			Chris Ross			BUG 13188 - CRM 3.0 - Modify to only output Account/Contact structure for non-CRM ID Cases, otherwise we display the individual, either
																		Org or Person. Always return the CRM ID provided in the incoming sample the Case is from, if it exists, otherwise take 
																		latest CRM ID on file.  For non-CRM customers also return the address, email and phone details to assist JLR system with 
																		matching (address is always at Account level but Email and Phone number are at Contact level in an Org/Contact scenario)
LIVE	1.5			16/11/2016			Chris Ross			BUG 13349 - Add lookup into CTE_CampaignResponsesCustomerInfo for JLR CRM Country codes in CRM.CountryLookup table.
LIVE	1.6			19/12/2016			Chris Ross			BUG 13424 - Truncate output values to ensure they are not larger than the CRM system expects. Also filter Customer bouncbacks and unsubscribes 
																		after 01-12-2016 (v3.0 inception) - this is to stop the system picking up old linked data. 																	
LIVE	1.6a		13/02/2017			Chris Ross			BUG 13424 - Reversed out 1.6 truncation changes but left bouncebacks and unsubscribes filter (after 01-12-2016) in place.
LIVE	1.6b		14/02/2017			Chris Ross			BUG 13424 - Added in funtionality to ensure no duplicates on Unsubscribes or BounceBacks (Note: bouncebacks take the latest Contact Outcome record)
LIVE	1.6c		15/02/2017			Chris Ross			BUG 13424 - New funtionality to ensure that mutiple <Email> elements are rolled up into a single <Emails> element (not mutiple as we have now).
LIVE	1.7			16/02/2017			Chris Ross			BUG 13590 - Filter out MENA addresses		
LIVE	1.8			16/02/2017			Chris Ross			BUG 13567 - Split OrgName over into OrgName2 when it breaks the column size limit. Include OrgName2 in output.
																		Apply formatting to MENA first and Last Names as they can be over 40 chars and Lastname is sometimes not populated.
LIVE	1.9			20/04/2017			Chris Ross			BUG 13566 - Modify to use EventID as well as CaseID from BatchOutput table.  Update to provide alternatve links and data where we cannot get from CaseDetails table.
																        Also, required moving to temp tables as running too slowly.
LIVE	1.10		10/05/2017			Chris Ross			BUG 13910 - Remove element JLRCntctRqstd from output.
LIVE	1.11		07/06/2017			Chris Ross			Increased the Manufacturer column size to 510 due to very strange bug caused by truncation even though the MAX len is only 10 chars.
LIVE	1.12		21/06/2017			Chris Ross			BUG 14039 - Remove <Emails/> item when no email info present, also do not populate the Email Cust Update or Address update if they are filled with blanks.
LIVE	1.13		29/08/2017			Chris Ross			BUG 14202 - Add in VsbltyStts element to Srvy.
LIVE	1.14		11/10/2017			Chris Ross			BUG 14299 - Add in Gold Star/Red Flag output and VsbltyStts column.
LIVE	1.15		05/12/2017			Chris Ledger		BUG 13373 - Add PreOwned
LIVE	1.16		26/01/2018			Chris Ross			BUG 14506 - Add in constraints to ensure we only retrieve the CRM staging records associated with the PartyID used in the Event or CaseID
LIVE	1.17		28/02/2018			Chris Ross			BUG 14506 - Removed filter on UncodedDealer from the additional AuditItemID lookup as not required.
LIVE	1.18		05/07/2018			Chris Ross			BUG 14741 - Update Unsubscribe/Permissions output with new permissions values and FrmOfCnsnt on output.  Update of SrvtDt to SrvyDt.
LIVE	1.19		22/11/2018			Chris Ross			BUG 15118 - Include Dealer Code column (DlrCd) in output
LIVE	1.20		08/01/2019			Chris Ross			BUG 15188 - Modify dealer code output for NA to use the OutletCode rather then Outlet_GDD
LIVE	1.21		01/03/2019			Chris Ross			BUG 15234 - Add check on originating CRM data to determine whether we output as an individual, as an Organization may have been attached to the Case.
LIVE	1.22		04/07/2019			Chris Ross			BUG 15472 - Fix bug where Contact “Prmssn”/ “Prmssns” elements are the wrong way round.
LIVE	1.23		29/11/2019			Chris Ledger		BUG 15490 - Add PreOwned LostLeads
LIVE	1.25		15/01/2020			Chris Ledger		BUG 15372 - Fix Hard coded references to databases
LIVE	1.26        18/02/2021          Chris Ledger        BUG 18110 - SV-CRM Feed Changes
LIVE	1.27		25/03/2021			Chris Ledger		TASK 299 - Add General Enquiry
LIVE	1.28		21/04/2021			Chris Ledger		TASK 400 - Amend AccountType setting Organization to Person and change ACCT_ACCT_TYPE values from Individual to Person 
LIVE	1.29		01/06/2021			Chris Ledger		TASK 411 - Add CQI
LIVE	1.33		17/06/2021			Chris Ledger		TASK 505 - Stop using XMLOutputValues_MarketQuestionnaire to get CmpgnID
LIVE	1.34		23/08/2021			Chris Ledger		TASK 567 - Add LostLeads
LIVE	1.35		18/10/2021			Chris Ledger		TASK 661 - Change PrmssnSupprType to 'JLR/All/Customer Satisfaction Survey' for Italy
LIVE	1.36		27/10/2021			Chris Ledger		TASK 661 - Add ServerName to WHERE clause for SecurityHeaderInfo 
LIVE	1.38		14/01/2022			Chris Ledger		TASK 755 - Set NSCRef based on country of market
LIVE	1.39		21/03/2022			Chris Ledger		TASK 530 - Add SC115 filter to WHERE clause for SecurityHeaderInfo
LIVE	1.40		27/04/2022			Chris Ledger		TASK 865 - Add HrdBncCntr and SftBncCntr back into output
LIVE	1.41		08/06/2022			Ben King			TASK 881 - Land Rover Experience - Selection Feedback SVCRM
*/


	--------------------------------------------------------------------------------------------------
	-- Create UUID for ContextId element
	--------------------------------------------------------------------------------------------------
	DECLARE @UID UNIQUEIDENTIFIER,						
			@ContextId NVARCHAR(42)

	SET @UID = NEWID()
	SET @ContextId = 'uuid:' + CONVERT(NVARCHAR(40), @UID)


	--------------------------------------------------------------------------------------------------
	-- Set the UUID in the Event.CaseCRM table for reference purposes
	--------------------------------------------------------------------------------------------------
	UPDATE C
	SET C.UUID = @UID
	FROM CRM.OutputBatches B 
	INNER JOIN [$(SampleDB)].Event.CaseCRM C ON C.CaseID = B.CaseID
											AND C.OutputToCRMDate IS NULL
	WHERE B.Batch = @Batch


	--------------------------------------------------------------------------------------------------
	-- Set the UUID in the CRM.CaseResponseStatuses table for reference purposes  -- V1.2
	--------------------------------------------------------------------------------------------------
	UPDATE C
	SET C.UUID = @UID
	FROM CRM.OutputBatches B 
	INNER JOIN CRM.CaseResponseStatuses C ON C.CaseID = B.CaseID
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
		NSCRef		NVARCHAR(255)						-- V1.38	
	)

	INSERT INTO #T_AllCases (CaseID, EventID, NSCRef)	-- V1.38
	SELECT DISTINCT CaseID, 
		EventID,
		NSCRef											-- V1.38
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
						WHERE I.ServerName = @@SERVERNAME					-- V1.36
							AND I.Username LIKE 'SC115%'					-- V1.39
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
				WHERE I.ServerName = @@SERVERNAME							-- V1.36
					AND I.Username LIKE 'SC115%'							-- V1.39
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
																					AND AC.CaseID = 0			-- V1.19
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
		C9.ACCT_ACCT_TYPE							-- V1.41
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
		CASE	WHEN CRM.ACCT_ACCT_TYPE = 'Person' THEN NULL														-- V1.28
				ELSE NULLIF(SL.MatchedODSOrganisationID, 0) END AS OrganisationPartyID,								-- V1.22
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
		LEFT JOIN #T_CRM_Data CRM ON CRM.EventID = AC.EventID														-- V1.22
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
			CD.Country,																											-- V1.35
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
		CASE	WHEN CU.Country = 'Italy' THEN 'JLR/All/Customer Satisfaction Survey'											-- V1.35
				ELSE CU.OrganisationName + ' E-mail' END AS PrmssnSupprType,													-- V1.35
		CU.DtOfCnsnt,
		CU.Cnsnt,
		COP.FrmOfCnsnt
	FROM CTE_Unsubscribes CU
		INNER JOIN CTE_OutputTypes COP ON CU.CaseID = COP.CaseID 
											AND RowID = 1
	UNION
	SELECT CU.CaseID,
		CASE	WHEN CU.Country = 'Italy' THEN 'JLR/All/Customer Satisfaction Survey'											-- V1.35
				ELSE CU.OrganisationName + ' Telephone' END AS PrmssnSupprType,													-- V1.35
		CU.DtOfCnsnt,
		CU.Cnsnt,
		COP.FrmOfCnsnt
	FROM CTE_Unsubscribes CU
		INNER JOIN CTE_OutputTypes COP ON CU.CaseID = COP.CaseID 
											AND RowID = 1
	UNION
	SELECT	CU.CaseID,
		CASE	WHEN CU.Country = 'Italy' THEN 'JLR/All/Customer Satisfaction Survey'											-- V1.35
				ELSE CU.OrganisationName + ' SMS' END AS PrmssnSupprType,														-- V1.35
		CU.DtOfCnsnt,
		CU.Cnsnt,
		COP.FrmOfCnsnt
	FROM CTE_Unsubscribes CU
		INNER JOIN CTE_OutputTypes COP ON CU.CaseID = COP.CaseID 
											AND RowID = 1
	UNION
	SELECT	CU.CaseID,
		CASE	WHEN CU.Country = 'Italy' THEN 'JLR/All/Customer Satisfaction Survey'											-- V1.35
				ELSE CU.OrganisationName + ' Post' END AS PrmssnSupprType,														-- V1.35
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
		RspnseId				NVARCHAR(20),
		Status					NVARCHAR(50),				-- CGR
		ResponseStatusID		INT,						-- CGR - for Auditing
		LoadedToConnexions		DATETIME2,					-- CGR - for Auditing
		CmpgnId					NVARCHAR(255),
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
		RspnseId,
		Status,
		ResponseStatusID,
		LoadedToConnexions,
		CmpgnId,
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
		C.RESPONSE_ID AS RspnseId,
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
		COALESCE(CCL.Country, CB.Country) AS Cntry,			-- V1.5		--<<<< Country name needs to match the list provided by JLR (e.g. Russia NOT Russian Federation)
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
	--  Add in IDs and whether Person/Org or CRM cust for output ----------------------------------------------------------------------------------
	UPDATE CI
	SET CI.CRM_CustID_Individual = COALESCE(NULLIF(CI.ACCT_ACCT_ID, ''), PCI.AcctID),					-- NOTE: the Organization and Person Cust ID columns get COALESCED so OK to use ACCT_ACCT_ID as primary value on both.
		CI.CRM_CustID_Organisation = COALESCE(NULLIF(CI.ACCT_ACCT_ID, ''), OCI.AcctID),
		CI.CRMCustomer = CASE	WHEN ((ISNULL(CI.PartyID, 0) <> 0 AND ISNULL(PCI.AcctID, '') <> '' )	-- An indiviudal exists and an associated CRM ID is present - THEN IS A CRM CUSTOMER
									OR (ISNULL(CI.PartyID, 0) = 0 AND ISNULL(OCI.AcctID, '') <> '' )	-- OR: No individual exists and the Organization has a CRM ID present - THEN IS A CRM CUSTOMER
									OR NULLIF(CI.ACCT_ACCT_ID, '') IS NOT NULL	) THEN 'Y'					-- Or we have a CRM account ID present in the staging tables   -- V1.2
								ELSE 'N' END,
		CI.ReturnIndividual	= CASE	WHEN (ISNULL(CI.OrgName1, '') = '' 
										OR PCI.AcctID IS NOT NULL										-- When the organisation name is blank OR we have an CRM CustID for the individual OR ...
										OR CI.ACCT_ACCT_TYPE = 'Person' ) THEN 'Y'					-- OR when the customer was received via CRM as "Person", then we return highest level as Person -- V1.21
									ELSE 'N' END
	FROM #T_CampaignResponsesCustomerInfo CI
		LEFT JOIN #T_PersonCustomerID PCI ON PCI.PartyID = CI.PartyID
		LEFT JOIN #T_OrgCustomerID OCI ON OCI.PartyID = CI.OrganisationPartyID
	*/
	--  V1.28 Add in IDs and whether Person/Org or CRM cust for output ----------------------------------------------------------------------------------
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



	-- POPULATE THE XML FIELDS --------------------------------------------------------------------------------------------------------------------
	SELECT @XML_BatchBody = (
		SELECT ( 
			SELECT ( -- BatchRequestBody
				SELECT (  -- BatchMessages
					SELECT (  -- createOrUpdateCampaignEventandResponse
						SELECT ( -- CRMHeader
							SELECT 'CAM' AS BusinessProcessReference,
								CTR.Manufacturer AS Brand,
								CTR.NSCRef
							FOR XML PATH ('CRMHeader'), TYPE 
						),
						( -- Cmpgn
						SELECT CTR.CmpgnId,				
							'Survey' AS CmpgnCat,
							CTR.Manufacturer AS Brnd,
							( -- CmpgnEvntResp
							SELECT CTR.RspnseId,		
								Status,
								( -- Acct
								SELECT
									CASE	WHEN CTR.CRMCustomer = 'Y' THEN CTR.ACCT_ACCT_ID		-- V1.28
											--WHEN CTR.CRMCustomer = 'Y' THEN COALESCE(CTR.CRM_CustID_Individual, CTR.CRM_CustID_Organisation) 
											ELSE NULL END AS AcctId, 
									--(	SELECT Ttl FROM #T_PersonUpdates PU 
									--	WHERE PU.CaseID = CTR.CaseID								-- Only display Title if there is a Customer Update for Person 
									--		AND PU.AuditItemID = (	SELECT MAX(PUL.AuditItemID)		-- And take the latest if there is more than one update supplied.
									--								FROM #T_PersonUpdates PUL
									--								WHERE PUL.CaseID= CTR.CaseID ) 
									--		AND ReturnIndividual = 'Y' ) AS Ttl,
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
									(-- AcctRls		
									SELECT ( -- AcctRl	
										SELECT	
											'Z2' AS '@ActnCd',
											CTR.Role
										FOR XML PATH ('AcctRl'), TYPE 
										)
									FOR XML PATH ('AcctRls'), TYPE 
									),
									CASE	WHEN CTR.CRMCustomer = 'N' THEN ( 	
												SELECT (-- ExtAccIds
													SELECT -- ExtAccId 	
														'GFK' AS IdType,
														CASE	WHEN CTR.CRMCustomer = 'N' AND CTR.ReturnIndividual = 'Y' THEN CTR.PartyID
																WHEN CTR.CRMCustomer = 'N' AND CTR.ReturnIndividual = 'N' THEN CTR.OrganisationPartyID
																ELSE NULL END AS IdVal
													FOR XML PATH ('ExtAccId'), TYPE
													)										-- Only include GFK PartyID where it is not a CRM customer 
												FOR XML PATH ('ExtAccIds'), TYPE 
												)
											ELSE NULL END ,
										(-- OrgCntcts		
										SELECT ( -- OrgCntct
											SELECT	
												'Contact Person Relationship' AS RelType,
											------------------------------------------------------------------------------------------------
											--- DUPLICATED "ACCT" ELEMENT INFORMATION FOR OrgCntct  --  
											------------------------------------------------------------------------------------------------
												( -- Acct
												SELECT
													-- CRM CUstomer will never be ORG/CONTACT - (SELECT AcctId FROM CTE_PersonCustomerID WHERE PartyID = CTR.PartyID ) AS AcctId,		-- <<< Pulled in from Customer Relationships table if it exists (this is supplied by JLR CRM)
													--(	SELECT Ttl		--V1.26 Not included
													--	FROM #T_PersonUpdates PU 
													--	WHERE PU.CaseID = CTR.CaseID								-- Only display Title if there is a Customer Update for Person 
													--		AND PU.AuditItemID = (	SELECT MAX(PUL.AuditItemID)		-- And take the latest if there is more than one update supplied.
													--								FROM #T_PersonUpdates PUL
													--								WHERE PUL.CaseID = CTR.CaseID) ) AS Ttl,	
													CTR.FstNm,  
													CTR.LstNm,
													CTR.AddLstNm,
													'Person' AS AcctType,
													CTR.Cntry,
													( -- AcctRls		
														SELECT ( -- AcctRl																					( 
															SELECT	
																'Z2' AS '@ActnCd',
																'Contact' AS Role		-- Fixed to 'Contact' as we are in the OrgCntcts element
															FOR XML PATH ('AcctRl'), TYPE
															)
														FOR XML PATH ('AcctRls'), TYPE
														),
														/*
														------------------------------------------------------------------------------------------------------------------------------------------																																																	
														-- AcctAddress - only send back with Org or Person (not Org Contact) 																														
														------------------------------------------------------------------------------------------------------------------------------------------																				
														( -- VhclAcctRels
															SELECT ( -- VhclAcctRel																					( 
																SELECT	( -- Vhcl
																		SELECT RU.RegNum
																		FOR XML PATH ('Vhcl'), TYPE
																	)	
																FOR XML PATH ('VhclAcctRel'), TYPE
																)
															FROM #T_RegistrationUpdates RU
															WHERE RU.CaseID = CTR.CaseID
															FOR XML PATH ('VhclAcctRels'), TYPE
														),
														------------------------------------------------------------------------------------------------------------------------------------------																				
														(-- Tels --> mobile against the Case
															SELECT ( -- Email
																	SELECT MN.PhNum,
																		'Cell Phone' AS PhNumType
																	FOR XML PATH ('Tel'), TYPE
																	)	
															FROM #T_CustomerMobileCombined MN
															WHERE MN.CaseID = CTR.CaseID
																AND MN.EventID = CTR.EventID			-- CGR
															FOR XML PATH ('Tels'), TYPE
														),
														*/	-- V1.40 Add HrdBncCntr & SftBncCntr back in to output
														------------------------------------------------------------------------------------------------------------------------------------------																				
														(-- Emails 
															SELECT ( 
																SELECT (	-- V1.12
																	/*	-- V1.40
																	SELECT ( -- Email  --> Non CRM Emails + Customer Updates 
																			SELECT EU.EmailAddr,
																				'false' AS DoNotUseFlg
																			FOR XML PATH ('Email'), TYPE
																			)	
																	FROM #T_CustomerEmailCombined EU
																	WHERE EU.CaseID = CTR.CaseID
																		AND EU.EventID = CTR.EventID			-- CGR -- New linkage to include on EventID
																	),
																	(
																	*/	-- V1.40
																		SELECT ( -- Email --> Bouncebacks
																			SELECT BB.EmailAddr,
																				BB.HrdBncCntr,
																				BB.SftBncCntr
																			FOR XML PATH ('Email'), TYPE
																			)	
																		FROM #T_BounceBacks BB
																		WHERE BB.CaseID = CTR.CaseID
																	)
																																	
																FOR XML PATH ('Emails'), TYPE 
																)
															WHERE EXISTS (	SELECT * 
																			FROM #T_BounceBacks BB				-- V1.12 - Add in additional check so that "Emails" is only output if
																			WHERE BB.CaseID = CTR.CaseID)		--         there are email elements data to output.
																/* -- V1.40
																OR EXISTS (	SELECT * 
																			FROM #T_CustomerEmailCombined EU
																			WHERE EU.CaseID = CTR.CaseID
																				AND EU.EventID = CTR.EventID)
																*/ -- V1.40
														),		
														------------------------------------------------------------------------------------------------------------------------------------------																				
													(-- Prmssns  -- V1.18
													SELECT ( 
														SELECT PRM.PrmssnSupprType,
															CONVERT(NVARCHAR(10), ISNULL(PRM.DtOfCnsnt, GETDATE()), 120) DtOfCnsnt,
															PRM.Cnsnt,
															PRM.FrmOfCnsnt
														FROM #T_Permissions PRM
														WHERE PRM.CaseID = CTR.CaseID
														FOR XML PATH ('Prmssn'), TYPE					-- V1.22
														)	
													WHERE EXISTS (	SELECT * 
																	FROM #T_Permissions PRM 
																	WHERE PRM.CaseID = CTR.CaseID)			-- Only output if permissions actually exist
													FOR XML PATH ('Prmssns'), TYPE							-- V1.22
													)
												------------------------------------------------------------------------------------------------------------------------------------------																				
												FOR XML PATH ('Acct'), TYPE
												)
												------------------------------------------------------------------------------------------------------------------------------------------																				
											------------------------------------------------------------------------------------------------------------------------------------------																				
											FOR XML PATH ('OrgCntct'), TYPE
											)
										WHERE CTR.OrgName1 <> '' 
											AND  CTR.LstNm <> ''  
											AND (CTR.CRMCustomer = 'N' OR CTR.ACCT_ACCT_TYPE = 'Organization')		-- Only output where an Organization AND Person exists  --V1.21
										FOR XML PATH ('OrgCntcts'), TYPE
										),
										/*
										------------------------------------------------------------------------------------------------------------------------------------------																				
										(-- AcctAddrs
											SELECT ( -- AcctAddr																					( 
												SELECT CASE	WHEN NULLIF(CTR.OrgName1, '') IS NOT NULL THEN 'Work' 
															ELSE 'Home 1' END AS AddrType,							-- <<<< Needs to be 'work' for organisations 
													CONVERT(NVARCHAR(10), ISNULL(CAC.StrtDt, GETDATE()), 120) AS StrtDt, 
													( -- Addr
														SELECT CAC.POBox,
															CAC.PremNum,
															CAC.Prfx1,
															CAC.Prfx2,
															CAC.Street,
															CAC.Suppl1,
															CAC.Suppl2,
															CAC.Suppl3,
															CAC.CityTown,
															CAC.RegState,
															CAC.PostCdZIP,
															CAC.Cntry,
															CAC.CofName,
															CAC.City2,
															CAC.HomeCity,
															CAC.POBoxPostCode,
															CAC.CmpnyPostCode,
															CAC.CityPostCodeExt,
															CAC.POBoxPostCodeExt,
															CAC.MajCustPostCodeExt,
															CAC.POBoxCity,
															CAC.CityPOBoxCode,
															CAC.POBoxRegState,
															CAC.POBoxCntry,
															CAC.PremNum2,
															CAC.PremNumRange,
															CAC.Location,
															CAC.BldngFloor,
															CAC.RoomNo,
															CAC.County,
															CAC.Township
															--	CAC.POBoxLobby			-- ERROR IN XSD  !!!
														FOR XML PATH ('Addr'), TYPE
													)	
												FOR XML PATH ('AcctAddr'), TYPE
											)
											FROM #T_CustomerAddressCombined CAC
											WHERE CAC.CaseID = CTR.CaseID
												AND CAC.EventID = CTR.EventID			-- CGR New linkage to include on EventID
											FOR XML PATH ('AcctAddrs'), TYPE
									),
									------------------------------------------------------------------------------------------------------------------------------------------																				
									(-- VhclAcctRels
										SELECT ( -- VhclAcctRel																					( 
											SELECT	( -- Vhcl
													SELECT RU.RegNum
													FOR XML PATH ('Vhcl'), TYPE
													)	
											FOR XML PATH ('VhclAcctRel'), TYPE
											)
										FROM #T_RegistrationUpdates RU
										WHERE RU.CaseID = CTR.CaseID
											AND (	(CTR.OrgName1 IS NOT NULL AND CTR.LstNm IS NULL)    -- Only output where either Organization OR Person exists but NOT both --V1.21
													OR  (CTR.OrgName1 IS NULL AND CTR.LstNm IS NOT NULL) )     
										FOR XML PATH ('VhclAcctRels'), TYPE
									),
									------------------------------------------------------------------------------------------------------------------------------------------																				
									(-- Tels --> mobile against the customer
										SELECT ( -- Email
											SELECT MN.PhNum,
												'Cell Phone' AS PhNumType
											FOR XML PATH ('Tel'), TYPE
											)	
										FROM #T_CustomerMobileCombined MN
										WHERE MN.CaseID = CTR.CaseID
											AND MN.EventID = CTR.EventID									-- CGR New linkage to include on EventID
											AND (    (CTR.OrgName1 IS NOT NULL AND CTR.LstNm IS NULL)		-- Only output where either Organization OR Person exists but NOT both --V1.21
													OR  (CTR.OrgName1 IS NULL AND CTR.LstNm IS NOT NULL) )  
										FOR XML PATH ('Tels'), TYPE
									),
									*/ -- V1.40 Add HrdBncCntr & SftBncCntr back in to output
									------------------------------------------------------------------------------------------------------------------------------------------																				
									(-- Emails 
										SELECT ( 
											SELECT (														-- V1.12
												/* -- V1.40
												SELECT (-- Email											--> Non CRM Emails + Customer Updates 
													SELECT EU.EmailAddr,
														'false' AS DoNotUseFlg
													FOR XML PATH ('Email'), TYPE
													)	
												FROM #T_CustomerEmailCombined EU
												WHERE EU.CaseID = CTR.CaseID
													AND EU.EventID = CTR.EventID							-- CGR New linkage to include on EventID
												),
											(
											*/ -- V1.40
												SELECT ( -- Email											--> Bouncebacks
													SELECT BB.EmailAddr,
														BB.HrdBncCntr,
														BB.SftBncCntr
													FOR XML PATH ('Email'), TYPE
													)	
												FROM #T_BounceBacks BB
												WHERE BB.CaseID = CTR.CaseID
												)
										FOR XML PATH ('Emails'), TYPE )
										WHERE (EXISTS (	SELECT * 
														FROM #T_BounceBacks BB								-- V1.12 - Add in additional check so that "Emails" is only output if
														WHERE BB.CaseID = CTR.CaseID ) )					--         there are email elements data to output.
												/* -- V1.40
												OR EXISTS (	SELECT * 
															FROM #T_CustomerEmailCombined EU
															WHERE EU.CaseID = CTR.CaseID
																AND EU.EventID = CTR.EventID ) )
												*/ -- V1.40
											AND ( (CTR.OrgName1 IS NOT NULL AND  CTR.LstNm IS NULL)			-- Only output where either Organization OR Person exists but NOT both  --V1.21
												OR (CTR.OrgName1 IS NULL AND  CTR.LstNm IS NOT NULL) )		--V1.21																											
									),
									------------------------------------------------------------------------------------------------------------------------------------------																				
										(-- Prmssns																		-- V1.18
										SELECT ( -- Prmssn
											SELECT PRM.PrmssnSupprType ,
												CONVERT(NVARCHAR(10), ISNULL(PRM.DtOfCnsnt, GETDATE()), 120) DtOfCnsnt,
												PRM.Cnsnt,
												PRM.FrmOfCnsnt
											FROM #T_Permissions PRM 
											WHERE PRM.CaseID = CTR.CaseID
											FOR XML PATH ('Prmssn'), TYPE
											)	
										WHERE EXISTS (	SELECT * 
														FROM #T_Permissions PRM 
														WHERE PRM.CaseID = CTR.CaseID)								-- Only output if permissions actually exist
											AND ( (CTR.OrgName1 IS NOT NULL AND CTR.LstNm IS NULL)					-- Only output where either Organization OR Person exists but NOT both  --V1.21
												OR  (CTR.OrgName1 IS NULL AND CTR.LstNm IS NOT NULL) )  
										FOR XML PATH ('Prmssns'), TYPE
										)
										/*
										,
										------------------------------------------------------------------------------------------------------------------------------------------
										( -- SrvyFlgs	
										SELECT ( -- SrvyFlg													-- V1.14
											SELECT FlgTyp,
												CTR.Manufacturer AS Brnd,
												1 AS FlgSts,
												CONVERT(NVARCHAR(10), ISNULL(ResponseDate, GETDATE()), 120) AS UpdDat
											FROM #T_SurveyFlags SV 
											WHERE SV.CaseID = CTR.CaseID
											FOR XML PATH ('SrvyFlg'), TYPE 
											)
										WHERE EXISTS (	SELECT * 
														FROM #T_SurveyFlags SV 
														WHERE SV.CaseID = CTR.CaseID ) -- Only output if flags actually exist
										FOR XML PATH ('SrvyFlgs'), TYPE 
										)
										------------------------------------------------------------------------------------------------------------------------------------------																				
										*/
								FOR XML PATH ('Acct'), TYPE
								),
								( -- Srvy
								SELECT CTR.Questionnaire AS SrvyTyp,
									CTR.DlrCd,														-- V1.19
									'Program'	AS Src,
									-- 'false'		AS JLRCntctRqstd,								-- V1.10 
									( -- Ints	
									SELECT 
										(	SELECT R.QuestionNumber AS IntNumb,
												R.QuestionText AS IntText,
												R.Response AS IntResp
											FROM [$(SampleDB)].Event.CaseCRMResponses R
											WHERE R.CaseID = CTR.CaseID
											FOR XML PATH ('Int'), TYPE 
											) 
									FOR XML PATH ('Ints'), TYPE	
									),
									( -- SrvyDts	
									SELECT 
									(	SELECT 'Survey Date' AS DtTyp,
											CONVERT(NVARCHAR(10), ISNULL(C.ClosureDate, GETDATE()), 120) AS Dt		-- <<< What if no date set???
										FROM [$(SampleDB)].Event.Cases C 
										WHERE C.CaseID = CTR.CaseID
										FOR XML PATH ('SrvyDt'), TYPE 
										)							-- V1.18
									FOR XML PATH ('SrvyDts'), TYPE 
									),
									VsbltyStts														-- V1.14  
								WHERE EXISTS (	SELECT TOP 1 * 
												FROM [$(SampleDB)].Event.CaseCRMResponses R
												WHERE R.CaseID = CTR.CaseID)						-- Only output if we have responses
								FOR XML PATH ('Srvy'), TYPE
								)
							FOR XML PATH ('CmpgnEvntResp'), TYPE 
							)
						FOR XML PATH ('Cmpgn'), TYPE
						)
					FROM #T_CampaignResponsesCustomerInfo CTR
					FOR XML PATH ('createOrUpdateCampaignEventandResponse'), TYPE
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
	SET B.OutputResponseStatusID = CI.ResponseStatusID ,
		B.LoadToConnexionsDate = CI.LoadedToConnexions ,
		B.Bounceback = CASE WHEN BB.CaseID IS NOT NULL THEN 1 
							ELSE 0 END
	FROM #T_CampaignResponsesCustomerInfo CI
		INNER JOIN CRM.OutputBatches B ON B.CaseID = CI.CaseID 
										AND B.EventID = CI.EventID
		LEFT JOIN #T_BounceBacks BB ON BB.CaseID = CI.CaseID


	--------------------------------------------------------------------------------------------------
	-- Convert and Concatenate the various parts of the XML
	--------------------------------------------------------------------------------------------------
	SET @NVC_BatchHeader =  CONVERT(NVARCHAR(max), @XML_BatchHeader) 
	SET @NVC_BatchBody   =  CONVERT(NVARCHAR(max), @XML_BatchBody) 

	SET @NVC_FileTop = '<?xml version="1.0" encoding="UTF-8"?><mssext:createOrUpdateCampaignEventandResponseBatch xsi:schemaLocation="http://jlrint.com/mss/message/createorupdatecampaigneventandresponse/1 CRM_S0400CreateOrUpdateCampaignEventAndResponseMessage.xsd" xmlns:mssext="http://jlrint.com/mss/message/createorupdatecampaigneventandresponse/1" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'
	SET @NVC_FileBottom = '</mssext:createOrUpdateCampaignEventandResponseBatch>'
		
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

