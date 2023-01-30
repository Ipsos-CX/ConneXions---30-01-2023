CREATE PROCEDURE [dbo].[uspCalculateSampleQuality]

AS

/*
		Purpose:	Produce file row counts for the service disposition report 
		
		Version		Date			Developer			Comment
LIVE	1.0			$(ReleaseDate)						Created
LIVE	1.1			30/04/2013		Chris Ross			BUG 8766 
														- Add in check and flag for OwnershipCycle
														- Update selection window check to use datepart only 
														  of LoadedDate as time part interfering with comparisons.
														- Ensure all updates are for event we are loading from current VWT only.
														(Interim versions taken out as not completed/tested - CGR 10/02/2014)
LIVE	1.4			24/01/2014		Chris Ross			BUG 9500 - Set flag for SuppliedMobilePhone															
LIVE	1.5			27/02/2014		Ali yuksel			BUG 10039 - Fixed PartyNonSolicitation flag
LIVE	1.6			14/05/2014		Ali Yuksel			BUG 10346 - EventDateOutOfDate fixed for null values
LIVE	1.7			17/06/2014		Ali Yuksel			BUG 10436 - InvalidManufacturer added
LIVE	1.8			09/10/2014		Chris Ross			BUG 6061 - Modified the Unmatched model check to look at the model ID via the Vehicle  
																   table rather than what was set during matching.  This was causing the unmatched
																   model flag to be set incorrectly as the model maybe different for previously
																   entered vehicles.  (And this is a problem when dealing with "CRC Unknown Vehicle" 
																   models on CRC dummy vehicles.)
LIVE	1.9			28-11-2014		Chris Ross			BUG 10916 - The previous bug (1.8) can stay in place as general fix, i.e. no need to branch.
																    Added in update for Global Sample Loader which links to BMQ on country and manufacturer
																	as well,
LIVE	2.0			12/12/2014		Eddie Thomas		BUG 11047 - (a) Changed Logic of EventDateOutOfDate to ONLY flag events that are too old.
																	(b) Update new flag EventDateTooYoung
LIVE	2.1			29/04/2015		Chris Ross			BUG 6061 - Modified to set the Market and Questionnaire information correctly for 
																   CRC and Roadside.  Also, to set 'Uncoded Dealer' flag if CRCCentrePartyID or 
																   RoadsideNetworkPartyID not set.
LIVE	2.2			26/02/2016		Chris Ross			BUG 12353 - Modify Out of date range checks to use getdate() not Loaded date.
LIVE	2.3			06/05/2016		Chris Ledger		BUG 12635 - Set AddressSupplied to 0 if no street and StreetOrEmailRequired = 1
LIVE	2.4			17/11/2016		Chris Ledger		BUG 13280 - Update for CRM loaders links to BMQ on country and manufacturer
																	as well.
LIVE	2.5			17/11/2017		Chris Ledger		BUG 14347 - Set InterCompanyOwnUseDealer to UnMatchedDealer 
LIVE	2.6			24/01/2018		Chris Ross			BUG 14435 - Store logging update values until the end so that only a single write to the SampleQualityAndSelectionLogging table is performed.
LIVE	2.7			29/10/2018		Chris Ledger		BUG 15056 - Add I-Assistance
LIVE	2.8			15/10/2019		Chris Ledger		BUG 15171 - Add Supplied Checks for Roadside Events
LIVE	2.9			29/10/2019		Chris Ledger		BUG 15490 - Split GSL_LostLeads Out as it includes LostLeads and PreOwned LostLeads
LIVE	2.10		04/11/2019		Chris Ledger		BUG 16377 - Only Code GSL_LostLeads to PreOwned LostLeads if CountryID = 219
LIVE	2.11		14/11/2019		Ben King			BUG 16767 - Remove Barred Email in SP [dbo].[uspCalculateSampleQuality]
LIVE	2.12		30/01/2021		Eddie Thomas		BUG 18080 - Adding BMQ information for CXP files
LIVE	2.13		18/02/2021		Ben King			BUG 18039 - Belgium and Netherlands Market Specific Loader
LIVE	2.14		19/03/2021		Chris Ledger		TASK 299 - Add CRC General Enquiry
LIVE	2.15		04/05/2021		Chris Ledger		TASK 387 - Modify out of date ranges for CQI to use this Monday's date rather than GETDATE().
LIVE	2.16		05/05/2021      Ben King            BUG 18203 - Global Low Coutries Loader - Fix bug updating Logging table
LIVE	2.17		10/06/2021      Ben King			TASK 474 - InvalidDealerBrand Flag
LIVE	2.18		10/02/2022		Chris Ledger		TASK 628 - Don't set UnmatchedModel flag for CRC/General Enquiry
LIVE	2.19		10/02/2022		Chris Ledger		TASK 628 - Set EventAlreadySelected flag if CaseID exists
LIVE	2.20		02/03/2022		Chris Ledger		TASK 791 - Set UK Land Rover Sales QuestionnaireRequirementID & Start/End Days based on ModelVariantID
LIVE    2.21		17/06/2022      Ben King            TASK 927 - 19509 - Sample Health - Incorrect / Missing VIN
LIVE	2.22		20/06/2022		Chris Ledger		TASK 917 - Add CQI 1MIS
LIVE	2.23		04/08/2022		Eddie Thomas		TASK 877 - New study Land Rover Experience
LIVE	2.24		15/08/2022		Eddie Thomas		TASK 980 / BugTracker 19546 - Special Selection Window for Range Rover Sport (L461)
*/

SET NOCOUNT ON


DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY


	-- CREATE AND POPULATE TEMP TABLE WHICH HOLDS LOGGING VALUES SO WE CAN APPLY A SINGLE UPDATE AT THE END			-- V2.6
	CREATE TABLE #LoggingValues
	(	
		AuditItemID				BIGINT,
		Brand					NVARCHAR(510),
		Market					VARCHAR(200),
		Questionnaire 			VARCHAR(255),
		QuestionnaireRequirementID INT,
		StartDays				INT,
		EndDays					INT,
		SuppliedName			BIT,
		SuppliedAddress			BIT,
		SuppliedPhoneNumber		BIT,
		SuppliedMobilePhone		BIT,
		SuppliedEmail			BIT,
		SuppliedEventDate		BIT,
		EventDateOutOfDate		BIT,
		EventDateTooYoung		BIT,
		InvalidEmailAddress		BIT,
		PartyNonSolicitation	BIT,
		EventNonSolicitation	BIT,
		UncodedDealer			BIT,
		UnmatchedModel			BIT,
		BarredEmailAddress		BIT,
		InvalidManufacturer		BIT,
		SalesDealerID			INT,
		SampleRowProcessed		BIT,
		SampleRowProcessedDate	DATETIME,
		InvalidDealerBrand		BIT,
		EventAlreadySelected	BIT
	)

	INSERT INTO #LoggingValues (AuditItemID, SalesDealerID)
	SELECT V.AuditItemID, SL.SalesDealerID 
	FROM [$(ETLDB)].dbo.VWT V
		INNER JOIN dbo.SampleQualityAndSelectionLogging SL ON SL.AuditItemID = V.AuditItemID
				

	-- SET THE BRAND
	UPDATE LV
	SET LV.Brand = B.Brand
	FROM dbo.SampleQualityAndSelectionLogging S
		INNER JOIN [$(ETLDB)].dbo.VWT V ON V.AuditItemID = S.AuditItemID		-- V1.2
		INNER JOIN #LoggingValues LV ON LV.AuditItemID = V.AuditItemID			-- V2.6
		INNER JOIN [$(SampleDB)].dbo.Brands B ON B.ManufacturerPartyID = S.ManufacturerID


	-- FOR MARKET SPECIFIC SAMPLE FILES USE THE FILENAME TO GET THE MARKET, QUESTIONNAIRE AND EVENT DATE RANGE INFORMATION
	UPDATE LV
	SET  LV.Market = BMQ.Market
		,LV.Questionnaire = BMQ.Questionnaire
		,LV.QuestionnaireRequirementID = BMQ.QuestionnaireRequirementID
		,LV.StartDays = QR.StartDays
		,LV.EndDays = QR.EndDays
	FROM dbo.SampleQualityAndSelectionLogging S
		INNER JOIN [$(ETLDB)].dbo.VWT V ON V.AuditItemID = S.AuditItemID		-- V1.2
		INNER JOIN #LoggingValues LV ON LV.AuditItemID = V.AuditItemID			-- V2.6
		INNER JOIN [$(AuditDB)].dbo.Files F ON F.AuditID = S.AuditID
		INNER JOIN [$(SampleDB)].dbo.vwBrandMarketQuestionnaireSampleMetadata BMQ ON F.FileName LIKE BMQ.SampleFileNamePrefix + '%'
		INNER JOIN [$(SampleDB)].Requirement.QuestionnaireRequirements QR ON QR.RequirementID = BMQ.QuestionnaireRequirementID
	WHERE BMQ.SampleFileNamePrefix <> 'Combined_DDW_Service'
		AND BMQ.SampleFileNamePrefix <> 'Jaguar_Cupid_Sales'
		AND BMQ.SampleFileNamePrefix NOT LIKE 'GSL_%'					-- V1.9 Ignore for Global Sample Loader
		AND BMQ.SampleFileNamePrefix NOT LIKE 'GLCL_%'					-- V2.13
		AND BMQ.SampleFileNamePrefix NOT LIKE 'CSD_%'					-- V2.4 Ignore for CSD Loaders
		AND BMQ.SampleFileNamePrefix NOT LIKE 'GFK_%'					-- V2.9 Ignore for CXP Loaders
		AND BMQ.SampleLoadActive = 1
		AND BMQ.Questionnaire NOT IN ('Roadside', 'CRC', 'I-Assistance', 'CRC General Enquiry')			-- V2.1 V2.7 V2.14 -- Roadside, CRC, I-Assistance and CRC General Enquiry are processed seperately


	-- GET THE MARKET AND QUESTIONNAIRE INFORMATION FOR GLOBAL SAMPLE LOADER FILES	(EXCLUDING LOST LEADS)		-- V1.9
	UPDATE LV
	SET  LV.Market = BMQ.Market
		,LV.Questionnaire = BMQ.Questionnaire
		,LV.QuestionnaireRequirementID = BMQ.QuestionnaireRequirementID
		,LV.StartDays = QR.StartDays
		,LV.EndDays = QR.EndDays
	FROM dbo.SampleQualityAndSelectionLogging S
		INNER JOIN [$(ETLDB)].[dbo].[VWT] V ON V.AuditItemID = S.AuditItemID	
		INNER JOIN #LoggingValues LV ON LV.AuditItemID = V.AuditItemID						-- V2.6
		INNER JOIN [$(AuditDB)].dbo.Files F ON F.AuditID = S.AuditID 
		INNER JOIN [$(SampleDB)].dbo.vwBrandMarketQuestionnaireSampleMetadata BMQ ON F.FileName LIKE BMQ.SampleFileNamePrefix + '%'
		INNER JOIN [$(SampleDB)].Requirement.QuestionnaireRequirements QR ON QR.RequirementID = BMQ.QuestionnaireRequirementID
	WHERE (BMQ.SampleFileNamePrefix LIKE 'GSL_%') 
		AND BMQ.SampleFileNamePrefix NOT LIKE 'GSL_LostLeads%'								-- V2.9
		AND BMQ.SampleLoadActive = 1
		AND BMQ.CountryID = V.CountryID
		AND BMQ.ManufacturerPartyID = V.ManufacturerID

	-- 2.16
	UPDATE LV
	SET  LV.Market = BMQ.Market
		,LV.Questionnaire = BMQ.Questionnaire
		,LV.QuestionnaireRequirementID = BMQ.QuestionnaireRequirementID
		,LV.StartDays = QR.StartDays
		,LV.EndDays = QR.EndDays
	FROM dbo.SampleQualityAndSelectionLogging S
		INNER JOIN [$(ETLDB)].[dbo].[VWT] V ON V.AuditItemID = S.AuditItemID	
		INNER JOIN #LoggingValues LV ON LV.AuditItemID = V.AuditItemID						-- V2.6
		INNER JOIN [$(AuditDB)].dbo.Files F ON F.AuditID = S.AuditID 
		INNER JOIN [$(SampleDB)].dbo.vwBrandMarketQuestionnaireSampleMetadata BMQ ON F.FileName LIKE BMQ.SampleFileNamePrefix + '%'
		INNER JOIN [$(SampleDB)].Event.EventTypes E ON BMQ.Questionnaire = E.EventType
		INNER JOIN [$(SampleDB)].Requirement.QuestionnaireRequirements QR ON QR.RequirementID = BMQ.QuestionnaireRequirementID
	WHERE (BMQ.SampleFileNamePrefix LIKE 'GLCL_%') -- V2.13
		AND BMQ.SampleFileNamePrefix NOT LIKE 'GSL_LostLeads%'								-- V2.9
		AND BMQ.SampleLoadActive = 1
		AND BMQ.CountryID = V.CountryID
		AND V.ODSEventTypeID = E.EventTypeID
		AND BMQ.ManufacturerPartyID = V.ManufacturerID


	-- GET THE MARKET AND QUESTIONNAIRE INFORMATION FOR CRM LOADERS			-- V2.4
	UPDATE LV
	SET  LV.Market = BMQ.Market
		,LV.Questionnaire = BMQ.Questionnaire
		,LV.QuestionnaireRequirementID = BMQ.QuestionnaireRequirementID
		,LV.StartDays = QR.StartDays
		,LV.EndDays = QR.EndDays
	FROM dbo.SampleQualityAndSelectionLogging S
		INNER JOIN [$(ETLDB)].[dbo].[VWT] V ON V.AuditItemID = S.AuditItemID	
		INNER JOIN #LoggingValues LV ON LV.AuditItemID = V.AuditItemID	-- V2.6
		INNER JOIN [$(AuditDB)].dbo.Files F ON F.AuditID = S.AuditID 
		INNER JOIN [$(SampleDB)].dbo.vwBrandMarketQuestionnaireSampleMetadata BMQ ON F.FileName LIKE BMQ.SampleFileNamePrefix + '%'
		INNER JOIN [$(SampleDB)].Requirement.QuestionnaireRequirements QR ON QR.RequirementID = BMQ.QuestionnaireRequirementID
		INNER JOIN [$(SampleDB)].Requirement.Requirements R ON QR.RequirementID = R.RequirementID								-- V2.20
	WHERE BMQ.SampleFileNamePrefix LIKE 'CSD_%'
		AND BMQ.SampleLoadActive = 1
		AND BMQ.CountryID = V.CountryID
		AND BMQ.ManufacturerPartyID = V.ManufacturerID
		AND R.Requirement NOT LIKE '%L460'					-- V2.20 Ignore L460 requirements
		AND R.Requirement NOT LIKE '%L461'					-- V2.24 Ignore L461 requirements

	-- V2.20 UPDATE QUESTIONNARE INFORMATION FOR UK LAND ROVER SALES L460/L461 ON VARIANT
	UPDATE LV
	SET  LV.QuestionnaireRequirementID = BMQ.QuestionnaireRequirementID
		,LV.StartDays = QR.StartDays
		,LV.EndDays = QR.EndDays
	FROM dbo.SampleQualityAndSelectionLogging S
		INNER JOIN [$(ETLDB)].[dbo].[VWT] V ON V.AuditItemID = S.AuditItemID	
		INNER JOIN #LoggingValues LV ON LV.AuditItemID = V.AuditItemID
		INNER JOIN [$(AuditDB)].dbo.Files F ON F.AuditID = S.AuditID 
		INNER JOIN [$(SampleDB)].dbo.vwBrandMarketQuestionnaireSampleMetadata BMQ ON F.FileName LIKE BMQ.SampleFileNamePrefix + '%'
		INNER JOIN [$(SampleDB)].Requirement.QuestionnaireRequirements QR ON QR.RequirementID = BMQ.QuestionnaireRequirementID
		INNER JOIN [$(SampleDB)].Requirement.QuestionnaireModelRequirements QMR ON QR.RequirementID = QMR.RequirementIDPartOf		-- V2.20
		INNER JOIN [$(SampleDB)].Requirement.ModelRequirements MR ON MR.RequirementID = QMR.RequirementIDMadeUpOf					-- V2.20
		INNER JOIN [$(SampleDB)].Vehicle.Models M ON MR.ModelID = M.ModelID															-- V2.20
		INNER JOIN [$(SampleDB)].Requirement.QuestionnaireVariantRequirements QVR ON QR.RequirementID = QVR.RequirementIDPartOf		-- V2.20
		INNER JOIN [$(SampleDB)].Requirement.VariantRequirements VR ON VR.RequirementID = QVR.RequirementIDMadeUpOf					-- V2.20
		INNER JOIN [$(SampleDB)].Vehicle.ModelVariants MV ON VR.VariantID = MV.VariantID											-- V2.20
		INNER JOIN [$(SampleDB)].Vehicle.Vehicles VH ON V.MatchedODSVehicleID = VH.VehicleID										-- V2.20
		INNER JOIN [$(SampleDB)].Vehicle.Models M1 ON VH.ModelID = M1.ModelID														-- V2.20
		INNER JOIN [$(SampleDB)].Vehicle.ModelVariants MV1 ON VH.ModelVariantID = MV1.VariantID										-- V2.20
	WHERE BMQ.SampleFileNamePrefix LIKE 'CSD_%'
		AND BMQ.SampleLoadActive = 1
		AND BMQ.CountryID = V.CountryID
		AND BMQ.ManufacturerPartyID = V.ManufacturerID
		AND M.ModelID = M1.ModelID								-- V2.20 --V2.24
		AND MV.VariantID = MV1.VariantID						-- V2.20 --V2.24
		
		
	-- GET THE MARKET AND QUESTIONNAIRE INFORMATION FOR CRC AND ROADSIDE AND IASSISTANCE		-- V2.1
	UPDATE LV
	SET  LV.Market = BMQ.Market
		,LV.Questionnaire = BMQ.Questionnaire
		,LV.QuestionnaireRequirementID = BMQ.QuestionnaireRequirementID
		,LV.StartDays = QR.StartDays
		,LV.EndDays = QR.EndDays
	FROM dbo.SampleQualityAndSelectionLogging S
		INNER JOIN [$(ETLDB)].dbo.VWT V ON V.AuditItemID = S.AuditItemID
		INNER JOIN #LoggingValues LV ON LV.AuditItemID = V.AuditItemID	-- V2.6
		INNER JOIN [$(AuditDB)].dbo.Files F ON F.AuditID = S.AuditID
		INNER JOIN [$(SampleDB)].dbo.Brands B ON B.ManufacturerPartyID = V.ManufacturerID	-- get the brand 
		INNER JOIN [$(SampleDB)].dbo.vwBrandMarketQuestionnaireSampleMetadata BMQ ON F.FileName LIKE BMQ.SampleFileNamePrefix + '%'
																				AND BMQ.CountryID = V.CountryID		 -- ensure brand and market match as the loaders are generic
																				AND BMQ.Brand = B.Brand
		INNER JOIN [$(SampleDB)].Requirement.QuestionnaireRequirements QR ON QR.RequirementID = BMQ.QuestionnaireRequirementID 
	WHERE BMQ.Questionnaire IN ('Roadside', 'CRC', 'I-Assistance', 'CRC General Enquiry')				-- V2.7 V2.14
	

	-- GET THE MARKET AND QUESTIONNAIRE INFORMATION FOR WARRANTY FILES
	UPDATE LV
	SET  LV.Market = M.Market
		,LV.Questionnaire = 'Service'
	FROM dbo.SampleQualityAndSelectionLogging S
		INNER JOIN [$(ETLDB)].dbo.VWT V ON V.AuditItemID = S.AuditItemID		-- V1.2
		INNER JOIN #LoggingValues LV ON LV.AuditItemID = V.AuditItemID			-- V2.6
		INNER JOIN [$(AuditDB)].dbo.Files F ON F.AuditID = S.AuditID
		INNER JOIN [$(SampleDB)].dbo.Markets M ON M.CountryID = S.CountryID
	WHERE S.ODSEventTypeID = (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventType = 'Warranty')
		AND F.FileName LIKE '%Combined_DDW_Service%'

	
	-- GET THE MARKET AND QUESTIONNAIRE INFORMATION FOR CUPID FILES
	UPDATE LV
	SET  LV.Market = M.Market
		,LV.Questionnaire = 'Sales'
	FROM dbo.SampleQualityAndSelectionLogging S
		INNER JOIN [$(ETLDB)].dbo.VWT V ON V.AuditItemID = S.AuditItemID		-- V1.2
		INNER JOIN #LoggingValues LV ON LV.AuditItemID = V.AuditItemID			-- V2.6
		INNER JOIN [$(AuditDB)].dbo.Files F ON F.AuditID = S.AuditID
		INNER JOIN [$(SampleDB)].dbo.Markets M ON M.CountryID = S.CountryID
	WHERE F.FileName LIKE '%Jaguar_Cupid_Sales%'

	
	-- GET THE EVENT DATE RANGE INFORMATION FOR WARRANTY AND CUPID FILES
	UPDATE LV
	SET  LV.QuestionnaireRequirementID = BMQ.QuestionnaireRequirementID
		,LV.StartDays = QR.StartDays
		,LV.EndDays = QR.EndDays
	FROM dbo.SampleQualityAndSelectionLogging S
		INNER JOIN [$(ETLDB)].dbo.VWT V ON V.AuditItemID = S.AuditItemID		-- V1.2
		INNER JOIN #LoggingValues LV ON LV.AuditItemID = V.AuditItemID			-- V2.6
		INNER JOIN [$(AuditDB)].dbo.Files F ON F.AuditID = S.AuditID
		LEFT JOIN [$(SampleDB)].dbo.vwBrandMarketQuestionnaireSampleMetadata BMQ ON BMQ.Brand = S.Brand
																			AND BMQ.Market = S.Market
																			AND BMQ.Questionnaire = S.Questionnaire
																			AND BMQ.SampleLoadActive = 1
		INNER JOIN [$(SampleDB)].Requirement.QuestionnaireRequirements QR ON QR.RequirementID = BMQ.QuestionnaireRequirementID
	WHERE ( F.FileName LIKE '%Combined_DDW_Service%'
		OR F.FileName LIKE '%Jaguar_Cupid_Sales%' )


	-- GET THE MARKET AND QUESTIONNAIRE INFORMATION FOR LOSTLEADS FILES			-- V2.9
	UPDATE LV
	SET  LV.Market = BMQ.Market
		,LV.Questionnaire = BMQ.Questionnaire
		,LV.QuestionnaireRequirementID = BMQ.QuestionnaireRequirementID
		,LV.StartDays = QR.StartDays
		,LV.EndDays = QR.EndDays
	FROM dbo.SampleQualityAndSelectionLogging S
		INNER JOIN [$(ETLDB)].[dbo].[VWT] V ON V.AuditItemID = S.AuditItemID	
		INNER JOIN #LoggingValues LV ON LV.AuditItemID = V.AuditItemID
		INNER JOIN [$(AuditDB)].dbo.Files F ON F.AuditID = S.AuditID 
		INNER JOIN [$(SampleDB)].dbo.vwBrandMarketQuestionnaireSampleMetadata BMQ ON F.FileName LIKE BMQ.SampleFileNamePrefix + '%'
		INNER JOIN [$(SampleDB)].Requirement.QuestionnaireRequirements QR ON QR.RequirementID = BMQ.QuestionnaireRequirementID
	WHERE BMQ.SampleFileNamePrefix LIKE 'GSL_LostLeads%'		
		AND BMQ.SampleLoadActive = 1
		AND BMQ.CountryID = V.CountryID
		AND BMQ.ManufacturerPartyID = V.ManufacturerID
		AND BMQ.Questionnaire = CASE	WHEN V.JLRSuppliedEventType = 2 AND V.CountryID = 219 THEN 'PreOwned LostLeads' 
										ELSE 'LostLeads' END		-- V2.10


	-- GET THE MARKET AND QUESTIONNAIRE INFORMATION FOR CXP FILES			-- V2.9
	UPDATE LV
	SET  LV.Market = BMQ.Market
		,LV.Questionnaire = BMQ.Questionnaire
		,LV.QuestionnaireRequirementID = BMQ.QuestionnaireRequirementID
		,LV.StartDays = QR.StartDays
		,LV.EndDays = QR.EndDays
	FROM WebsiteReporting.dbo.SampleQualityAndSelectionLogging S
		INNER JOIN [Sample_ETL].[dbo].[VWT] V ON V.AuditItemID = S.AuditItemID	
		INNER JOIN #LoggingValues LV ON LV.AuditItemID = V.AuditItemID	-- V2.6
		INNER JOIN [Sample_Audit].dbo.Files F ON F.AuditID = S.AuditID 
		INNER JOIN [Sample].dbo.vwBrandMarketQuestionnaireSampleMetadata BMQ ON F.FileName LIKE BMQ.SampleFileNamePrefix + '%'
		INNER JOIN [Sample].Requirement.QuestionnaireRequirements QR ON QR.RequirementID = BMQ.QuestionnaireRequirementID
	WHERE BMQ.SampleFileNamePrefix LIKE 'Gfk_%'
		AND BMQ.SampleLoadActive = 1
		AND BMQ.CountryID = V.CountryID
		AND BMQ.ManufacturerPartyID = V.ManufacturerID


	-- CHECK WE HAVE NAME OR COMPANY INFORMATION
	UPDATE LV 
	SET LV.SuppliedName = 1
	FROM #LoggingValues	LV				-- V1.26
		INNER JOIN [$(ETLDB)].dbo.VWT V ON V.AuditItemID = LV.AuditItemID
	WHERE ISNULL(V.LastName, '') <> ''

	UPDATE LV SET LV.SuppliedName = 1
	FROM #LoggingValues  LV					-- V1.26
		INNER JOIN [$(ETLDB)].dbo.VWT V ON V.AuditItemID = LV.AuditItemID
	WHERE ISNULL(V.OrganisationName, '') <> ''


	-- V2.8 EXTRA CHECK FOR ROADSIDE BASED ON ROADSIDEEVENTS FILE
	UPDATE LV 
	SET LV.SuppliedName = 1
	FROM #LoggingValues	LV
		INNER JOIN [$(ETLDB)].Roadside.RoadsideEvents RE ON LV.AuditItemID = RE.AuditItemID
	WHERE ISNULL(RE.SurnameField1, '')  <> ''


	-- -- CHECK WE HAVE ADDRESS INFORMATION
	-- FOR SOME MARKETS WE NEED JUST STREET DATA FOR SOME WE NEED BOTH STREET AND POSTCODE
	UPDATE LV 
	SET LV.SuppliedAddress = 1
	FROM #LoggingValues	LV				-- V1.26
		INNER JOIN [$(SampleDB)].dbo.vwBrandMarketQuestionnaireSampleMetadata BMQ ON BMQ.Brand = LV.Brand AND BMQ.Market = LV.Market AND BMQ.Questionnaire = LV.Questionnaire
		INNER JOIN [$(ETLDB)].dbo.VWT V ON V.AuditItemID = LV.AuditItemID
	WHERE
		CASE		-- If no flags set we just assume that having a street constitutes having an address 
			WHEN BMQ.StreetRequired = 0 AND BMQ.PostcodeRequired = 0 AND BMQ.StreetOrEmailRequired = 0 THEN ISNULL(V.Street, '') 
			ELSE 'Street' 
			END <> ''
		AND CASE		-- If Street required is set check for street again 
			WHEN BMQ.StreetRequired = 1 THEN ISNULL(V.Street, '')
			ELSE 'Street'
			END <> ''
		AND CASE
			WHEN BMQ.PostcodeRequired = 1 THEN ISNULL(V.Postcode, '')
			ELSE 'Postcode'
			END <> ''
		AND CASE
			WHEN BMQ.StreetOrEmailRequired = 1 THEN ISNULL(V.Street, '')
			ELSE 'Street'
			END <> ''


	-- V2.8 EXTRA CHECK FOR ROADSIDE BASED ON ROADSIDEEVENTS FILE
	UPDATE LV 
	SET LV.SuppliedAddress = 1
	FROM #LoggingValues	LV
		INNER JOIN [$(ETLDB)].Roadside.RoadsideEvents RE ON LV.AuditItemID = RE.AuditItemID
	WHERE ISNULL(RE.Address1, '')  <> ''


	-- CHECK FOR SUPPLIED PHONE NUMBER
	UPDATE LV 
	SET LV.SuppliedPhoneNumber = 1
	FROM dbo.SampleQualityAndSelectionLogging S
		INNER JOIN [$(ETLDB)].dbo.VWT V ON V.AuditItemID = S.AuditItemID
		INNER JOIN #LoggingValues LV ON LV.AuditItemID = V.AuditItemID		-- V2.6
	WHERE COALESCE(S.MatchedODSTelID, S.MatchedODSPrivTelID, S.MatchedODSBusTelID, S.MatchedODSMobileTelID, S.MatchedODSPrivMobileTelID, 0) > 0


	-- V2.8 EXTRA CHECK FOR ROADSIDE BASED ON ROADSIDEEVENTS FILE
	UPDATE LV 
	SET LV.SuppliedPhoneNumber = 1
	FROM #LoggingValues	LV
		INNER JOIN [$(ETLDB)].Roadside.RoadsideEvents RE ON LV.AuditItemID = RE.AuditItemID
	WHERE ISNULL(RE.MobileTelephoneNumber, '') <> '' 
		OR ISNULL(RE.HomeTelephoneNumber, '') <> ''
	

	-- CHECK FOR SUPPLIED MOBILE PHONE NUMBER			-- V1.4
	UPDATE LV 
	SET LV.SuppliedMobilePhone = 1
	FROM dbo.SampleQualityAndSelectionLogging S
		INNER JOIN [$(ETLDB)].dbo.VWT V ON V.AuditItemID = S.AuditItemID
		INNER JOIN #LoggingValues LV ON LV.AuditItemID = V.AuditItemID		-- V2.6
	WHERE COALESCE(S.MatchedODSMobileTelID, S.MatchedODSPrivMobileTelID, 0) > 0


	-- V2.8 EXTRA CHECK FOR ROADSIDE BASED ON ROADSIDEEVENTS FILE
	UPDATE LV 
	SET LV.SuppliedMobilePhone = 1
	FROM #LoggingValues	LV
		INNER JOIN [$(ETLDB)].Roadside.RoadsideEvents RE ON LV.AuditItemID = RE.AuditItemID
	WHERE ISNULL(RE.MobileTelephoneNumber, '')  <> ''


	-- CHECK FOR SUPPLIED EMAIL
	UPDATE LV 
	SET LV.SuppliedEmail = 1
	FROM dbo.SampleQualityAndSelectionLogging S
		INNER JOIN [$(ETLDB)].dbo.VWT V ON V.AuditItemID = S.AuditItemID
		INNER JOIN #LoggingValues LV ON LV.AuditItemID = V.AuditItemID		-- V2.6
	WHERE COALESCE(S.MatchedODSEmailAddressID, S.MatchedODSPrivEmailAddressID, 0) > 0

	
	-- V2.8 EXTRA CHECK FOR ROADSIDE BASED ON ROADSIDEEVENTS FILE
	UPDATE LV 
	SET LV.SuppliedEmail = 1
	FROM #LoggingValues	LV
	INNER JOIN [$(ETLDB)].Roadside.RoadsideEvents RE ON LV.AuditItemID = RE.AuditItemID
	WHERE ISNULL(RE.EmailAddress1, '')  <> '' 
		OR ISNULL(RE.EmailAddress2, '')  <> ''
	
	
	-- CHECK FOR SUPPLIED EVENT DATE
	UPDATE LV 
	SET LV.SuppliedEventDate = 1
	FROM #LoggingValues LV			-- V1.26
		INNER JOIN [$(AuditDB)].Audit.Events AE ON AE.AuditItemID = LV.AuditItemID
	WHERE AE.EventDate IS NOT NULL

	
	-- CHECK FOR OUT OF RANGE EVENT DATE (EventDateTooOld)
	-- IN THIS CASE WE WILL NEVER SELECT THE RECORD SO SET IT TO BEING PROCESSED 
	--   Note: The record might still be selected if there is a valid registration date that can be used.
	-- V2.0 - This flag has been modified to only record where the Event Date is too OLD
	UPDATE LV
	SET  LV.EventDateOutOfDate = 1
		,LV.SampleRowProcessed = 1
		,LV.SampleRowProcessedDate = GETDATE()
	FROM #LoggingValues LV   -- V1.26
		INNER JOIN [$(AuditDB)].Audit.Events AE ON AE.AuditItemID = LV.AuditItemID
		INNER JOIN [$(ETLDB)].dbo.VWT V ON V.AuditItemID = LV.AuditItemID
	WHERE AE.EventDate < CASE	WHEN LV.Questionnaire IN ('CQI 1MIS','CQI 3MIS','CQI 24MIS') THEN DATEADD(D, LV.EndDays, DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE() - 1), 0))	-- V2.15, V2.22
								ELSE DATEADD(D, LV.EndDays, CAST(GETDATE() AS DATE)) END	-- V1.2 use the cast to get just the date part as 
		--OR AE.EventDate > DATEADD(D, S.StartDays, CAST(S.LoadedDate AS DATE))				-- ==== the time was throuwing the comparison out.
		OR AE.EventDate IS NULL																-- V1.6 - EventDate fixed for null values
	
	
	-- CHECK FOR OUT OF RANGE EVENT DATE (EventDateTooYoung)
	-- IN THIS CASE WE WILL NEVER SELECT THE RECORD SO SET IT TO BEING PROCESSED 
	--   Note: The record might still be selected if there is a valid registration date that can be used.
	-- V2.0 - This flag has been Added flag when the Event Date is too Young
	UPDATE LV
	SET  LV.EventDateTooYoung = 1
		,LV.SampleRowProcessed = 1
		,LV.SampleRowProcessedDate = GETDATE()
	FROM #LoggingValues LV   -- V1.26
		INNER JOIN [$(AuditDB)].Audit.Events AE ON AE.AuditItemID = LV.AuditItemID
		INNER JOIN [$(ETLDB)].dbo.VWT V ON V.AuditItemID = LV.AuditItemID
	WHERE AE.EventDate > CASE	WHEN LV.Questionnaire IN ('CQI 1MIS','CQI 3MIS','CQI 24MIS') THEN DATEADD(D, LV.StartDays, DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE() - 1), 0))	-- V2.15, V2.22
								ELSE DATEADD(D, LV.StartDays, CAST(GETDATE() AS DATE)) END	-- V1.2 use the cast to get just the date part as the time was throuwing the comparison out.
		--OR AE.EventDate IS NULL															-- V1.6 - EventDate fixed for null values

		
	-- CHECK FOR INVALID OWNERSHIP CYCLE				-- V1.2
	UPDATE	LV
	SET		LV.InvalidEmailAddress = 1,
			LV.SampleRowProcessed = 1,
			LV.SampleRowProcessedDate = GETDATE()
	FROM dbo.SampleQualityAndSelectionLogging S	
		INNER JOIN [$(ETLDB)].dbo.VWT V ON V.AuditItemID = S.AuditItemID		-- V1.2
		INNER JOIN #LoggingValues LV ON LV.AuditItemID = V.AuditItemID			-- V2.6
		INNER JOIN [$(SampleDB)].ContactMechanism.EmailAddresses EA ON EA.ContactMechanismID = S.MatchedODSEmailAddressID 
																	AND EA.EmailAddress NOT LIKE '%_@_%_.__%'
	WHERE LV.SuppliedEmail = 1
		
	
	-- CHECK FOR NON SOLICITATIONS
	-- PARTY
	-- IN THIS CASE WE WILL NEVER SELECT THE RECORD SO SET IT TO BEING PROCESSED
	UPDATE LV
	SET  LV.PartyNonSolicitation = 1
		,LV.SampleRowProcessed = 1
		,LV.SampleRowProcessedDate = GETDATE()
	FROM dbo.SampleQualityAndSelectionLogging S
		INNER JOIN [$(SampleDB)].dbo.NonSolicitations NS ON NS.PartyID = COALESCE(NULLIF(S.MatchedODSPersonID,0), NULLIF(S.MatchedODSOrganisationID,0), S.MatchedODSPartyID)
		INNER JOIN [$(SampleDB)].Party.NonSolicitations PNS ON PNS.NonSolicitationID = NS.NonSolicitationID
		INNER JOIN [$(ETLDB)].dbo.VWT V ON V.AuditItemID = S.AuditItemID
		INNER JOIN #LoggingValues LV ON LV.AuditItemID = V.AuditItemID		-- V2.6
	WHERE S.LoadedDate <= ISNULL(NS.ThroughDate, S.LoadedDate)


	-- EVENT
	-- IN THIS CASE WE WILL NEVER SELECT THE RECORD SO SET IT TO BEING PROCESSED
	UPDATE LV
	SET  LV.EventNonSolicitation = 1
		,LV.SampleRowProcessed = 1
		,LV.SampleRowProcessedDate = GETDATE()
	FROM dbo.SampleQualityAndSelectionLogging S
		INNER JOIN [$(SampleDB)].Event.NonSolicitations ENS ON ENS.EventID = S.MatchedODSEventID
		INNER JOIN [$(SampleDB)].dbo.NonSolicitations NS ON NS.NonSolicitationID = ENS.NonSolicitationID
		INNER JOIN [$(ETLDB)].dbo.VWT V ON V.AuditItemID = S.AuditItemID
		INNER JOIN #LoggingValues LV ON LV.AuditItemID = V.AuditItemID		-- V2.6
	WHERE S.LoadedDate <= ISNULL(NS.ThroughDate, S.LoadedDate)
	

	-- CHECK FOR UNCODED DEALERS
	-- IN THIS CASE WE WILL NEVER SELECT THE RECORD SO SET IT TO BEING PROCESSED
	UPDATE LV
	SET  LV.UncodedDealer = 1
		,LV.SampleRowProcessed = 1
		,LV.SampleRowProcessedDate = GETDATE()
	FROM dbo.SampleQualityAndSelectionLogging S
		INNER JOIN [$(AuditDB)].Audit.EventPartyRoles AEPR ON AEPR.AuditItemID = S.AuditItemID
		INNER JOIN [$(SampleDB)].dbo.vwDealerRoleTypes DRT ON DRT.RoleTypeID = AEPR.RoleTypeID
		INNER JOIN [$(ETLDB)].dbo.VWT V ON V.AuditItemID = S.AuditItemID
		INNER JOIN #LoggingValues LV ON LV.AuditItemID = V.AuditItemID		-- V2.6
	WHERE ISNULL(AEPR.PartyID, 0) = 0


	---------------------------------------------------------------------------------
	-- V2.5 CHECK FOR InterCompanyOwnUseDealer DEALERS
	-- THESE WILL BE TREATED AS UNCODED DEALER FOR LOGGING PURPOSES AS THEY ARE NOT USED FOR NORMAL 
	---------------------------------------------------------------------------------
	UPDATE LV
	SET  LV.UncodedDealer = 1
		,LV.SalesDealerID = 0
		,LV.SampleRowProcessed = 1
		,LV.SampleRowProcessedDate = GETDATE()
	FROM dbo.SampleQualityAndSelectionLogging S
		INNER JOIN [$(SampleDB)].dbo.DW_JLRCSPDealers D ON S.SalesDealerID = D.OutletPartyID
		INNER JOIN [$(ETLDB)].dbo.VWT V ON V.AuditItemID = S.AuditItemID
		INNER JOIN #LoggingValues LV ON LV.AuditItemID = V.AuditItemID		-- V2.6
	WHERE D.InterCompanyOwnUseDealer = 1	
	---------------------------------------------------------------------------------
		
	
	-- CHECK FOR UNCODED CRC CENTRES										-- V2.1
	UPDATE LV
	SET  LV.UncodedDealer = 1
		,LV.SampleRowProcessed = 1
		,LV.SampleRowProcessedDate = GETDATE()
	FROM dbo.SampleQualityAndSelectionLogging S
		INNER JOIN [$(ETLDB)].dbo.VWT V ON V.AuditItemID = S.AuditItemID
		INNER JOIN #LoggingValues LV ON LV.AuditItemID = V.AuditItemID		-- V2.6
	WHERE LV.Questionnaire IN ('CRC', 'CRC General Enquiry')				-- V2.14
		AND ISNULL(S.CRCCentrePartyID, 0) = 0

	
	-- CHECK FOR UNCODED ROADSIDE NETWORKS									-- V2.1
	UPDATE LV
	SET  LV.UncodedDealer = 1
		,LV.SampleRowProcessed = 1
		,LV.SampleRowProcessedDate = GETDATE()
	FROM dbo.SampleQualityAndSelectionLogging S
		INNER JOIN [$(ETLDB)].dbo.VWT V ON V.AuditItemID = S.AuditItemID
		INNER JOIN #LoggingValues LV ON LV.AuditItemID = V.AuditItemID		-- V2.6
	WHERE LV.Questionnaire = 'Roadside'
		AND ISNULL(S.RoadsideNetworkPartyID, 0) = 0


	-- CHECK FOR UNCODED I-ASSISTANCE CENTRES								-- V2.7
	UPDATE LV
	SET  LV.UncodedDealer = 1
		,LV.SampleRowProcessed = 1
		,LV.SampleRowProcessedDate = GETDATE()
	FROM dbo.SampleQualityAndSelectionLogging S
		INNER JOIN [$(ETLDB)].dbo.VWT V ON V.AuditItemID = S.AuditItemID
		INNER JOIN #LoggingValues LV ON LV.AuditItemID = V.AuditItemID		-- V2.7
	WHERE LV.Questionnaire = 'I-Assistance'
		AND ISNULL(S.IAssistanceCentrePartyID, 0) = 0


	-- CHECK FOR UNCODED MODELS
	-- IN THIS CASE WE WILL NEVER SELECT THE RECORD SO SET IT TO BEING PROCESSED
	UPDATE LV
	SET  LV.UnmatchedModel = 1
		,LV.SampleRowProcessed = 1
		,LV.SampleRowProcessedDate = GETDATE()
	FROM dbo.SampleQualityAndSelectionLogging S								-- V1.2
		INNER JOIN [$(ETLDB)].dbo.VWT V ON V.AuditItemID = S.AuditItemID	-- V1.2
		INNER JOIN #LoggingValues LV ON LV.AuditItemID = V.AuditItemID		-- V2.6
	WHERE S.MatchedODSModelID IS NULL
	
	UPDATE LV
	SET  LV.UnmatchedModel = 1
		,LV.SampleRowProcessed = 1
		,LV.SampleRowProcessedDate = GETDATE()
	FROM dbo.SampleQualityAndSelectionLogging S
		INNER JOIN [$(ETLDB)].dbo.VWT V ON V.AuditItemID = S.AuditItemID	-- V1.2
		INNER JOIN #LoggingValues LV ON LV.AuditItemID = V.AuditItemID		-- V2.6
		INNER JOIN [$(SampleDB)].Vehicle.Vehicles VEH ON VEH.VehicleID = V.MatchedODSVehicleID		-- V1.8 -- Get model via vehicle
		INNER JOIN [$(SampleDB)].Vehicle.Models M ON M.ModelID = VEH.ModelID
	WHERE M.ModelDescription = 'Unknown Vehicle'
		AND LV.Questionnaire NOT IN ('CRC','CRC General Enquiry')			-- V2.18 CRC/CRC General Enquiry allow Unknown Vehicle, V1.21
	

	-- Update the flag for barred emails - V2.11 Removed. Run in WebsiteReporting.[dbo].[uspRunPreSelectionFlags]
	--UPDATE LV
	--SET	LV.BarredEmailAddress = 1,
	--	LV.SampleRowProcessed = 1,
	--	LV.SampleRowProcessedDate = GETDATE()
	--FROM dbo.SampleQualityAndSelectionLogging S	
	--	INNER JOIN [$(ETLDB)].dbo.VWT V ON V.AuditItemID = S.AuditItemID		-- V1.2
	--	INNER JOIN #LoggingValues LV ON LV.AuditItemID = V.AuditItemID			-- V2.6
	--	INNER JOIN [$(SampleDB)].ContactMechanism.BlacklistContactMechanisms BCM ON BCM.ContactMechanismID = S.MatchedODSEmailAddressID 
	--					AND BCM.ContactMechanismTypeID =  (	SELECT ContactMechanismTypeID 
	--														FROM [$(SampleDB)].ContactMechanism.ContactMechanismTypes CMT 
	--														WHERE CMT.ContactMechanismType = 'E-mail address')
	--	INNER JOIN [$(SampleDB)].[ContactMechanism].[BlacklistStrings] BS ON BS.[BlacklistStringID] = BCM.BlacklistStringID -- V2.11
	--	INNER JOIN [$(SampleDB)].[ContactMechanism].[BlacklistTypes] BLT ON BLT.[BlacklistTypeID] = BS.[BlacklistTypeID]	-- V2.11
	--WHERE BLT.PreventsSelection = 1			-- V2.11
	--	AND BLT.AFRLFilter = 1					-- V2.11


	-- Update the flag for invalid formed email id
	UPDATE LV
	SET		LV.InvalidEmailAddress = 1,
			LV.SampleRowProcessed = 1,
			LV.SampleRowProcessedDate = GETDATE()
	FROM dbo.SampleQualityAndSelectionLogging S	
		INNER JOIN [$(ETLDB)].dbo.VWT V ON V.AuditItemID = S.AuditItemID		-- V1.2
		INNER JOIN #LoggingValues LV ON LV.AuditItemID = V.AuditItemID			-- V2.6
		INNER JOIN [$(SampleDB)].ContactMechanism.EmailAddresses EA ON EA.ContactMechanismID = S.MatchedODSEmailAddressID 
																		AND EA.EmailAddress NOT LIKE '%_@_%_.__%'
	WHERE LV.SuppliedEmail = 1
	

	-- V1.7
	-- CHECK IF BRAND IS DIFFERENT THAN LOADED FILE
	UPDATE LV
	SET  LV.InvalidManufacturer = 1
		,LV.SampleRowProcessed = 1
		,LV.SampleRowProcessedDate = GETDATE()
	FROM dbo.SampleQualityAndSelectionLogging S
		INNER JOIN [$(ETLDB)].dbo.VWT V ON V.AuditItemID = S.AuditItemID
		INNER JOIN #LoggingValues LV ON LV.AuditItemID = V.AuditItemID					-- V2.6
		INNER JOIN [$(SampleDB)].Vehicle.Vehicles VE ON VE.VehicleID=S.MatchedODSVehicleID
		INNER JOIN [$(SampleDB)].Vehicle.Models M ON M.ModelID=VE.ModelID
		INNER JOIN [$(SampleDB)].dbo.Brands B ON B.ManufacturerPartyID=M.ManufacturerPartyID
	WHERE B.Brand<> LV.Brand	
	
	
	-- V2.17
	-- Flag if sample Manufacturer does not match Dealer lookup for Market, Outletcode combination
	UPDATE LV
	SET  LV.InvalidDealerBrand = 1
	FROM dbo.SampleQualityAndSelectionLogging S
		INNER JOIN [$(ETLDB)].dbo.VWT V ON V.AuditItemID = S.AuditItemID
		INNER JOIN #LoggingValues LV ON LV.AuditItemID = V.AuditItemID
		INNER JOIN [$(SampleDB)].dbo.Markets MA ON S.CountryID = MA.CountryID
		INNER JOIN [$(SampleDB)].dbo.DW_JLRCSPDealers J ON COALESCE(MA.DealerTableEquivMarket, MA.Market) = J.Market
												AND COALESCE(S.SalesDealerID, S.ServiceDealerID, S.BodyshopDealerID,S.ExperienceDealerID) = J.OutletPartyID
												AND CASE 
														WHEN S.Questionnaire = 'Service' THEN 'AfterSales'
														WHEN S.Questionnaire = 'Sales' THEN 'Sales'
														WHEN S.Questionnaire = 'CQI 24MIS' THEN 'Sales'
														WHEN S.Questionnaire = 'CQI 3MIS' THEN 'Sales'
														WHEN S.Questionnaire = 'CQI 1MIS' THEN 'Sales'						-- V1.22
														WHEN S.Questionnaire = 'LostLeads' THEN 'Sales'
														WHEN S.Questionnaire = 'PreOwned' THEN 'PreOwned'
														WHEN S.Questionnaire = 'Bodyshop' THEN 'Bodyshop'
														WHEN S.Questionnaire = 'PreOwned LostLeads' THEN 'PreOwned'
														WHEN S.Questionnaire = 'Land Rover Experience' THEN 'Experience'	--V2.23
														ELSE ''
													END = J.OutletFunction	
	WHERE J.ThroughDate IS NULL
	AND J.Manufacturer <> S.Brand
	AND S.Questionnaire NOT IN ('CRC','Roadside','0')
	AND LV.UncodedDealer = 0


	-- V2.19
	-- Set EventAlreadySelected flag if Case Already Exists
	UPDATE LV
	SET  LV.EventAlreadySelected = 1
	FROM dbo.SampleQualityAndSelectionLogging S
		INNER JOIN [$(ETLDB)].dbo.VWT V ON V.AuditItemID = S.AuditItemID
		INNER JOIN #LoggingValues LV ON LV.AuditItemID = V.AuditItemID
		INNER JOIN [$(SampleDB)].Event.AutomotiveEventBasedInterviews AEBI ON AEBI.EventID = S.MatchedODSEventID


	------------------------------------------------------------------------------------------
	-- NOW APPLY ALL THE CHANGES TO LOGGING TABLE IN ONE GO						-- V2.6
	------------------------------------------------------------------------------------------
	UPDATE S
	SET S.Brand							= ISNULL(LV.Brand						,0),
		S.Market						= ISNULL(LV.Market						,0),
		S.Questionnaire 				= ISNULL(LV.Questionnaire 				,0),
		S.QuestionnaireRequirementID	= ISNULL(LV.QuestionnaireRequirementID	,0),
		S.StartDays						= ISNULL(LV.StartDays					,0),
		S.EndDays						= ISNULL(LV.EndDays						,0),
		S.SuppliedName					= ISNULL(LV.SuppliedName				,0),
		S.SuppliedAddress				= ISNULL(LV.SuppliedAddress				,0),
		S.SuppliedPhoneNumber			= ISNULL(LV.SuppliedPhoneNumber			,0),
		S.SuppliedMobilePhone			= ISNULL(LV.SuppliedMobilePhone			,0),
		S.SuppliedEmail					= ISNULL(LV.SuppliedEmail				,0),
		S.SuppliedEventDate				= ISNULL(LV.SuppliedEventDate			,0),
		S.EventDateOutOfDate			= ISNULL(LV.EventDateOutOfDate			,0),
		S.EventDateTooYoung				= ISNULL(LV.EventDateTooYoung			,0),
		S.InvalidEmailAddress			= ISNULL(LV.InvalidEmailAddress			,0),
		S.PartyNonSolicitation			= ISNULL(LV.PartyNonSolicitation		,0),
		S.EventNonSolicitation			= ISNULL(LV.EventNonSolicitation		,0),
		S.UncodedDealer					= ISNULL(LV.UncodedDealer				,0),
		S.UnmatchedModel				= ISNULL(LV.UnmatchedModel				,0),
		S.BarredEmailAddress			= ISNULL(LV.BarredEmailAddress			,0),
		S.InvalidManufacturer			= ISNULL(LV.InvalidManufacturer			,0),
		S.SalesDealerID					= LV.SalesDealerID,
		S.SampleRowProcessed			= ISNULL(LV.SampleRowProcessed			,0),
		S.SampleRowProcessedDate		= LV.SampleRowProcessedDate,
		S.InvalidDealerBrand			= ISNULL(LV.InvalidDealerBrand			,0),
		S.EventAlreadySelected			= ISNULL(LV.EventAlreadySelected		,0)
	FROM #LoggingValues LV 
		INNER JOIN dbo.SampleQualityAndSelectionLogging S ON S.AuditItemID = LV.AuditItemID	


	

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

