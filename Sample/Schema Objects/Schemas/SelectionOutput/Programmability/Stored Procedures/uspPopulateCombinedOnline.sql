CREATE PROCEDURE [SelectionOutput].[uspPopulateCombinedOnline]
	@RussiaOutput INTEGER = 0
AS 

/*
		Version		Created			Author			Description	
		-------		-------			------			-------			
LIVE	1.0			2021-03-03		Eddie Thomas 	Created to replace SelectionOutput.uspGetAllOnline
LIVE	1.1			2021-01-11		Eddie Thomas	Replacing references to #OnlineOutput with a base table 
LIVE	1.2			2021-01-20		Eddie Thomas	Select Dealer10DigitCode
LIVE	1.3			2021-01-25		Eddie Thomas	Added EventID 
LIVE	1.4			2021-03-09		Chris Ledger	Task 305 - Change BreakdownCountryID & FOBCode from 0 to Blank
LIVE	1.5			2021-03-26		Eddie Thomas	BUG 18144 - New CRC Global List Lookup
LIVE	1.6			2021-04-26		Chris Ledger	TASK 409 - Exclude employee data for certain markets
LIVE	1.7			2021-05-10		Chris Ledger	TASK 389 - Add CRC General Enquiry
LIVE	1.8			2021-05-26		Chris Ledger	Remove LEFT JOINS to China_WithResponses tables
LIVE	1.9			2021-06-03		Chris Ledger	TASK 390 - Stop excluding USA/Canada from Roadside output
LIVE	1.10		2021-06-17		Chris Ledger	TASK 506 - cast CarHireStartDate as DATE and force Approved field to 'APPROVED'
LIVE	1.11		2021-06-29		Eddie Thomas	BugTracker 18235 - PHEV Flags
LIVE	1.12		2021-07-07		Chris Ledger	TASK 549 - Populate CRMSalesman & CRMSalesmancode for PreOwned
LIVE	1.13		2021-07-21		Chris Ledger	TASK 552 - Populate SVOTypeID for Bodyshop, CRC,CRC General Enquiry, Lost Leads, PreOwned & Roadside
LIVE	1.14		2021-07-21		Eddie Thomas	BUG 18240 - Field for General Enquiry were being output as blank
LIVE	1.15		2021-07-27		Eddie Thomas	BUG 18301 - Roadside Model Year outputting as 0
LIVE	1.16        2021-08-23      Ben King        TASK 567 - Setup SV-CRM Lost Leads Loader
LIVE	1.17        2021-09-29      Ben King        TASK 600 - 18342 - Legitimate Business Interest (LBI) Consent
LIVE	1.18		2021-10-19		Chris Ledger	TASK 664 - Add PAGCode to EmployeeName & CRMEmployeeName fields
LIVE	1.19		2021-11-05		Eddie Thomas	BUG 18358 - Add CustomerID to Roadsdide output
LIVE	1.20		2022-01-18		Chris Ledger	TASK 758 - Remove Russia filters (Russia now output to Medallia)
LIVE	1.21		2022-03-23		Chris Ledger	Query optimisation
LIVE    1.22        2022-06-15		Chris Ledger    TASK 729 - Populate ModelVariantCode & ModelVariant for Roadside
LIVE    1.23		2022-06-14		Eddie Thomas	TASK 877 Land Rover Experience
LIVE	1.24		2022-06-23		Eddie Thomas	TASK 900 - Business & Fleet Vehicle, Populate BusinessFlag & CommonSaleType
LIVE	1.25		2022-09-07		Eddie Thomas	Task 1018 - OutputSubBrand
LIVE	1.26		2022-10-05		Chris Ledger	TASK 1059 - Remove EmployeeName from Lost Leads output
LIVE	1.27		2022-10-18		Chris Ledger	TASK 1046 - Populate LeadVehSaleType for Non-SVCRM, exclude dummy VINS & ModelYear = 0
LIVE	1.28		2022-11-03		Ben King		TASK 956 - 19540 - Lost Leads CXP Loader
*/

	SET NOCOUNT ON	
    DECLARE @NOW	DATETIME,	
			@dtCATI	DATETIME
    
    SET		@NOW = GETDATE()
	SET		@dtCATI	= DATEADD(week, DATEDIFF(day, 0, @NOW)/7, 4)


	----------------------------------------------------------
	TRUNCATE TABLE SelectionOutput.CombinedOnlineOutput
	

	----------------------------------------------------------
	-- Temp Table for CRC DeDupedEvents
	DECLARE @DeDupedEvents TABLE
	(  
		ODSEventID INT NULL,
		AuditItemID INT NULL,
		UNIQUE CLUSTERED (ODSEventID)
	)
	----------------------------------------------------------

	----------------------------------------------------------
	-- CRC DeDuped Events
	INSERT INTO @DeDupedEvents (ODSEventID, AuditItemID)
	SELECT ODSEventID, 
		MAX(AuditItemID) AS AuditItemID
	FROM [$(ETLDB)].CRC.CRCEvents
	GROUP BY ODSEventID
	----------------------------------------------------------

	----------------------------------------------------------
	-- CRC Output
	INSERT INTO SelectionOutput.CombinedOnlineOutput
	SELECT DISTINCT
		O.ID AS ID,
		O.etype AS SurveyTypeID,
		O.modelcode AS ModelCode,
		O.FullModel AS ModelDescription,
		CASE WHEN O.ModelYear = 0 THEN ''
			 ELSE CAST(O.ModelYear AS VARCHAR) END AS ModelYear,				-- V1.27
		O.manuf AS ManufacturerID,
		O.sType AS Manufacturer,
		REPLACE(O.CarReg, CHAR(9), '') AS CarRegistration,
		CASE WHEN O.VIN	= 'SAJ_CRC_Unknown_V' THEN ''
			 WHEN O.VIN	= 'SAL_CRC_Unknown_V' THEN ''
			 ELSE REPLACE(O.VIN, CHAR(9), '') END AS VIN,	-- V1.27
		O.VariantID AS ModelVariantCode,
		O.ModelVariant AS ModelVariantDescription,
		O.PartyID AS PartyID,
		REPLACE(O.Title, CHAR(9), '') AS Title,
		REPLACE(O.Initial, CHAR(9), '') AS Initial,
		REPLACE(O.Surname, CHAR(9), '') AS LastName,
		REPLACE(O.Fullname, CHAR(9), '') AS FullName,
		REPLACE(O.DearName, CHAR(9), '') AS DearName,
		REPLACE(O.CoName, CHAR(9), '') AS CompanyName,
		REPLACE(O.Add1, CHAR(9), '') AS Address1,
		REPLACE(O.Add2, CHAR(9), '') AS Address2,
		REPLACE(O.Add3, CHAR(9), '') AS Address3,
		REPLACE(O.Add4, CHAR(9), '') AS Address4,
		REPLACE(O.Add5, CHAR(9), '') AS Address5,
		REPLACE(O.Add6, CHAR(9), '') AS Address6,
		REPLACE(O.Add7, CHAR(9), '') AS Address7,
		REPLACE(O.Add8, CHAR(9), '') AS Address8,
		O.CTRY AS Country,
		O.ccode AS CountryID,
		O.EmailAddress AS EmailAddress,
		REPLACE(O.Telephone, CHAR(9), '') AS HomeNumber,
		REPLACE(O.WorkTel, CHAR(9), '') AS WorkNumber,
		REPLACE(O.MobilePhone, CHAR(9), '') AS MobileNumber,
		REPLACE(O.CustomerIdentifier, CHAR(9), '') AS CustomerUniqueID,
		O.sno AS VersionCode,
		O.lang AS LanguageID,
		O.gender AS GenderID,
		O.etype AS EventTypeID,
		REPLACE(CONVERT(VARCHAR(10), O.EventDate, 102), '.', '-') AS EventDate,
		O.Password AS Password,
		O.ITYPE AS IType,
		CASE	
			WHEN O.Itype ='T' THEN  CONVERT(NVARCHAR(10), @dtCATI, 121)
			ELSE CONVERT(NVARCHAR(10), @NOW, 121) 
		END AS SelectionDate,
		O.week AS Week,
		O.Expired AS Expired,
		CONVERT(NVARCHAR(100),
		CONVERT(VARCHAR(10), ISNULL(O.etype, '')) + '_'
		+ CASE	WHEN ISNULL(O.ITYPE, '') = '' THEN 'blank'
				ELSE O.ITYPE END + '_' 
		+ CONVERT(VARCHAR(10), ISNULL(O.ccode, '')) + '_'
		+ CASE	WHEN O.manuf = 2 THEN 'J'
			WHEN O.manuf = 3 THEN 'L'
			ELSE 'UknownManufacturer' END + '_' 
		+ CONVERT(VARCHAR(10), ISNULL(O.lang, ''))) AS CampaignID,
		O.Test AS Test,
		O.OutletPartyID AS DealerPartyID,
		O.ReportingDealerPartyID AS ReportingDealerPartyID,
		O.Dealer AS DealerName,
		O.DealerCode AS DealerCode,
		O.GDDDealerCode AS GlobalDealerCode,
		O.blank AS BusinessRegion,
		O.OwnershipCycle AS OwnershipCycle,
		REPLACE(O.EmailSignator, CHAR(10), '<br/>') AS EmailSignator,
		REPLACE(O.EmailSignatorTitle, CHAR(10), '<br/>') AS EmailSignatorTitle,
		REPLACE(O.EmailContactText, CHAR(10), '<br/>') AS EmailContactText,
		REPLACE(O.EmailCompanyDetails, CHAR(10), '<br/>') AS EmailCompanyDetails,
		REPLACE(O.JLRPrivacyPolicy, CHAR(10), '<br/>') AS JLRPrivacyPolicy,
		REPLACE(O.JLRCompanyname, CHAR(10), '<br/>') AS JLRCompanyName,
		'' AS UnknownLanguage,
		O.BilingualFlag AS BilingualFlag,
		O.langBilingual AS BilingualLanguageID,
		O.DearNameBilingual AS DearNameBilingual,
		O.EmailSignatorTitleBilingual AS EmailSignatorTitleBilingual,
		O.EmailContactTextBilingual AS EmailContactTextBilingual,
		O.EmailCompanyDetailsBilingual AS EmailCompanyDetailsBilingual,
		O.JLRPrivacyPolicyBilingual AS JLRPrivacyPolicyBilingual,
		O.EmployeeCode AS EmployeeCode,
		O.EmployeeName AS EmployeeName,
		'' AS CRMSalesmanCode,
		'' AS CRMSalesmanName,
		'' AS RockarDealer,
		ISNULL(O.SVOvehicle, '') AS SVOTypeID,										-- V1.13
		'' AS SVODealer,
		'' AS VistaContractOrderNumber,
		'' AS DealerNumber,
		'' AS FOBCode,
		'' AS HotTopicCodes,
		'' AS ServiceTechnicianID,
		'' AS ServiceTechnicianName,
		'' AS ServiceAdvisorID,
		'' AS ServiceAdvisorName,
		'' AS RepairOrderNumber,
		'' AS ServiceEventType,
		'' AS Approved,
		'' AS BreakdownDate,
		'' AS BreakdownCountry,
		'' AS BreakdownCountryID,
		'' AS BreakdownCaseID,
		'' AS CarHireStartDate,
		'' AS ReasonForHire,
		'' AS HireGroupBranch,
		'' AS CarHireTicketNumber,
		'' AS HireJobNumber,
		'' AS RepairingDealer,
		'' AS DataSource,
		'' AS ReplacementVehicleMake,
		'' AS ReplacementVehicleModel,
		'' AS CarHireStartTime,
		'' AS RepairingDealerCountry,
		'' AS RoadsideAssistanceProvider,
		'' AS BreakdownAttendingResource,
		'' AS CarHireProvider,
		'' AS VehicleOriginCountry,
		--CASE 
		--	WHEN LEN(ISNULL(CRC.ClosedBy,'')) > 0 THEN CRC.ClosedBy 
		--	ELSE CRC.Owner END AS CRCOwnerCode,
		COALESCE(LTRIM(RTRIM(CRC.[Owner])), LTRIM(RTRIM(CRC.ClosedBy)), '') AS CRCOwnerCode,		-- V1.5
		CRC.CRCCode AS CRCCode,
		CRC.MarketCode AS CRCMarketCode,
		YEAR(GETDATE()) AS SampleYear,
		CRC.VehicleMileage AS VehicleMileage,
		CRC.VehicleMonthsinService AS VehicleMonthsinService,
		CRC.RowId AS CRCRowID,
		CRC.CaseNumber AS CRCSerialNumber,
		'' AS NSCFlag,
		'' AS JLREventType,
		'' AS DealerType,
		'' AS Queue,
		O.Dealer10DigitCode,				-- V1.2
		O.EventID,							-- V1.3
		O.EngineType,						-- V1.11
		'' AS LeadVehSaleType,				-- V1.16
		'' AS LeadOrigin,					-- V1.16
		'' AS LegalGrounds ,                -- V1.17
		'' AS AnonymityQuestion,            -- V1.17
		'' AS LandRoverExperienceID,		-- V1.23
		'' AS BusinessFlag,					-- V1.24
		'' AS CommonSaleType,				-- V1.24
		O.SubBrand							-- V1.25
    FROM SelectionOutput.OnlineOutput O
		INNER JOIN Event.vwEventTypes ET ON	ET.EventTypeID = O.etype 
											AND ET.EventCategory = 'CRC' 
		INNER JOIN Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = O.ID 
		INNER JOIN @DeDupedEvents DDE ON DDE.ODSEventID = AEBI.EventID
		INNER JOIN [$(ETLDB)].CRC.CRCEvents CRC ON CRC.AuditItemID = DDE.AuditItemID
		--LEFT JOIN [$(ETLDB)].China.CRC_WithResponses CWR ON O.ID = CWR.CaseID			-- V1.8
	--WHERE ((@RussiaOutput = 1 AND ISNULL(O.CTRY,'') = 'Russian Federation') OR  (@RussiaOutput = 0 AND ISNULL(O.CTRY,'') <> 'Russian Federation'))	-- V1.20
		--AND CWR.CaseID IS NULL														-- V1.8
	----------------------------------------------------------
		

	----------------------------------------------------------
	-- V1.7 Temp Table for CRC General Enquiry DeDupedEvents
	DECLARE @DeDupedGeneralEnquiryEvents TABLE
	(  
		ODSEventID INT NULL,
		AuditItemID INT NULL,
		UNIQUE CLUSTERED (ODSEventID)
	)
	----------------------------------------------------------

	----------------------------------------------------------
	-- V1.7 CRC General Enquiry DeDuped Events
	INSERT INTO @DeDupedGeneralEnquiryEvents (ODSEventID, AuditItemID)
	SELECT ODSEventID, 
		MAX(AuditItemID) AS AuditItemID
	FROM [$(ETLDB)].GeneralEnquiry.GeneralEnquiryEvents
	GROUP BY ODSEventID
	----------------------------------------------------------

	----------------------------------------------------------
	-- V1.7 CRC General Enquiry Output
	INSERT INTO SelectionOutput.CombinedOnlineOutput
	SELECT DISTINCT
		O.ID AS ID,
		O.etype AS SurveyTypeID,
		O.modelcode AS ModelCode,
		O.FullModel AS ModelDescription,
		CASE WHEN O.ModelYear = 0 THEN ''
			ELSE CAST(O.ModelYear AS VARCHAR) END AS ModelYear,				-- V1.27
		O.manuf AS ManufacturerID,
		O.sType AS Manufacturer,
		REPLACE(O.CarReg, CHAR(9), '') AS CarRegistration,
		CASE WHEN O.VIN	= 'SAJ_CRC_Unknown_V' THEN ''
			 WHEN O.VIN	= 'SAL_CRC_Unknown_V' THEN ''
			 ELSE REPLACE(O.VIN, CHAR(9), '') END AS VIN,	-- V1.27		
		O.VariantID AS ModelVariantCode,
		O.ModelVariant AS ModelVariantDescription,
		O.PartyID AS PartyID,
		REPLACE(O.Title, CHAR(9), '') AS Title,
		REPLACE(O.Initial, CHAR(9), '') AS Initial,
		REPLACE(O.Surname, CHAR(9), '') AS LastName,
		REPLACE(O.Fullname, CHAR(9), '') AS FullName,
		REPLACE(O.DearName, CHAR(9), '') AS DearName,
		REPLACE(O.CoName, CHAR(9), '') AS CompanyName,
		REPLACE(O.Add1, CHAR(9), '') AS Address1,
		REPLACE(O.Add2, CHAR(9), '') AS Address2,
		REPLACE(O.Add3, CHAR(9), '') AS Address3,
		REPLACE(O.Add4, CHAR(9), '') AS Address4,
		REPLACE(O.Add5, CHAR(9), '') AS Address5,
		REPLACE(O.Add6, CHAR(9), '') AS Address6,
		REPLACE(O.Add7, CHAR(9), '') AS Address7,
		REPLACE(O.Add8, CHAR(9), '') AS Address8,
		O.CTRY AS Country,
		O.ccode AS CountryID,
		O.EmailAddress AS EmailAddress,
		REPLACE(O.Telephone, CHAR(9), '') AS HomeNumber,
		REPLACE(O.WorkTel, CHAR(9), '') AS WorkNumber,
		REPLACE(O.MobilePhone, CHAR(9), '') AS MobileNumber,
		REPLACE(O.CustomerIdentifier, CHAR(9), '') AS CustomerUniqueID,
		O.sno AS VersionCode,
		O.lang AS LanguageID,
		O.gender AS GenderID,
		O.etype AS EventTypeID,
		REPLACE(CONVERT(VARCHAR(10), O.EventDate, 102), '.', '-') AS EventDate,
		O.Password AS Password,
		O.ITYPE AS IType,
		CASE	
			WHEN O.Itype ='T' THEN  CONVERT(NVARCHAR(10), @dtCATI, 121)
			ELSE CONVERT(NVARCHAR(10), @NOW, 121) 
		END AS SelectionDate,
		O.week AS Week,
		O.Expired AS Expired,
		CONVERT(NVARCHAR(100),
		CONVERT(VARCHAR(10), ISNULL(O.etype, '')) + '_'
		+ CASE	WHEN ISNULL(O.ITYPE, '') = '' THEN 'blank'
				ELSE O.ITYPE END + '_' 
		+ CONVERT(VARCHAR(10), ISNULL(O.ccode, '')) + '_'
		+ CASE	WHEN O.manuf = 2 THEN 'J'
			WHEN O.manuf = 3 THEN 'L'
			ELSE 'UknownManufacturer' END + '_' 
		+ CONVERT(VARCHAR(10), ISNULL(O.lang, ''))) AS CampaignID,
		O.Test AS Test,
		O.OutletPartyID AS DealerPartyID,
		O.ReportingDealerPartyID AS ReportingDealerPartyID,
		O.Dealer AS DealerName,
		O.DealerCode AS DealerCode,
		O.GDDDealerCode AS GlobalDealerCode,
		O.blank AS BusinessRegion,
		O.OwnershipCycle AS OwnershipCycle,
		REPLACE(O.EmailSignator, CHAR(10), '<br/>') AS EmailSignator,
		REPLACE(O.EmailSignatorTitle, CHAR(10), '<br/>') AS EmailSignatorTitle,
		REPLACE(O.EmailContactText, CHAR(10), '<br/>') AS EmailContactText,
		REPLACE(O.EmailCompanyDetails, CHAR(10), '<br/>') AS EmailCompanyDetails,
		REPLACE(O.JLRPrivacyPolicy, CHAR(10), '<br/>') AS JLRPrivacyPolicy,
		REPLACE(O.JLRCompanyname, CHAR(10), '<br/>') AS JLRCompanyName,
		'' AS UnknownLanguage,
		O.BilingualFlag AS BilingualFlag,
		O.langBilingual AS BilingualLanguageID,
		O.DearNameBilingual AS DearNameBilingual,
		O.EmailSignatorTitleBilingual AS EmailSignatorTitleBilingual,
		O.EmailContactTextBilingual AS EmailContactTextBilingual,
		O.EmailCompanyDetailsBilingual AS EmailCompanyDetailsBilingual,
		O.JLRPrivacyPolicyBilingual AS JLRPrivacyPolicyBilingual,
		O.EmployeeCode AS EmployeeCode,
		O.EmployeeName AS EmployeeName,
		'' AS CRMSalesmanCode,
		'' AS CRMSalesmanName,
		'' AS RockarDealer,
		ISNULL(O.SVOvehicle, '') AS SVOTypeID,							-- V1.13
		'' AS SVODealer,
		'' AS VistaContractOrderNumber,
		'' AS DealerNumber,
		'' AS FOBCode,
		'' AS HotTopicCodes,
		'' AS ServiceTechnicianID,
		'' AS ServiceTechnicianName,
		'' AS ServiceAdvisorID,
		'' AS ServiceAdvisorName,
		'' AS RepairOrderNumber,
		'' AS ServiceEventType,
		'' AS Approved,
		'' AS BreakdownDate,
		'' AS BreakdownCountry,
		'' AS BreakdownCountryID,
		'' AS BreakdownCaseID,
		'' AS CarHireStartDate,
		'' AS ReasonForHire,
		'' AS HireGroupBranch,
		'' AS CarHireTicketNumber,
		'' AS HireJobNumber,
		'' AS RepairingDealer,
		'' AS DataSource,
		'' AS ReplacementVehicleMake,
		'' AS ReplacementVehicleModel,
		'' AS CarHireStartTime,
		'' AS RepairingDealerCountry,
		'' AS RoadsideAssistanceProvider,
		'' AS BreakdownAttendingResource,
		'' AS CarHireProvider,
		'' AS VehicleOriginCountry,
		LTRIM(RTRIM(GE.EmployeeResponsibleName)) AS CRCOwnerCode,		-- V1.7
		GE.CRCCentreCode AS CRCCode,
		GE.MarketCode AS CRCMarketCode,
		YEAR(GETDATE()) AS SampleYear,
		GE.VehicleMileage,					--V1.14
		GE.VehicleMonthsinService,			--V1.14
		GE.RowId AS CRCRowID,
		GE.CaseNumber AS CRCSerialNumber,	--V1.14
		'' AS NSCFlag,
		'' AS JLREventType,
		'' AS DealerType,
		'' AS Queue,
		O.Dealer10DigitCode,				-- V1.2
		O.EventID,							-- V1.3
		O.EngineType,						-- V1.11
		'' AS LeadVehSaleType,				-- V1.16
		'' AS LeadOrigin,					-- V1.16
		'' AS LegalGrounds ,                -- V1.17
		'' AS AnonymityQuestion,            -- V1.17
		'' AS LandRoverExperienceID,		-- V1.23
		'' AS BusinessFlag,					-- V1.24
		'' AS CommonSaleType,				-- V1.24
		O.SubBrand							-- V1.25
    FROM SelectionOutput.OnlineOutput O
		INNER JOIN Event.vwEventTypes ET ON	ET.EventTypeID = O.etype 
											AND ET.EventCategory = 'CRC General Enquiry' 
		INNER JOIN Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = O.ID 
		INNER JOIN @DeDupedGeneralEnquiryEvents DDE ON DDE.ODSEventID = AEBI.EventID
		INNER JOIN [$(ETLDB)].GeneralEnquiry.GeneralEnquiryEvents GE ON GE.AuditItemID = DDE.AuditItemID
		--LEFT JOIN [$(ETLDB)].China.CRC_WithResponses CWR ON O.ID = CWR.CaseID			-- V1.8
	--WHERE ((@RussiaOutput = 1 AND ISNULL(O.CTRY,'') = 'Russian Federation') OR  (@RussiaOutput = 0 AND ISNULL(O.CTRY,'') <> 'Russian Federation'))	-- V1.20
		--AND CWR.CaseID IS NULL														-- V1.8
	----------------------------------------------------------
	
	
	UPDATE OO 
	SET OO.CRCOwnerCode = CASE	WHEN LKO.CDSID IS NOT NULL THEN LKO.CDSID	-- WE'VE GOT A MATCH IN THE LOOKUP TABLE, USE IT. 
								WHEN LKF.CDSID IS NOT NULL THEN LKF.CDSID
								ELSE OO.CRCOwnerCode END
	FROM SelectionOutput.CombinedOnlineOutput OO
		LEFT JOIN [$(ETLDB)].Lookup.CRCAgents_GlobalList LKO ON OO.CRCOwnerCode = LKO.CDSID 
																AND OO.CRCMarketCode = LKO.MarketCode
		LEFT JOIN [$(ETLDB)].Lookup.CRCAgents_GlobalList LKF ON OO.CRCOwnerCode = LKF.FullName 
																AND OO.CRCMarketCode = LKF.MarketCode  
	--WHERE LK.CODE IS NOT NULL


	----------------------------------------------------------
	-- Sales Output
	;WITH CTE_CRMInfoSales (CaseID, AuditItemID) AS 
	(
		SELECT SL.CaseID, 
			MAX(SL.AuditItemID) AS AuditItemID
		FROM SelectionOutput.OnlineOutput O
			INNER JOIN Event.vwEventTypes ET ON	ET.EventTypeID = O.etype 
												AND	ET.EventCategory = 'Sales'
			INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL ON SL.CaseID = O.ID
			INNER JOIN [$(ETLDB)].CRM.Vista_Contract_Sales VCS ON SL.AuditItemID = VCS.AudititemID
			--LEFT JOIN [$(ETLDB)].China.Sales_WithResponses CSR ON O.ID = CSR.CaseID 		-- V1.8								
		--WHERE CSR.CaseID IS NULL															-- V1.8
		GROUP BY SL.CaseID
	)
	INSERT INTO SelectionOutput.CombinedOnlineOutput
    SELECT O.ID AS ID,
		O.etype AS SurveyTypeID,
		O.modelcode AS ModelCode,
		O.FullModel AS ModelDescription,
		CASE WHEN O.ModelYear = 0 THEN ''
			ELSE CAST(O.ModelYear AS VARCHAR) END AS ModelYear,				-- V1.27
		O.manuf AS ManufacturerID,
		O.sType AS Manufacturer,
		REPLACE(O.CarReg, CHAR(9), '') AS CarRegistration,
		REPLACE(O.VIN, CHAR(9), '') AS VIN,
		O.VariantID AS ModelVariantCode,
		O.ModelVariant AS ModelVariantDescription,
		O.PartyID AS PartyID,
		REPLACE(O.Title, CHAR(9), '') AS Title,
		REPLACE(O.Initial, CHAR(9), '') AS Initial,
		REPLACE(O.Surname, CHAR(9), '') AS LastName,
		REPLACE(O.Fullname, CHAR(9), '') AS FullName,
		REPLACE(O.DearName, CHAR(9), '') AS DearName,
		REPLACE(O.CoName, CHAR(9), '') AS CompanyName,
		REPLACE(O.Add1, CHAR(9), '') AS Address1,
		REPLACE(O.Add2, CHAR(9), '') AS Address2,
		REPLACE(O.Add3, CHAR(9), '') AS Address3,
		REPLACE(O.Add4, CHAR(9), '') AS Address4,
		REPLACE(O.Add5, CHAR(9), '') AS Address5,
		REPLACE(O.Add6, CHAR(9), '') AS Address6,
		REPLACE(O.Add7, CHAR(9), '') AS Address7,
		REPLACE(O.Add8, CHAR(9), '') AS Address8,
		O.CTRY AS Country,
		O.ccode AS CountryID,
		O.EmailAddress AS EmailAddress,
		REPLACE(O.Telephone, CHAR(9), '') AS HomeNumber,
		REPLACE(O.WorkTel, CHAR(9), '') AS WorkNumber,
		REPLACE(O.MobilePhone, CHAR(9), '') AS MobileNumber,
		REPLACE(O.CustomerIdentifier, CHAR(9), '') AS CustomerUniqueID,
		O.sno AS VersionCode,
		O.lang AS LanguageID,
		O.gender AS GenderID,
		O.etype AS EventTypeID,
		REPLACE(CONVERT(VARCHAR(10), O.EventDate, 102), '.', '-') AS EventDate,
		O.Password AS Password,
		O.ITYPE AS IType,
		CASE	WHEN O.Itype ='T' THEN CONVERT(NVARCHAR(10), @dtCATI, 121)
				ELSE CONVERT(NVARCHAR(10), @NOW, 121) END AS SelectionDate,
		O.week AS Week,
		O.Expired AS Expired,
		CONVERT(NVARCHAR(100),
			CONVERT(VARCHAR(10), ISNULL(O.etype, '')) + '_'
			+ CASE	WHEN ISNULL(O.ITYPE, '') = '' THEN 'blank'
					ELSE O.ITYPE END + '_' 
			+ CONVERT(VARCHAR(10), ISNULL(O.ccode, '')) + '_'
			+ CASE	WHEN O.manuf = 2 THEN 'J'
					WHEN O.manuf = 3 THEN 'L'
					ELSE 'UknownManufacturer' END + '_' 
			+ CONVERT(VARCHAR(10), ISNULL(O.lang, ''))) AS CampaignID,
		O.test AS Test,
		O.OutletPartyID AS DealerPartyID,
		O.ReportingDealerPartyID AS ReportingDealerPartyID,
		O.Dealer AS DealerName,
		O.DealerCode AS DealerCode,
		O.GDDDealerCode AS GlobalDealerCode,
		O.blank AS BusinessRegion,
		O.OwnershipCycle AS OwnershipCycle,
		REPLACE(O.EmailSignator, CHAR(10), '<br/>') AS EmailSignator,
		REPLACE(O.EmailSignatorTitle, CHAR(10), '<br/>') AS EmailSignatorTitle,
		REPLACE(O.EmailContactText, CHAR(10), '<br/>') AS EmailContactText,
		REPLACE(O.EmailCompanyDetails, CHAR(10), '<br/>') AS EmailCompanyDetails,
		REPLACE(O.JLRPrivacyPolicy, CHAR(10), '<br/>') AS JLRPrivacyPolicy,
		REPLACE(O.JLRCompanyname, CHAR(10), '<br/>') AS JLRCompanyName,
		O.UnknownLang AS UnknownLanguage,
		O.BilingualFlag AS BilingualFlag,
		O.langBilingual AS BilingualLanguageID,
		O.DearNameBilingual AS DearNameBilingual,
		O.EmailSignatorTitleBilingual AS EmailSignatorTitleBilingual,
		O.EmailContactTextBilingual AS EmailContactTextBilingual,
		O.EmailCompanyDetailsBilingual AS EmailCompanyDetailsBilingual,
		O.JLRPrivacyPolicyBilingual AS JLRPrivacyPolicyBilingual,
		CASE	WHEN VCS.AudititemID IS NULL THEN O.EmployeeCode 
				ELSE '' END AS EmployeeCode,
		CASE	WHEN VCS.AudititemID IS NULL THEN CASE	WHEN D.PAGCode IS NULL THEN O.EmployeeName									-- V1.18
														WHEN LEN(O.EmployeeName) > 0 THEN O.EmployeeName + ' (' + D.PAGCode + ')'	-- V1.18
														ELSE '' END																	-- V1.18
				ELSE '' END AS EmployeeName,																						-- V1.18
		ISNULL(COALESCE(VCS.VISTACONTRACT_SALESMAN_CODE, O.SalesAdvisorID), '') AS CRMSalesmanCode,
		CASE	WHEN D.PAGCode IS NULL THEN ISNULL(COALESCE(VCS.VISTACONTRACT_SALES_MAN_FULNAM, O.SalesAdvisorName), '')																				-- V1.18
				WHEN LEN(ISNULL(COALESCE(VCS.VISTACONTRACT_SALES_MAN_FULNAM, O.SalesAdvisorName), ''))>0 THEN COALESCE(VCS.VISTACONTRACT_SALES_MAN_FULNAM, O.SalesAdvisorName) + ' (' + D.PAGCode + ')'	-- V1.18
				ELSE '' END AS CRMSalesmanName,																																						-- V1.18
		ISNULL(O.RockarDealer, 0) AS RockarDealer,
		ISNULL(O.SVOvehicle, '') AS SVOTypeID,					-- V1.4
		ISNULL(O.SVODealer, '') AS SVODealer,					-- V1.4
		O.VistaContractOrderNumber AS VistaContractOrderNumber,
		O.DealNo AS DealerNumber,
		O.FOBCode AS FOBCode,
		O.HotTopicCodes AS HotTopicCodes,
		'' AS ServiceTechnicianID,
		'' AS ServiceTechnicianName,
		'' AS ServiceAdvisorID,
		'' AS ServiceAdvisorName,
		'' AS RepairOrderNumber,
		'' AS ServiceEventType,
		'' AS Approved,
		'' AS BreakdownDate,
		'' AS BreakdownCountry,
		'' AS BreakdownCountryID,
		'' AS BreakdownCaseID,
		'' AS CarHireStartDate,
		'' AS ReasonForHire,
		'' AS HireGroupBranch,
		'' AS CarHireTicketNumber,
		'' AS HireJobNumber,
		'' AS RepairingDealer,
		'' AS DataSource,
		'' AS ReplacementVehicleMake,
		'' AS ReplacementVehicleModel,
		'' AS CarHireStartTime,
		'' AS RepairingDealerCountry,
		'' AS RoadsideAssistanceProvider,
		'' AS BreakdownAttendingResource,
		'' AS CarHireProvider,
		'' AS VehicleOriginCountry,
		'' AS CRCOwnerCode,
		'' AS CRCCode,
		'' AS CRCMarketCode,
		'' AS SampleYear,
		'' AS VehicleMileage,
		'' AS VehicleMonthsinService,
		'' AS CRCRowID,
		'' AS CRCSerialNumber,
		'' AS NSCFlag,
		'' AS JLREventType,
		'' AS DealerType,
		'' AS Queue,
		O.Dealer10DigitCode,
		O.EventID,							-- V1.3
		O.EngineType,						-- V1.11
		'' AS LeadVehSaleType,				-- V1.16
		'' AS LeadOrigin,					-- V1.16
		'' AS LegalGrounds ,                -- V1.17
		'' AS AnonymityQuestion,            -- V1.17
		'' AS LandRoverExperienceID,		-- V1.23
		O.BusinessFlag,						-- V1.24
		O.CommonSaleType,					-- V1.24
		O.SubBrand							-- V1.25
	FROM SelectionOutput.OnlineOutput O
		INNER JOIN Event.vwEventTypes ET ON	ET.EventTypeID = O.etype 
											AND ET.EventCategory = 'Sales' 
		INNER JOIN Event.EventTypes ET1 ON ET1.EventTypeID = O.etype										-- V1.18
		LEFT JOIN dbo.DW_JLRCSPDealers D ON O.OutletPartyID = D.OutletPartyID								-- V1.18
											AND ET1.RelatedOutletFunctionID = D.OutletFunctionID			-- V1.18
		LEFT JOIN CTE_CRMInfoSales CRM ON CRM.CaseID = O.ID
		LEFT JOIN [$(ETLDB)].CRM.Vista_Contract_Sales VCS ON VCS.AuditItemID = CRM.AuditItemID
		--LEFT JOIN [$(ETLDB)].China.Sales_WithResponses CSR ON O.ID = CSR.CaseID 		-- V1.8								
	--WHERE ((@RussiaOutput = 1 AND ISNULL(O.CTRY,'') = 'Russian Federation') OR (@RussiaOutput = 0 AND ISNULL(O.CTRY,'') <> 'Russian Federation'))	-- V1.20
		--AND CSR.CaseID IS NULL														-- V1.8
	----------------------------------------------------------


	----------------------------------------------------------
	-- Service Output
	;WITH CTE_CRMInfoService (CaseID, AuditItemID) AS 
	(
		SELECT SL.CaseID, 
			MAX(SL.AuditItemID) AS AuditItemID
		FROM SelectionOutput.OnlineOutput O
			INNER JOIN Event.vwEventTypes ET ON	ET.EventTypeID = O.etype 
												AND	ET.EventCategory = 'Service'
			INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL ON SL.CaseID = O.ID
			INNER JOIN [$(ETLDB)].CRM.DMS_Repair_Service DRS ON SL.AuditItemID = DRS.AuditItemID
			--LEFT JOIN [$(ETLDB)].China.Service_WithResponses CSR ON O.ID = CSR.CaseID 	-- V1.8									
		--WHERE CSR.CaseID IS NULL															-- V1.8
		GROUP BY SL.CaseID
	)
	INSERT INTO SelectionOutput.CombinedOnlineOutput
    SELECT O.ID AS ID,
		O.etype AS SurveyTypeID,
		O.modelcode AS ModelCode,
		O.FullModel AS ModelDescription,
		CASE WHEN O.ModelYear = 0 THEN ''
			ELSE CAST(O.ModelYear AS VARCHAR) END AS ModelYear,				-- V1.27
		O.manuf AS ManufacturerID,
		O.sType AS Manufacturer,
		REPLACE(O.CarReg, CHAR(9), '') AS CarRegistration,
		REPLACE(O.VIN, CHAR(9), '') AS VIN,
		O.VariantID AS ModelVariantCode,
		O.ModelVariant AS ModelVariantDescription,
		O.PartyID AS PartyID,
		REPLACE(O.Title, CHAR(9), '') AS Title,
		REPLACE(O.Initial, CHAR(9), '') AS Initial,
		REPLACE(O.Surname, CHAR(9), '') AS LastName,
		REPLACE(O.Fullname, CHAR(9), '') AS FullName,
		REPLACE(O.DearName, CHAR(9), '') AS DearName,
		REPLACE(O.CoName, CHAR(9), '') AS CompanyName,
		REPLACE(O.Add1, CHAR(9), '') AS Address1,
		REPLACE(O.Add2, CHAR(9), '') AS Address2,
		REPLACE(O.Add3, CHAR(9), '') AS Address3,
		REPLACE(O.Add4, CHAR(9), '') AS Address4,
		REPLACE(O.Add5, CHAR(9), '') AS Address5,
		REPLACE(O.Add6, CHAR(9), '') AS Address6,
		REPLACE(O.Add7, CHAR(9), '') AS Address7,
		REPLACE(O.Add8, CHAR(9), '') AS Address8,
		O.CTRY AS Country,
		O.ccode AS CountryID,
		O.EmailAddress AS EmailAddress,
		REPLACE(O.Telephone, CHAR(9), '') AS HomeNumber,
		REPLACE(O.WorkTel, CHAR(9), '') AS WorkNumber,
		REPLACE(O.MobilePhone, CHAR(9), '') AS MobileNumber,
		REPLACE(O.CustomerIdentifier, CHAR(9), '') AS CustomerUniqueID,
		O.sno AS VersionCode,
		O.lang AS LanguageID,
		O.gender AS GenderID,
		O.etype AS EventTypeID,
		REPLACE(CONVERT(VARCHAR(10), O.EventDate, 102), '.', '-') AS EventDate,
		O.Password AS Password,
		O.ITYPE AS IType,
		CASE	WHEN O.Itype ='T' THEN  CONVERT(NVARCHAR(10), @dtCATI, 121)
				ELSE CONVERT(NVARCHAR(10), @NOW, 121) END AS SelectionDate,
		O.week AS Week,
		O.Expired AS Expired,
		CONVERT(NVARCHAR(100),
		CONVERT(VARCHAR(10), ISNULL(O.etype, '')) + '_'
		+ CASE	WHEN ISNULL(O.ITYPE, '') = '' THEN 'blank'
				ELSE O.ITYPE END + '_' 
		+ CONVERT(VARCHAR(10), ISNULL(O.ccode, '')) + '_'
		+ CASE	WHEN O.manuf = 2 THEN 'J'
				WHEN O.manuf = 3 THEN 'L'
				ELSE 'UknownManufacturer' END + '_' 
		+ CONVERT(VARCHAR(10), ISNULL(O.lang, ''))) AS CampaignID,
		O.Test AS Test,
		O.OutletPartyID AS DealerPartyID,
		O.ReportingDealerPartyID AS ReportingDealerPartyID,
		O.Dealer AS DealerName,
		O.DealerCode AS DealerCode,
		O.GDDDealerCode AS GlobalDealerCode,
		O.blank AS BusinessRegion,
		O.OwnershipCycle AS OwnershipCycle,
		REPLACE(O.EmailSignator, CHAR(10), '<br/>') AS EmailSignator,
		REPLACE(O.EmailSignatorTitle, CHAR(10), '<br/>') AS EmailSignatorTitle,
		REPLACE(O.EmailContactText, CHAR(10), '<br/>') AS EmailContactText,
		REPLACE(O.EmailCompanyDetails, CHAR(10), '<br/>') AS EmailCompanyDetails,
		REPLACE(O.JLRPrivacyPolicy, CHAR(10), '<br/>') AS JLRPrivacyPolicy,
		REPLACE(O.JLRCompanyname, CHAR(10), '<br/>') AS JLRCompanyName,
		O.UnknownLang AS UnknownLanguage,
		O.BilingualFlag AS BilingualFlag,
		O.langBilingual AS BilingualLanguageID,
		O.DearNameBilingual AS DearNameBilingual,
		O.EmailSignatorTitleBilingual AS EmailSignatorTitleBilingual,
		O.EmailContactTextBilingual AS EmailContactTextBilingual,
		O.EmailCompanyDetailsBilingual AS EmailCompanyDetailsBilingual,
		O.JLRPrivacyPolicyBilingual AS JLRPrivacyPolicyBilingual,
		CASE	WHEN DRS.AuditItemID IS NULL THEN O.EmployeeCode 
				ELSE '' END AS EmployeeCode,
		CASE	WHEN DRS.AudititemID IS NULL THEN CASE	WHEN D.PAGCode IS NULL THEN O.EmployeeName									-- V1.18
														WHEN LEN(O.EmployeeName) > 0 THEN O.EmployeeName + ' (' + D.PAGCode + ')'	-- V1.18
														ELSE '' END																	-- V1.18
				ELSE '' END AS EmployeeName,																						-- V1.18
		'' AS CRMSalesmanCode,
		'' AS CRMSalesmanName,
		ISNULL(O.RockarDealer, 0) AS RockarDealer,
		ISNULL(O.SVOvehicle, '') AS SVOTypeID,					-- V1.4
		ISNULL(O.SVODealer, '') AS SVODealer,					-- V1.4
		'' AS VistaContractOrderNumber,
		'' AS DealerNumber,
		O.FOBCode AS FOBCode,
		O.HotTopicCodes AS HotTopicCodes,
		ISNULL(COALESCE(DRS.[DMS_TECHNICIAN_ID], O.TechnicianID), '') AS ServiceTechnicianID,
		CASE	WHEN D.PAGCode IS NULL THEN ISNULL(COALESCE(DRS.[DMS_TECHNICIAN], O.TechnicianName), '')																	-- V1.18
				WHEN LEN(ISNULL(COALESCE(DRS.[DMS_TECHNICIAN], O.TechnicianName), ''))>0 THEN COALESCE(DRS.[DMS_TECHNICIAN], O.TechnicianName) + ' (' + D.PAGCode + ')'		-- V1.18
				ELSE '' END AS ServiceTechnicianName,																														-- V1.18
		ISNULL(COALESCE(DRS.[DMS_SERVICE_ADVISOR_ID], O.ServiceAdvisorID), '') AS ServiceAdvisorID,
		CASE	WHEN D.PAGCode IS NULL THEN ISNULL(COALESCE(DRS.[DMS_SERVICE_ADVISOR], O.ServiceAdvisorName), '')																			-- V1.18
				WHEN LEN(ISNULL(COALESCE(DRS.[DMS_SERVICE_ADVISOR], O.ServiceAdvisorName), ''))>0 THEN COALESCE(DRS.[DMS_SERVICE_ADVISOR], O.ServiceAdvisorName) + ' (' + D.PAGCode + ')'	-- V1.18
				ELSE '' END AS ServiceAdvisorName,																																			-- V1.18
		O.RepairOrderNumber AS RepairOrderNumber,
		O.ServiceEventType AS ServiceEventType,
		'' AS Approved,
		'' AS BreakdownDate,
		'' AS BreakdownCountry,
		'' AS BreakdownCountryID,
		'' AS BreakdownCaseID,
		'' AS CarHireStartDate,
		'' AS ReasonForHire,
		'' AS HireGroupBranch,
		'' AS CarHireTicketNumber,
		'' AS HireJobNumber,
		'' AS RepairingDealer,
		'' AS DataSource,
		'' AS ReplacementVehicleMake,
		'' AS ReplacementVehicleModel,
		'' AS CarHireStartTime,
		'' AS RepairingDealerCountry,
		'' AS RoadsideAssistanceProvider,
		'' AS BreakdownAttendingResource,
		'' AS CarHireProvider,
		'' AS VehicleOriginCountry,
		'' AS CRCOwnerCode,
		'' AS CRCCode,
		'' AS CRCMarketCode,
		'' AS SampleYear,
		'' AS VehicleMileage,
		'' AS VehicleMonthsinService,
		'' AS CRCRowID,
		'' AS CRCSerialNumber,
		'' AS NSCFlag,
		'' AS JLREventType,
		'' AS DealerType,
		'' AS Queue,
		O.Dealer10DigitCode,				-- V1.2
		O.EventID,							-- V1.3
		O.EngineType,						-- V1.11
		'' AS LeadVehSaleType,				-- V1.16
		'' AS LeadOrigin,					-- V1.16
		'' AS LegalGrounds ,                -- V1.17
		'' AS AnonymityQuestion,            -- V1.17
		'' AS LandRoverExperienceID,		-- V1.23
		'' AS BusinessFlag,					-- V1.24
		'' AS CommonSaleType,				-- V1.24
		O.SubBrand							-- V1.25
    FROM SelectionOutput.OnlineOutput O
        INNER JOIN Event.vwEventTypes ET ON	ET.EventTypeID = O.etype 
											AND	ET.EventCategory = 'Service'
		INNER JOIN Event.EventTypes ET1 ON ET1.EventTypeID = O.etype										-- V1.18
		LEFT JOIN dbo.DW_JLRCSPDealers D ON O.OutletPartyID = D.OutletPartyID								-- V1.18
											AND ET1.RelatedOutletFunctionID = D.OutletFunctionID			-- V1.18
		LEFT JOIN CTE_CRMInfoService CRM ON CRM.CaseID = O.ID
		LEFT JOIN [$(ETLDB)].CRM.DMS_Repair_Service DRS ON DRS.AuditItemID = CRM.AuditItemID
		--LEFT JOIN [$(ETLDB)].China.Service_WithResponses CSR ON O.ID = CSR.CaseID 	-- V1.8							
	--WHERE ((@RussiaOutput = 1 AND ISNULL(O.CTRY,'') = 'Russian Federation') OR (@RussiaOutput = 0 AND ISNULL(O.CTRY,'') <> 'Russian Federation'))		-- V1.20
		--AND CSR.CaseID IS NULL														-- V1.8
	----------------------------------------------------------


	----------------------------------------------------------
	-- Roadside Output
	;WITH CTE_Events_Roadside (EventID, AuditItemID) AS 
	(
		SELECT AEBI.EventID, 
			RE.AuditItemID
		FROM SelectionOutput.OnlineOutput O
			INNER JOIN Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = O.ID 
			INNER JOIN [$(AuditDB)].Audit.Events AE ON AE.EventID = AEBI.EventID
			INNER JOIN [$(ETLDB)].Roadside.RoadsideEvents RE ON RE.AuditItemID = AE.AuditItemID
		UNION
		SELECT AEBI.EventID, 
			REP.AuditItemID
		FROM SelectionOutput.OnlineOutput O
			INNER JOIN Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = O.ID 
			INNER JOIN [$(AuditDB)].Audit.Events AE ON AE.EventID = AEBI.EventID
			INNER JOIN [$(ETLDB)].Roadside.RoadsideEventsProcessed REP ON REP.AuditItemID = AE.AuditItemID
	)
	, CTE_DeDuped_Events (EventID, AuditItemID) AS 
	(
		SELECT EventID , 
			MAX(AuditItemID)
		FROM CTE_Events_Roadside
		GROUP BY EventID
	)
	, CTE_RoadsideEventData AS 
	(
		SELECT 
			E.EventID,
			COALESCE(REP.BreakdownDate, REP.CarHireStartDate,'') AS BreakdownDate, 
			COALESCE(REP.BreakdownDateOrig, REP.CarHireStartDateOrig,'') AS BreakdownDateOrig, 
			--REP.BreakdownDate, 
			--REP.BreakdownDateOrig,
			REP.BreakdownCountry, 
			REP.BreakdownCountryID, 
			REP.BreakdownCaseId, 
			CAST(REP.CarHireStartDate AS DATE) AS CarHireStartDate,			-- V1.10
			REP.ReasonForHire, 
			REP.HireGroupBranch, 
			REP.CarHireTicketNumber, 
			REP.HireJobNumber, 
			REP.RepairingDealer, 
			REP.DataSource,
			REP.ReplacementVehicleMake,
			REP.ReplacementVehicleModel,
			REP.VehicleReplacementTime,
			REP.CarHireStartTime,
			REP.ConvertedCarHireStartTime,
			REP.RepairingDealerCountry,
			REP.RoadsideAssistanceProvider,
			REP.BreakdownAttendingResource,
			REP.CarHireProvider,
			REP.CountryCodeISOAlpha2,
			REP.BreakdownCountryISOAlpha2,
			REP.DealerCode,
			REP.CountryCode AS VehicleOriginCountry
		FROM [$(ETLDB)].Roadside.RoadsideEventsProcessed REP
			INNER JOIN CTE_DeDuped_Events E ON E.AuditItemID = REP.AuditItemID
			INNER JOIN [$(AuditDB)].Audit.Events AE ON REP.AuditItemID = AE.AuditItemID 
		UNION 
		SELECT 
			E.EventID,
			COALESCE(RE.BreakdownDate, RE.CarHireStartDate,'') AS BreakdownDate, 
			COALESCE(RE.BreakdownDateOrig, RE.CarHireStartDateOrig,'') AS BreakdownDateOrig, 
			--RE.BreakdownDate, 
			--RE.BreakdownDateOrig,
			RE.BreakdownCountry, 
			RE.BreakdownCountryID, 
			RE.BreakdownCaseId, 
			CAST(RE.CarHireStartDate AS DATE) AS CarHireStartDate,			-- V1.10
			RE.ReasonForHire, 
			RE.HireGroupBranch, 
			RE.CarHireTicketNumber, 
			RE.HireJobNumber, 
			RE.RepairingDealer, 
			RE.DataSource,
			RE.ReplacementVehicleMake,
			RE.ReplacementVehicleModel,
			RE.VehicleReplacementTime,
			RE.CarHireStartTime,
			RE.ConvertedCarHireStartTime,
			RE.RepairingDealerCountry,
			RE.RoadsideAssistanceProvider,
			RE.BreakdownAttendingResource,
			RE.CarHireProvider,
			RE.CountryCodeISOAlpha2,
			RE.BreakdownCountryISOAlpha2,
			RE.DealerCode,
			RE.CountryCode AS VehicleOriginCountry
		FROM [$(ETLDB)].Roadside.RoadsideEvents RE
			INNER JOIN CTE_DeDuped_Events E ON E.AuditItemID = RE.AuditItemID
			INNER JOIN [$(AuditDB)].Audit.Events AE ON RE.AuditItemID = AE.AuditItemID 
	)
	INSERT INTO SelectionOutput.CombinedOnlineOutput
	SELECT O.ID AS ID,
		O.etype AS SurveyTypeID,
		O.modelcode AS ModelCode,
		O.FullModel AS ModelDescription,
		CASE WHEN O.ModelYear = 0 THEN ''
			ELSE CAST(O.ModelYear AS VARCHAR) END AS ModelYear,				-- V1.27
		O.manuf AS ManufacturerID,
		O.sType AS Manufacturer,
		REPLACE(O.CarReg, CHAR(9), '') AS CarRegistration,
		REPLACE(O.VIN, CHAR(9), '') AS VIN,
        O.VariantID AS ModelVariantCode,                          -- V1.22
		O.ModelVariant AS ModelVariantDescription,                -- V1.22
		O.PartyID AS PartyID,
		REPLACE(O.Title, CHAR(9), '') AS Title,
		REPLACE(O.Initial, CHAR(9), '') AS Initial,
		REPLACE(O.Surname, CHAR(9), '') AS LastName,
		REPLACE(O.Fullname, CHAR(9), '') AS FullName,
		REPLACE(O.DearName, CHAR(9), '') AS DearName,
		REPLACE(O.CoName, CHAR(9), '') AS CompanyName,
		REPLACE(O.Add1, CHAR(9), '') AS Address1,
		REPLACE(O.Add2, CHAR(9), '') AS Address2,
		REPLACE(O.Add3, CHAR(9), '') AS Address3,
		REPLACE(O.Add4, CHAR(9), '') AS Address4,
		REPLACE(O.Add5, CHAR(9), '') AS Address5,
		REPLACE(O.Add6, CHAR(9), '') AS Address6,
		REPLACE(O.Add7, CHAR(9), '') AS Address7,
		REPLACE(O.Add8, CHAR(9), '') AS Address8,
		O.CTRY AS Country,
		O.ccode AS CountryID,
		O.EmailAddress AS EmailAddress,
		REPLACE(O.Telephone, CHAR(9), '') AS HomeNumber,
		REPLACE(O.WorkTel, CHAR(9), '') AS WorkNumber,
		REPLACE(O.MobilePhone, CHAR(9), '') AS MobileNumber,
		--'' AS CustomerUniqueID,
		REPLACE(O.CustomerIdentifier, CHAR(9), '') AS CustomerUniqueID,		--V1.19
		O.sno AS VersionCode,
		O.lang AS LanguageID,
		O.gender AS GenderID,
		O.etype AS EventTypeID,
		'' AS EventDate,
		O.Password AS Password,
		O.ITYPE AS IType,
		CASE	WHEN O.Itype ='T' THEN  CONVERT(NVARCHAR(10), @dtCATI, 121)
				ELSE CONVERT(NVARCHAR(10), @NOW, 121) END AS SelectionDate,
		O.week AS Week,
		O.Expired AS Expired,
		'' AS CampaignID,
		O.test AS Test,
		'' AS DealerPartyID,
		'' AS ReportingDealerPartyID,
		O.Dealer AS DealerName,
		'' AS DealerCode,
		'' AS GlobalDealerCode,
		O.blank AS BusinessRegion,
		'' AS OwnershipCycle,
		REPLACE(O.EmailSignator, CHAR(10), '<br/>') AS EmailSignator,
		REPLACE(O.EmailSignatorTitle, CHAR(10), '<br/>') AS EmailSignatorTitle,
		REPLACE(O.EmailContactText, CHAR(10), '<br/>') AS EmailContactText,
		REPLACE(O.EmailCompanyDetails, CHAR(10), '<br/>') AS EmailCompanyDetails,
		REPLACE(O.JLRPrivacyPolicy, CHAR(10), '<br/>') AS JLRPrivacyPolicy,
		REPLACE(O.JLRCompanyname, CHAR(10), '<br/>') AS JLRCompanyName,
		'' AS UnknownLanguage,
		O.BilingualFlag AS BilingualFlag,
		O.langBilingual AS BilingualLanguageID,
		O.DearNameBilingual AS DearNameBilingual,
		O.EmailSignatorTitleBilingual AS EmailSignatorTitleBilingual,
		O.EmailContactTextBilingual AS EmailContactTextBilingual,
		O.EmailCompanyDetailsBilingual AS EmailCompanyDetailsBilingual,
		O.JLRPrivacyPolicyBilingual AS JLRPrivacyPolicyBilingual,
		'' AS EmployeeCode,
		'' AS EmployeeName,
		'' AS CRMSalesmanCode,
		'' AS CRMSalesmanName,
		'' AS RockarDealer,
		ISNULL(O.SVOvehicle, '') AS SVOTypeID,										-- V1.13
		'' AS SVODealer,
		'' AS VistaContractOrderNumber,
		'' AS DealerNumber,
		'' AS FOBCode,
		'' AS HotTopicCodes,
		'' AS ServiceTechnicianID,
		'' AS ServiceTechnicianName,
		'' AS ServiceAdvisorID,
		'' AS ServiceAdvisorName,
		'' AS RepairOrderNumber,
		'' AS ServiceEventType,
		'' AS Approved,
		RED.BreakdownDate AS BreakdownDate,
		COALESCE(RED.BreakdownCountryISOAlpha2, RED.BreakdownCountry) AS BreakdownCountry,
		RED.BreakdownCountryID AS BreakdownCountryID,
		REPLACE(RED.BreakdownCaseID, CHAR(9), '') AS BreakdownCaseID,
		REPLACE(RED.CarHireStartDate, CHAR(9), '') AS CarHireStartDate,
		REPLACE(RED.ReasonForHire, CHAR(9), '') AS ReasonForHire,
		REPLACE(RED.HireGroupBranch, CHAR(9), '') AS HireGroupBranch,
		REPLACE(RED.CarHireTicketNumber, CHAR(9), '') AS CarHireTicketNumber,
		REPLACE(RED.HireJobNumber, CHAR(9), '') AS HireJobNumber,
		REPLACE(RED.RepairingDealer, CHAR(9), '') AS RepairingDealer,
		REPLACE(RED.DataSource, CHAR(9), '') AS DataSource,
		REPLACE(RED.ReplacementVehicleMake, CHAR(9), '') AS ReplacementVehicleMake,
		REPLACE(RED.ReplacementVehicleModel, CHAR(9), '') AS ReplacementVehicleModel,
		RED.ConvertedCarHireStartTime AS CarHireStartTime,
		REPLACE(RED.RepairingDealerCountry, CHAR(9), '') AS RepairingDealerCountry,
		REPLACE(RED.RoadsideAssistanceProvider, CHAR(9), '') AS RoadsideAssistanceProvider,
		REPLACE(RED.BreakdownAttendingResource, CHAR(9), '') AS BreakdownAttendingResource,
		REPLACE(RED.CarHireProvider, CHAR(9), '') AS CarHireProvider,
		REPLACE(RED.VehicleOriginCountry, CHAR(9), '') AS VehicleOriginCountry,
		'' AS CRCOwnerCode,
		'' AS CRCCode,
		'' AS CRCMarketCode,
		'' AS SampleYear,
		'' AS VehicleMileage,
		'' AS VehicleMonthsinService,
		'' AS CRCRowID,
		'' AS CRCSerialNumber,
		'' AS NSCFlag,
		'' AS JLREventType,
		'' AS DealerType,
		'' AS Queue,
		O.Dealer10DigitCode,			-- V1.2
		O.EventID,						-- V1.3
		O.EngineType,						-- V1.11
		'' AS LeadVehSaleType,				-- V1.16
		'' AS LeadOrigin,					-- V1.16
		'' AS LegalGrounds ,                -- V1.17
		'' AS AnonymityQuestion,            -- V1.17
		'' AS LandRoverExperienceID,		-- V1.23
		'' AS BusinessFlag,					-- V1.24
		'' AS CommonSaleType,				-- V1.24
		O.SubBrand							-- V1.25
	FROM SelectionOutput.OnlineOutput O 
		INNER JOIN Event.vwEventTypes ET ON ET.EventTypeID = O.etype
		INNER JOIN Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = O.ID 
		INNER JOIN CTE_RoadsideEventData RED ON RED.EventID = AEBI.EventID
		INNER JOIN Contactmechanism.Countries CN ON O.ccode = CN.CountryID
		--LEFT JOIN [$(ETLDB)].China.Roadside_WithResponses CSR ON O.ID = CSR.CaseID	-- V1.8
	WHERE (ET.EventCategory = 'Roadside')
		--AND ((@RussiaOutput = 1 AND ISNULL(O.CTRY,'') = 'Russian Federation') OR  (@RussiaOutput = 0 AND ISNULL(O.CTRY,'') <> 'Russian Federation'))		-- V1.20
		--AND (CN.Country NOT IN ('United States of America','Canada'))					-- V1.9
		--AND CSR.CaseID IS NULL														-- V1.8
	----------------------------------------------------------


	----------------------------------------------------------
	-- PreOwned Output
	;WITH CTE_CRMInfoPreOwned (CaseID, AuditItemID) AS										-- V1.12
	(
		SELECT SL.CaseID, 
			MAX(SL.AuditItemID) AS AuditItemID
		FROM SelectionOutput.OnlineOutput O
			INNER JOIN Event.vwEventTypes ET ON	ET.EventTypeID = O.etype 
												AND	ET.EventCategory = 'PreOwned'
			INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL ON SL.CaseID = O.ID
			INNER JOIN [$(ETLDB)].CRM.PreOwned P ON SL.AuditItemID = P.AuditItemID
			--LEFT JOIN [$(ETLDB)].China.Service_WithResponses CSR ON O.ID = CSR.CaseID 	-- V1.8									
		--WHERE CSR.CaseID IS NULL															-- V1.8
		GROUP BY SL.CaseID
	)
	INSERT INTO SelectionOutput.CombinedOnlineOutput
	SELECT DISTINCT
		O.ID AS ID,
		O.etype AS SurveyTypeID,
		O.modelcode AS ModelCode,
		O.FullModel AS ModelDescription,
		CASE WHEN O.ModelYear = 0 THEN ''
			ELSE CAST(O.ModelYear AS VARCHAR) END AS ModelYear,				-- V1.27
		O.manuf AS ManufacturerID,
		O.sType AS Manufacturer,
		REPLACE(O.CarReg, CHAR(9), '') AS CarRegistration,
		REPLACE(O.VIN, CHAR(9), '') AS VIN,
		O.VariantID AS ModelVariantCode,
		O.ModelVariant AS ModelVariantDescription,
		O.PartyID AS PartyID,
		REPLACE(O.Title, CHAR(9), '') AS Title,
		REPLACE(O.Initial, CHAR(9), '') AS Initial,
		REPLACE(O.Surname, CHAR(9), '') AS LastName,
		REPLACE(O.Fullname, CHAR(9), '') AS FullName,
		REPLACE(O.DearName, CHAR(9), '') AS DearName,
		REPLACE(O.CoName, CHAR(9), '') AS CompanyName,
		REPLACE(O.Add1, CHAR(9), '') AS Address1,
		REPLACE(O.Add2, CHAR(9), '') AS Address2,
		REPLACE(O.Add3, CHAR(9), '') AS Address3,
		REPLACE(O.Add4, CHAR(9), '') AS Address4,
		REPLACE(O.Add5, CHAR(9), '') AS Address5,
		REPLACE(O.Add6, CHAR(9), '') AS Address6,
		REPLACE(O.Add7, CHAR(9), '') AS Address7,
		REPLACE(O.Add8, CHAR(9), '') AS Address8,
		O.CTRY AS Country,
		O.ccode AS CountryID,
		O.EmailAddress AS EmailAddress,
		REPLACE(O.Telephone, CHAR(9), '') AS HomeNumber,
		REPLACE(O.WorkTel, CHAR(9), '') AS WorkNumber,
		REPLACE(O.MobilePhone, CHAR(9), '') AS MobileNumber,
		REPLACE(O.CustomerIdentifier, CHAR(9), '') AS CustomerUniqueID,
		O.sno AS VersionCode,
		O.lang AS LanguageID,
		O.gender AS GenderID,
		O.etype AS EventTypeID,
		REPLACE(CONVERT(VARCHAR(10), O.EventDate, 102), '.', '-') AS EventDate,
		O.Password AS Password,
		O.ITYPE AS IType,
		CASE	WHEN O.Itype ='T' THEN  CONVERT(NVARCHAR(10), @dtCATI, 121)
				ELSE CONVERT(NVARCHAR(10), @NOW, 121) END AS SelectionDate,
		O.week AS Week,
		O.Expired AS Expired,
		CONVERT(NVARCHAR(100),
		CONVERT(VARCHAR(10), ISNULL(O.etype, '')) + '_'
		+ CASE	WHEN ISNULL(O.ITYPE, '') = '' THEN 'blank'
				ELSE O.ITYPE END + '_' 
		+ CONVERT(VARCHAR(10), ISNULL(O.ccode, '')) + '_'
		+ CASE	WHEN O.manuf = 2 THEN 'J'
				WHEN O.manuf = 3 THEN 'L'
				ELSE 'UknownManufacturer' END + '_' 
		+ CONVERT(VARCHAR(10), ISNULL(O.lang, ''))) AS CampaignID,
		O.Test AS Test,
		O.OutletPartyID AS DealerPartyID,
		O.ReportingDealerPartyID AS ReportingDealerPartyID,
		O.Dealer AS DealerName,
		O.DealerCode AS DealerCode,
		O.GDDDealerCode AS GlobalDealerCode,
		O.blank AS BusinessRegion,
		O.OwnershipCycle AS OwnershipCycle,
		REPLACE(O.EmailSignator, CHAR(10), '<br/>') AS EmailSignator,
		REPLACE(O.EmailSignatorTitle, CHAR(10), '<br/>') AS EmailSignatorTitle,
		REPLACE(O.EmailContactText, CHAR(10), '<br/>') AS EmailContactText,
		REPLACE(O.EmailCompanyDetails, CHAR(10), '<br/>') AS EmailCompanyDetails,
		REPLACE(O.JLRPrivacyPolicy, CHAR(10), '<br/>') AS JLRPrivacyPolicy,
		REPLACE(O.JLRCompanyname, CHAR(10), '<br/>') AS JLRCompanyName,
		'' AS UnknownLanguage,
		O.BilingualFlag AS BilingualFlag,
		O.langBilingual AS BilingualLanguageID,
		O.DearNameBilingual AS DearNameBilingual,
		O.EmailSignatorTitleBilingual AS EmailSignatorTitleBilingual,
		O.EmailContactTextBilingual AS EmailContactTextBilingual,
		O.EmailCompanyDetailsBilingual AS EmailCompanyDetailsBilingual,
		O.JLRPrivacyPolicyBilingual AS JLRPrivacyPolicyBilingual,
		CASE	WHEN P.AuditItemID IS NULL THEN O.EmployeeCode 
				ELSE '' END AS EmployeeCode,																-- V1.12
		CASE	WHEN P.AudititemID IS NULL THEN CASE	WHEN D.PAGCode IS NULL THEN O.EmployeeName									-- V1.18
														WHEN LEN(O.EmployeeName) > 0 THEN O.EmployeeName + ' (' + D.PAGCode + ')'	-- V1.18
														ELSE '' END																	-- V1.18
				ELSE '' END AS EmployeeName,																						-- V1.18
		ISNULL(COALESCE(P.VISTACONTRACT_SALESMAN_CODE, O.SalesAdvisorID), '') AS CRMSalesmanCode,			-- V1.12
		CASE	WHEN D.PAGCode IS NULL THEN ISNULL(COALESCE(P.VISTACONTRACT_SALES_MAN_FULNAM, O.SalesAdvisorName), '')																				-- V1.18
				WHEN LEN(ISNULL(COALESCE(P.VISTACONTRACT_SALES_MAN_FULNAM, O.SalesAdvisorName), ''))>0 THEN COALESCE(P.VISTACONTRACT_SALES_MAN_FULNAM, O.SalesAdvisorName) + ' (' + D.PAGCode + ')'	-- V1.18
				ELSE '' END AS CRMSalesmanName,																																						-- V1.18
		'' AS RockarDealer,
		ISNULL(O.SVOvehicle, '') AS SVOTypeID,																-- V1.13
		'' AS SVODealer,
		'' AS VistaContractOrderNumber,
		'' AS DealerNumber,
		O.FOBCode AS FOBCode,
		O.HotTopicCodes AS HotTopicCodes,
		'' AS ServiceTechnicianID,
		'' AS ServiceTechnicianName,
		'' AS ServiceAdvisorID,
		'' AS ServiceAdvisorName,
		'' AS RepairOrderNumber,
		'' AS ServiceEventType,
		'APPROVED' AS Approved,																				-- V1.10
		'' AS BreakdownDate,
		'' AS BreakdownCountry,
		'' AS BreakdownCountryID,
		'' AS BreakdownCaseID,
		'' AS CarHireStartDate,
		'' AS ReasonForHire,
		'' AS HireGroupBranch,
		'' AS CarHireTicketNumber,
		'' AS HireJobNumber,
		'' AS RepairingDealer,
		'' AS DataSource,
		'' AS ReplacementVehicleMake,
		'' AS ReplacementVehicleModel,
		'' AS CarHireStartTime,
		'' AS RepairingDealerCountry,
		'' AS RoadsideAssistanceProvider,
		'' AS BreakdownAttendingResource,
		'' AS CarHireProvider,
		'' AS VehicleOriginCountry,
		'' AS CRCOwnerCode,
		'' AS CRCCode,
		'' AS CRCMarketCode,
		'' AS SampleYear,
		'' AS VehicleMileage,
		'' AS VehicleMonthsinService,
		'' AS CRCRowID,
		'' AS CRCSerialNumber,
		'' AS NSCFlag,
		'' AS JLREventType,
		'' AS DealerType,
		'' AS Queue,
		O.Dealer10DigitCode,				-- V1.2
		O.EventID,							-- V1.3
		O.EngineType,						-- V1.11
		'' AS LeadVehSaleType,				-- V1.16
		'' AS LeadOrigin,					-- V1.16
		'' AS LegalGrounds ,                -- V1.17
		'' AS AnonymityQuestion,            -- V1.17
		'' AS LandRoverExperienceID,		-- V1.23
		'' AS BusinessFlag,					-- V1.24
		'' AS CommonSaleType,				-- V1.24
		O.SubBrand							-- V1.25
	FROM SelectionOutput.OnlineOutput O
        INNER JOIN Event.vwEventTypes ET ON ET.EventTypeID = O.etype 
											AND ET.EventCategory = 'PreOwned' 
		INNER JOIN Event.EventTypes ET1 ON ET1.EventTypeID = O.etype										-- V1.18
		LEFT JOIN dbo.DW_JLRCSPDealers D ON O.OutletPartyID = D.OutletPartyID								-- V1.18
											AND ET1.RelatedOutletFunctionID = D.OutletFunctionID			-- V1.18
		INNER JOIN Event.AutomotiveEventBasedInterviews AEBI ON O.ID = AEBI.CaseID
		INNER JOIN Event.AdditionalInfoSales AIS ON AIS.EventID = AEBI.EventID
		LEFT JOIN CTE_CRMInfoPreOwned CRM ON CRM.CaseID = O.ID							-- V1.12
		LEFT JOIN [$(ETLDB)].CRM.PreOwned P ON P.AuditItemID = CRM.AuditItemID			-- V1.12
		--INNER JOIN Vehicle.Vehicles VEH ON O.VIN = VEH.VIN
		--LEFT JOIN [$(ETLDB)].China.Sales_WithResponses CSR ON O.ID = CSR.CaseID 		-- V1.8									
	--WHERE ((@RussiaOutput = 1 AND ISNULL(O.CTRY,'') = 'Russian Federation') OR  (@RussiaOutput = 0 AND ISNULL(O.CTRY,'') <> 'Russian Federation'))	-- V1.20
		--AND CSR.CaseID IS NULL														-- V1.8
	----------------------------------------------------------


	----------------------------------------------------------
	-- LostLeads Output -- V1.16
	;WITH CTE_CRMInfoLostLeads (CaseID, AuditItemID) AS										
	(
		SELECT SL.CaseID, 
			MAX(SL.AuditItemID) AS AuditItemID
		FROM SelectionOutput.OnlineOutput O	
		--	INNER JOIN Event.vwEventTypes ET ON	ET.EventTypeID = O.etype										-- V1.21
		--										AND	ET.EventCategory = 'LostLeads'								-- V1.21
			INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL ON SL.CaseID = O.ID
			INNER JOIN [$(ETLDB)].CRM.Lost_Leads L ON SL.AuditItemID = L.AuditItemID
			--LEFT JOIN [$(ETLDB)].China.Service_WithResponses CSR ON O.ID = CSR.CaseID 									
		--WHERE CSR.CaseID IS NULL															
		GROUP BY SL.CaseID
	) -- V1.16
	INSERT INTO SelectionOutput.CombinedOnlineOutput
    SELECT O.ID AS ID,
		O.etype AS SurveyTypeID,
		O.modelcode AS ModelCode,
		O.FullModel AS ModelDescription,
		CASE WHEN O.ModelYear = 0 THEN ''
			ELSE CAST(O.ModelYear AS VARCHAR) END AS ModelYear,				-- V1.27
		O.manuf AS ManufacturerID,
		O.sType AS Manufacturer,
		REPLACE(O.CarReg, CHAR(9), '') AS CarRegistration,
		'' AS VIN,											-- V1.27
		O.VariantID AS ModelVariantCode,
		O.ModelVariant AS ModelVariantDescription,
		O.PartyID AS PartyID,
		REPLACE(O.Title, CHAR(9), '') AS Title,
		REPLACE(O.Initial, CHAR(9), '') AS Initial,
		REPLACE(O.Surname, CHAR(9), '') AS LastName,
		REPLACE(O.Fullname, CHAR(9), '') AS FullName,
		REPLACE(O.DearName, CHAR(9), '') AS DearName,
		REPLACE(O.CoName, CHAR(9), '') AS CompanyName,
		REPLACE(O.Add1, CHAR(9), '') AS Address1,
		REPLACE(O.Add2, CHAR(9), '') AS Address2,
		REPLACE(O.Add3, CHAR(9), '') AS Address3,
		REPLACE(O.Add4, CHAR(9), '') AS Address4,
		REPLACE(O.Add5, CHAR(9), '') AS Address5,
		REPLACE(O.Add6, CHAR(9), '') AS Address6,
		REPLACE(O.Add7, CHAR(9), '') AS Address7,
		REPLACE(O.Add8, CHAR(9), '') AS Address8,
		O.CTRY AS Country,
		O.ccode AS CountryID,
		O.EmailAddress AS EmailAddress,
		REPLACE(O.Telephone, CHAR(9), '') AS HomeNumber,
		REPLACE(O.WorkTel, CHAR(9), '') AS WorkNumber,
		REPLACE(O.MobilePhone, CHAR(9), '') AS MobileNumber,
		REPLACE(O.CustomerIdentifier, CHAR(9), '') AS CustomerUniqueID,
		O.sno AS VersionCode,
		O.lang AS LanguageID,
		O.gender AS GenderID,
		O.etype AS EventTypeID,
		REPLACE(CONVERT(VARCHAR(10), O.EventDate, 102), '.', '-') AS EventDate,
		O.Password AS Password,
		O.ITYPE AS IType,
		CONVERT (NVARCHAR(10), CS.[CreationDate], 121) AS SelectionDate,
		O.week AS Week,
		O.Expired AS Expired,
		CONVERT(NVARCHAR(100),
		CONVERT(VARCHAR(10), ISNULL(O.etype, '')) + '_'
		+ CASE	WHEN ISNULL(O.ITYPE, '') = '' THEN 'blank'
				ELSE O.ITYPE END + '_' 
		+ CONVERT(VARCHAR(10), ISNULL(O.ccode, '')) + '_'
		+ CASE	WHEN O.manuf = 2 THEN 'J'
				WHEN O.manuf = 3 THEN 'L'
				ELSE 'UknownManufacturer' END + '_' 
		+ CONVERT(VARCHAR(10), ISNULL(O.lang, ''))) AS CampaignID,
		O.Test AS Test,
		O.OutletPartyID AS DealerPartyID,
		O.ReportingDealerPartyID AS ReportingDealerPartyID,
		O.Dealer AS DealerName,
		O.DealerCode AS DealerCode,
		O.GDDDealerCode AS GlobalDealerCode,
		O.blank AS BusinessRegion,
		O.OwnershipCycle AS OwnershipCycle,
		REPLACE(O.EmailSignator, CHAR(10), '<br/>') AS EmailSignator,
		REPLACE(O.EmailSignatorTitle, CHAR(10), '<br/>') AS EmailSignatorTitle,
		REPLACE(O.EmailContactText, CHAR(10), '<br/>') AS EmailContactText,
		REPLACE(O.EmailCompanyDetails, CHAR(10), '<br/>') AS EmailCompanyDetails,
		REPLACE(O.JLRPrivacyPolicy, CHAR(10), '<br/>') AS JLRPrivacyPolicy,
		REPLACE(O.JLRCompanyname, CHAR(10), '<br/>') AS JLRCompanyName,
		'' AS UnknownLanguage,
		O.BilingualFlag AS BilingualFlag,
		O.langBilingual AS BilingualLanguageID,
		O.DearNameBilingual AS DearNameBilingual,
		O.EmailSignatorTitleBilingual AS EmailSignatorTitleBilingual,
		O.EmailContactTextBilingual AS EmailContactTextBilingual,
		O.EmailCompanyDetailsBilingual AS EmailCompanyDetailsBilingual,
		O.JLRPrivacyPolicyBilingual AS JLRPrivacyPolicyBilingual,
		'' AS EmployeeCode,		-- V1.26
		O.EmployeeName AS EmployeeName,		-- V1.26, -- V1.28
		'' AS CRMSalesmanCode,
		'' AS CRMSalesmanName,
		'' AS RockarDealer,
		'' AS SVOTypeID,		-- V1.4
		'' AS SVODealer,
		'' AS VistaContractOrderNumber,
		'' AS DealerNumber,
		O.FOBCode AS FOBCode,
		'' AS HotTopicCodes,
		'' AS ServiceTechnicianID,
		'' AS ServiceTechnicianName,
		'' AS ServiceAdvisorID,
		'' AS ServiceAdvisorName,
		'' AS RepairOrderNumber,
		'' AS ServiceEventType,
		'' AS Approved,
		'' AS BreakdownDate,
		'' AS BreakdownCountry,
		'' AS BreakdownCountryID,
		'' AS BreakdownCaseID,
		'' AS CarHireStartDate,
		'' AS ReasonForHire,
		'' AS HireGroupBranch,
		'' AS CarHireTicketNumber,
		'' AS HireJobNumber,
		'' AS RepairingDealer,
		'' AS DataSource,
		'' AS ReplacementVehicleMake,
		'' AS ReplacementVehicleModel,
		'' AS CarHireStartTime,
		'' AS RepairingDealerCountry,
		'' AS RoadsideAssistanceProvider,
		'' AS BreakdownAttendingResource,
		'' AS CarHireProvider,
		'' AS VehicleOriginCountry,
		'' AS CRCOwnerCode,
		'' AS CRCCode,
		'' AS CRCMarketCode,
		'' AS SampleYear,
		'' AS VehicleMileage,
		'' AS VehicleMonthsinService,
		'' AS CRCRowID,
		'' AS CRCSerialNumber,
		ISNULL(M.SelectionOutput_NSCFlag, 'N') AS NSCFlag,
		O.JLREventType AS JLREventType,
		O.DealerType AS DealerType,
		O.Queue AS Queue,
		O.Dealer10DigitCode,					-- V1.2
		O.EventID,								-- V1.3
		O.EngineType,							-- V1.11
		--L.LEAD_VEH_SALE_TYPE AS LeadVehSaleType,				-- V1.16
		CASE WHEN AIS.JLRSuppliedEventType IS NOT NULL THEN AIS.JLRSuppliedEventType
			 ELSE CASE LTRIM(RTRIM(L.LEAD_VEH_SALE_TYPE))	WHEN 'USED VEHICLE SALE' THEN '2'
															WHEN 'NEW VEHICLE SALE' THEN '1' END END AS LeadVehSaleType,				-- V1.16, V1.27
		CASE LTRIM(RTRIM(L.LEAD_ORIGIN))
			WHEN 'JLR' THEN '1'
			WHEN '3rd Party' THEN '1'
			WHEN 'Retailer' THEN '2' 
		END AS LeadOrigin,					-- V1.16
		'' AS LegalGrounds ,                -- V1.17
		'' AS AnonymityQuestion,            -- V1.17
		'' AS LandRoverExperienceID,		-- V1.23
		'' AS BusinessFlag,					-- V1.24
		'' AS CommonSaleType,				-- V1.24
		O.SubBrand							-- V1.25
	FROM SelectionOutput.OnlineOutput O
		INNER JOIN Event.EventTypes ET ON ET.EventTypeID = O.etype											-- V1.21
											AND ET.EventType IN ('LostLeads', 'PreOwned LostLeads')			-- V1.21
		--INNER JOIN Event.vwEventTypes ET ON	ET.EventTypeID = O.etype									-- V1.21
		--									AND ET.EventCategory IN ('LostLeads', 'PreOwned LostLeads')		-- V1.21
		INNER JOIN Event.Cases CS ON O.ID = CS.CaseID
		LEFT JOIN CTE_CRMInfoLostLeads CRM ON CRM.CaseID = O.ID							-- V1.12
		LEFT JOIN [$(ETLDB)].CRM.Lost_Leads L ON L.AuditItemID = CRM.AuditItemID
		LEFT JOIN Event.AdditionalInfoSales AIS ON O.EventID = AIS.EventID				-- V1.27
		LEFT JOIN dbo.Markets M ON M.CountryID = O.ccode
		--LEFT JOIN [$(ETLDB)].China.Sales_WithResponses CSR ON O.ID = CSR.CaseID 		-- V1.8						
	--WHERE ((@RussiaOutput = 1 AND ISNULL(O.CTRY,'') = 'Russian Federation') OR  (@RussiaOutput = 0 AND ISNULL(O.CTRY,'') <> 'Russian Federation'))	-- V1.20
		--AND CSR.CaseID IS NULL														-- V1.8
	----------------------------------------------------------


	----------------------------------------------------------
	-- Bodyshop Output
	INSERT INTO SelectionOutput.CombinedOnlineOutput
	SELECT O.ID AS ID,
		O.etype AS SurveyTypeID,
		O.modelcode AS ModelCode,
		O.FullModel AS ModelDescription,
		CASE WHEN O.ModelYear = 0 THEN ''
			ELSE CAST(O.ModelYear AS VARCHAR) END AS ModelYear,				-- V1.27
		O.manuf AS ManufacturerID,
		O.sType AS Manufacturer,
		REPLACE(O.CarReg, CHAR(9), '') AS CarRegistration,
		REPLACE(O.VIN, CHAR(9), '') AS VIN,
		O.VariantID AS ModelVariantCode,
		O.ModelVariant AS ModelVariantDescription,
		O.PartyID AS PartyID,
		REPLACE(O.Title, CHAR(9), '') AS Title,
		REPLACE(O.Initial, CHAR(9), '') AS Initial,
		REPLACE(O.Surname, CHAR(9), '') AS LastName,
		REPLACE(O.Fullname, CHAR(9), '') AS FullName,
		REPLACE(O.DearName, CHAR(9), '') AS DearName,
		REPLACE(O.CoName, CHAR(9), '') AS CompanyName,
		REPLACE(O.Add1, CHAR(9), '') AS Address1,
		REPLACE(O.Add2, CHAR(9), '') AS Address2,
		REPLACE(O.Add3, CHAR(9), '') AS Address3,
		REPLACE(O.Add4, CHAR(9), '') AS Address4,
		REPLACE(O.Add5, CHAR(9), '') AS Address5,
		REPLACE(O.Add6, CHAR(9), '') AS Address6,
		REPLACE(O.Add7, CHAR(9), '') AS Address7,
		REPLACE(O.Add8, CHAR(9), '') AS Address8,
		O.CTRY AS Country,
		O.ccode AS CountryID,
		O.EmailAddress AS EmailAddress,
		REPLACE(O.Telephone, CHAR(9), '') AS HomeNumber,
		REPLACE(O.WorkTel, CHAR(9), '') AS WorkNumber,
		REPLACE(O.MobilePhone, CHAR(9), '') AS MobileNumber,
		REPLACE(O.CustomerIdentifier, CHAR(9), '') AS CustomerUniqueID,
		O.sno AS VersionCode,
		O.lang AS LanguageID,
		O.gender AS GenderID,
		O.etype AS EventTypeID,
		REPLACE(CONVERT(VARCHAR(10), O.EventDate, 102), '.', '-') AS EventDate,
		O.Password AS Password,
		O.ITYPE AS IType,
		CASE	WHEN O.Itype ='T' THEN  CONVERT(NVARCHAR(10), @dtCATI, 121)
				ELSE CONVERT(NVARCHAR(10), @NOW, 121) END AS SelectionDate,
		O.week AS Week,
		O.Expired AS Expired,
		CONVERT(NVARCHAR(100),
		CONVERT(VARCHAR(10), ISNULL(O.etype, '')) + '_'
		+ CASE	WHEN ISNULL(O.ITYPE, '') = '' THEN 'blank'
				ELSE O.ITYPE END + '_' 
		+ CONVERT(VARCHAR(10), ISNULL(O.ccode, '')) + '_'
		+ CASE	WHEN O.manuf = 2 THEN 'J'
				WHEN O.manuf = 3 THEN 'L'
				ELSE 'UknownManufacturer' END + '_' 
		+ CONVERT(VARCHAR(10), ISNULL(O.lang, ''))) AS CampaignID,
		O.Test AS Test,
		O.OutletPartyID AS DealerPartyID,
		O.ReportingDealerPartyID AS ReportingDealerPartyID,
		O.Dealer AS DealerName,
		O.DealerCode AS DealerCode,
		O.GDDDealerCode AS GlobalDealerCode,
		O.blank AS BusinessRegion,
		O.OwnershipCycle AS OwnershipCycle,
		REPLACE(O.EmailSignator, CHAR(10), '<br/>') AS EmailSignator,
		REPLACE(O.EmailSignatorTitle, CHAR(10), '<br/>') AS EmailSignatorTitle,
		REPLACE(O.EmailContactText, CHAR(10), '<br/>') AS EmailContactText,
		REPLACE(O.EmailCompanyDetails, CHAR(10), '<br/>') AS EmailCompanyDetails,
		REPLACE(O.JLRPrivacyPolicy, CHAR(10), '<br/>') AS JLRPrivacyPolicy,
		REPLACE(O.JLRCompanyname, CHAR(10), '<br/>') AS JLRCompanyName,
		'' AS UnknownLanguage,
		O.BilingualFlag AS BilingualFlag,
		O.langBilingual AS BilingualLanguageID,
		O.DearNameBilingual AS DearNameBilingual,
		O.EmailSignatorTitleBilingual AS EmailSignatorTitleBilingual,
		O.EmailContactTextBilingual AS EmailContactTextBilingual,
		O.EmailCompanyDetailsBilingual AS EmailCompanyDetailsBilingual,
		O.JLRPrivacyPolicyBilingual AS JLRPrivacyPolicyBilingual,
		O.EmployeeCode AS EmployeeCode,
		O.EmployeeName AS EmployeeName,
		'' AS CRMSalesmanCode,
		'' AS CRMSalesmanName,
		'' AS RockarDealer,
		ISNULL(O.SVOvehicle, '') AS SVOTypeID,	-- V1.13
		'' AS SVODealer,
		'' AS VistaContractOrderNumber,
		'' AS DealerNumber,
		'' AS FOBCode,
		'' AS HotTopicCodes,
		'' AS ServiceTechnicianID,
		'' AS ServiceTechnicianName,
		'' AS ServiceAdvisorID,
		'' AS ServiceAdvisorName,
		'' AS RepairOrderNumber,
		'' AS ServiceEventType,
		'' AS Approved,
		'' AS BreakdownDate,
		'' AS BreakdownCountry,
		'' AS BreakdownCountryID,
		'' AS BreakdownCaseID,
		'' AS CarHireStartDate,
		'' AS ReasonForHire,
		'' AS HireGroupBranch,
		'' AS CarHireTicketNumber,
		'' AS HireJobNumber,
		'' AS RepairingDealer,
		'' AS DataSource,
		'' AS ReplacementVehicleMake,
		'' AS ReplacementVehicleModel,
		'' AS CarHireStartTime,
		'' AS RepairingDealerCountry,
		'' AS RoadsideAssistanceProvider,
		'' AS BreakdownAttendingResource,
		'' AS CarHireProvider,
		'' AS VehicleOriginCountry,
		'' AS CRCOwnerCode,
		'' AS CRCCode,
		'' AS CRCMarketCode,
		'' AS SampleYear,
		'' AS VehicleMileage,
		'' AS VehicleMonthsinService,
		'' AS CRCRowID,
		'' AS CRCSerialNumber,
		'' AS NSCFlag,
		'' AS JLREventType,
		'' AS DealerType,
		'' AS Queue,
		O.Dealer10DigitCode,				-- V1.2
		O.EventID,							-- V1.3
		O.EngineType,						-- V1.11
		'' AS LeadVehSaleType,				-- V1.16
		'' AS LeadOrigin,					-- V1.16
		'' AS LegalGrounds ,                -- V1.17
		'' AS AnonymityQuestion,            -- V1.17
		'' AS LandRoverExperienceID,		-- V1.23
		'' AS BusinessFlag,					-- V1.24
		'' AS CommonSaleType,				-- V1.24
		O.SubBrand							-- V1.25
	FROM SelectionOutput.OnlineOutput O
		INNER JOIN Event.vwEventTypes ET ON ET.EventTypeID = O.etype 
											AND	ET.EventCategory = 'Bodyshop'
	--WHERE ((@RussiaOutput = 1 AND ISNULL(O.CTRY,'') = 'Russian Federation') OR  (@RussiaOutput = 0 AND ISNULL(O.CTRY,'') <> 'Russian Federation'))	-- V1.20
	----------------------------------------------------------

	-- Land Rover Experience Output
	;WITH CTE_CRMInfoExperience (CaseID, AuditItemID) AS 
	(
		SELECT SL.CaseID, 
			MAX(SL.AuditItemID) AS AuditItemID
		FROM SelectionOutput.OnlineOutput O
			INNER JOIN Event.vwEventTypes ET ON	ET.EventTypeID = O.etype 
												AND	ET.EventCategory = 'Land Rover Experience'
			INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL ON SL.CaseID = O.ID
			INNER JOIN [$(ETLDB)].CRM.LandRover_Experience VCS ON SL.AuditItemID = VCS.AudititemID
		GROUP BY SL.CaseID
	)
	INSERT INTO SelectionOutput.CombinedOnlineOutput
    SELECT O.ID AS ID,
		O.etype AS SurveyTypeID,
		O.modelcode AS ModelCode,
		O.FullModel AS ModelDescription,
		CASE WHEN O.ModelYear = 0 THEN ''
			ELSE CAST(O.ModelYear AS VARCHAR) END AS ModelYear,				-- V1.27
		O.manuf AS ManufacturerID,
		O.sType AS Manufacturer,
		REPLACE(O.CarReg, CHAR(9), '') AS CarRegistration,
		REPLACE(O.VIN, CHAR(9), '') AS VIN,
		O.VariantID AS ModelVariantCode,
		O.ModelVariant AS ModelVariantDescription,
		O.PartyID AS PartyID,
		REPLACE(O.Title, CHAR(9), '') AS Title,
		REPLACE(O.Initial, CHAR(9), '') AS Initial,
		REPLACE(O.Surname, CHAR(9), '') AS LastName,
		REPLACE(O.Fullname, CHAR(9), '') AS FullName,
		REPLACE(O.DearName, CHAR(9), '') AS DearName,
		REPLACE(O.CoName, CHAR(9), '') AS CompanyName,
		REPLACE(O.Add1, CHAR(9), '') AS Address1,
		REPLACE(O.Add2, CHAR(9), '') AS Address2,
		REPLACE(O.Add3, CHAR(9), '') AS Address3,
		REPLACE(O.Add4, CHAR(9), '') AS Address4,
		REPLACE(O.Add5, CHAR(9), '') AS Address5,
		REPLACE(O.Add6, CHAR(9), '') AS Address6,
		REPLACE(O.Add7, CHAR(9), '') AS Address7,
		REPLACE(O.Add8, CHAR(9), '') AS Address8,
		O.CTRY AS Country,
		O.ccode AS CountryID,
		O.EmailAddress AS EmailAddress,
		REPLACE(O.Telephone, CHAR(9), '') AS HomeNumber,
		REPLACE(O.WorkTel, CHAR(9), '') AS WorkNumber,
		REPLACE(O.MobilePhone, CHAR(9), '') AS MobileNumber,
		REPLACE(O.CustomerIdentifier, CHAR(9), '') AS CustomerUniqueID,
		O.sno AS VersionCode,
		O.lang AS LanguageID,
		O.gender AS GenderID,
		O.etype AS EventTypeID,
		REPLACE(CONVERT(VARCHAR(10), O.EventDate, 102), '.', '-') AS EventDate,
		O.Password AS Password,
		O.ITYPE AS IType,
		CASE	WHEN O.Itype ='T' THEN CONVERT(NVARCHAR(10), @dtCATI, 121)
				ELSE CONVERT(NVARCHAR(10), @NOW, 121) END AS SelectionDate,
		O.week AS Week,
		O.Expired AS Expired,
		CONVERT(NVARCHAR(100),
			CONVERT(VARCHAR(10), ISNULL(O.etype, '')) + '_'
			+ CASE	WHEN ISNULL(O.ITYPE, '') = '' THEN 'blank'
					ELSE O.ITYPE END + '_' 
			+ CONVERT(VARCHAR(10), ISNULL(O.ccode, '')) + '_'
			+ CASE	WHEN O.manuf = 2 THEN 'J'
					WHEN O.manuf = 3 THEN 'L'
					ELSE 'UknownManufacturer' END + '_' 
			+ CONVERT(VARCHAR(10), ISNULL(O.lang, ''))) AS CampaignID,
		O.test AS Test,
		O.OutletPartyID AS DealerPartyID,
		O.ReportingDealerPartyID AS ReportingDealerPartyID,
		O.Dealer AS DealerName,
		O.DealerCode AS DealerCode,
		O.GDDDealerCode AS GlobalDealerCode,
		O.blank AS BusinessRegion,
		O.OwnershipCycle AS OwnershipCycle,
		REPLACE(O.EmailSignator, CHAR(10), '<br/>') AS EmailSignator,
		REPLACE(O.EmailSignatorTitle, CHAR(10), '<br/>') AS EmailSignatorTitle,
		REPLACE(O.EmailContactText, CHAR(10), '<br/>') AS EmailContactText,
		REPLACE(O.EmailCompanyDetails, CHAR(10), '<br/>') AS EmailCompanyDetails,
		REPLACE(O.JLRPrivacyPolicy, CHAR(10), '<br/>') AS JLRPrivacyPolicy,
		REPLACE(O.JLRCompanyname, CHAR(10), '<br/>') AS JLRCompanyName,
		O.UnknownLang AS UnknownLanguage,
		O.BilingualFlag AS BilingualFlag,
		O.langBilingual AS BilingualLanguageID,
		O.DearNameBilingual AS DearNameBilingual,
		O.EmailSignatorTitleBilingual AS EmailSignatorTitleBilingual,
		O.EmailContactTextBilingual AS EmailContactTextBilingual,
		O.EmailCompanyDetailsBilingual AS EmailCompanyDetailsBilingual,
		O.JLRPrivacyPolicyBilingual AS JLRPrivacyPolicyBilingual,
		'' AS EmployeeCode,
		'' AS EmployeeName,																						-- V1.18
		'' AS CRMSalesmanCode,
		'' AS CRMSalesmanName,																																					-- V1.18
		ISNULL(O.RockarDealer, 0) AS RockarDealer,
		ISNULL(O.SVOvehicle, '') AS SVOTypeID,					-- V1.4
		ISNULL(O.SVODealer, '') AS SVODealer,					-- V1.4
		O.VistaContractOrderNumber AS VistaContractOrderNumber,
		O.DealNo AS DealerNumber,
		O.FOBCode AS FOBCode,
		O.HotTopicCodes AS HotTopicCodes,
		'' AS ServiceTechnicianID,
		'' AS ServiceTechnicianName,
		'' AS ServiceAdvisorID,
		'' AS ServiceAdvisorName,
		'' AS RepairOrderNumber,
		'' AS ServiceEventType,
		'' AS Approved,
		'' AS BreakdownDate,
		'' AS BreakdownCountry,
		'' AS BreakdownCountryID,
		'' AS BreakdownCaseID,
		'' AS CarHireStartDate,
		'' AS ReasonForHire,
		'' AS HireGroupBranch,
		'' AS CarHireTicketNumber,
		'' AS HireJobNumber,
		'' AS RepairingDealer,
		'' AS DataSource,
		'' AS ReplacementVehicleMake,
		'' AS ReplacementVehicleModel,
		'' AS CarHireStartTime,
		'' AS RepairingDealerCountry,
		'' AS RoadsideAssistanceProvider,
		'' AS BreakdownAttendingResource,
		'' AS CarHireProvider,
		'' AS VehicleOriginCountry,
		'' AS CRCOwnerCode,
		'' AS CRCCode,
		'' AS CRCMarketCode,
		'' AS SampleYear,
		'' AS VehicleMileage,
		'' AS VehicleMonthsinService,
		'' AS CRCRowID,
		'' AS CRCSerialNumber,
		'' AS NSCFlag,
		'' AS JLREventType,
		'' AS DealerType,
		'' AS Queue,
		O.Dealer10DigitCode,
		O.EventID,
		O.EngineType,
		'' AS LeadVehSaleType,
		'' AS LeadOrigin,
		'' AS LegalGrounds,
		'' AS AnonymityQuestion,
		O.LandRoverExperienceID,
		'' AS BusinessFlag,					-- V1.24
		'' AS CommonSaleType,				-- V1.24
		O.SubBrand							-- V1.25
    FROM SelectionOutput.OnlineOutput O
		INNER JOIN Event.vwEventTypes ET ON	ET.EventTypeID = O.etype 
											AND ET.EventCategory = 'Land Rover Experience' 
		INNER JOIN Event.EventTypes ET1 ON ET1.EventTypeID = O.etype										-- V1.18
		LEFT JOIN dbo.DW_JLRCSPDealers D ON O.OutletPartyID = D.OutletPartyID								-- V1.18
											AND ET1.RelatedOutletFunctionID = D.OutletFunctionID			-- V1.18
		LEFT JOIN CTE_CRMInfoExperience CRM ON CRM.CaseID = O.ID
		LEFT JOIN [$(ETLDB)].CRM.LandRover_Experience VCS ON VCS.AuditItemID = CRM.AuditItemID

	----------------------------------------------------------


	----------------------------------------------------------
	-- V1.6 Exclude employee data for certain markets
	UPDATE OO
	SET OO.EmployeeCode = '',
		OO.EmployeeName = '',
		OO.CRMSalesmanCode = '',
		OO.CRMSalesmanName = '',
		OO.ServiceAdvisorID = '',
		OO.ServiceAdvisorName = '',
		OO.ServiceTechnicianID = '',
		OO.ServiceTechnicianName = ''
	FROM SelectionOutput.CombinedOnlineOutput OO
		INNER JOIN dbo.Markets M ON OO.CountryID = M.CountryID
	WHERE M.ExcludeEmployeeData = 1
	----------------------------------------------------------


	----------------------------------------------------------
	-- V1.17
	UPDATE OO
	SET OO.LegalGrounds = M.LegalGrounds,
		OO.AnonymityQuestion = M.AnonymityQuestion
	FROM SelectionOutput.CombinedOnlineOutput OO
		INNER JOIN dbo.Markets M ON OO.CountryID = M.CountryID
	----------------------------------------------------------