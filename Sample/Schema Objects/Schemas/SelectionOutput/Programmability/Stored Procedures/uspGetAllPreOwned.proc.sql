CREATE PROCEDURE SelectionOutput.uspGetAllPreOwned
	@RussiaOutput INTEGER = 0		-- V1.9	
AS 
/*

	Description: Gets All Pre-Owned. Called by: Selection Output.dtsx (Output All PreOwned - Data Flow Task)	

	Version		Created			Author			History		
	-------		-------			------			-------			
	1.0			03-02-2016		Chris Ross		Original version.  BUG 12038.  
	1.1			26-01-2017		Eddie Thomas	BUG 13507 North America - selection output filename
	1.2			06-04-2017		Eddie Thomas	BUG 13703 - CATI - Expiration/Selection date changes
	1.3			04-07-2017		Eddie Thomas	BUG 14035 - Add fields SVOvehicle & FOB
	1.4			08-09-2017		Chris Ledger	BUG 14217 - Make DISTINCT to avoid duplication from multiple VehicleIDs for same VIN	DEPLOYED LIVE: CL 2017-09-08
	1.5			25-10-2017		Chris Ledger	BUG 14245 - Add Bilingual Fields
	1.6			09-02-2018		Eddie Thomas	BUG 14362 Online files – Re-output records to be output once a week / reverse NA Pilot changes
	1.7			01-06-2018		Eddie Thomas	BUG 14763 - Adding JLR PP field
	1.8			26-03-2019		Chris Ross		BUG 15310 - Add in HotTopicCodes column
	1.9			12-09-2019		Chris Ledger	BUG 15571 - Separate Russia Output
	1.10		27-05-2021		Chris Ledger	Remove China.Sales_WithResponses
	1.11		02-07-2021		Chris Ledger	TASK 535: Add EventID
	1.12		20-07-2021		Chris Ledger	TASK 558: Add EngineType
	1.13		19-10-2021		Chris Ledger	TASK 664 - Add PAGCode to EmployeeName & CRMEmployeeName fields

*/
	SET NOCOUNT ON				-- V1.1 
    DECLARE @NOW	DATETIME,	
			@dtCATI	DATETIME	-- V1.2
    
    SET	@NOW = GETDATE()
	SET	@dtCATI	= DATEADD(week, DATEDIFF(day, 0, @NOW)/7, 4) -- V1.2


	;WITH CTE_CRMInfoPreOwned (CaseID, AuditItemID) AS										-- V1.13
	(
		SELECT SL.CaseID, 
			MAX(SL.AuditItemID) AS AuditItemID
		FROM SelectionOutput.OnlineOutput O
			INNER JOIN Event.vwEventTypes ET ON	ET.EventTypeID = O.etype 
												AND	ET.EventCategory = 'PreOwned'
			INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL ON SL.CaseID = O.ID
			INNER JOIN [$(ETLDB)].CRM.PreOwned P ON SL.AuditItemID = P.AuditItemID
			--LEFT JOIN [$(ETLDB)].China.Service_WithResponses CSR ON O.ID = CSR.CaseID 	-- V1.10								
		--WHERE CSR.CaseID IS NULL															-- V1.10
		GROUP BY SL.CaseID
	)
	SELECT DISTINCT			-- V1.4
		O.Password,
        O.ID,
        O.FullModel,
        O.Model,
        O.sType,
        REPLACE(O.CarReg, CHAR(9), '') AS CarReg,
        REPLACE(O.Title, CHAR(9), '') AS Title,
        REPLACE(O.Initial, CHAR(9), '') AS Initial,
        REPLACE(O.Surname, CHAR(9), '') AS Surname,
        REPLACE(O.Fullname, CHAR(9), '') AS Fullname,
        REPLACE(O.DearName, CHAR(9), '') AS DearName,
        REPLACE(O.CoName, CHAR(9), '') AS CoName,
        REPLACE(O.Add1, CHAR(9), '') AS Add1,
        REPLACE(O.Add2, CHAR(9), '') AS Add2,
        REPLACE(O.Add3, CHAR(9), '') AS Add3,
        REPLACE(O.Add4, CHAR(9), '') AS Add4,
        REPLACE(O.Add5, CHAR(9), '') AS Add5,
        REPLACE(O.Add6, CHAR(9), '') AS Add6,
        REPLACE(O.Add7, CHAR(9), '') AS Add7,
        REPLACE(O.Add8, CHAR(9), '') AS Add8,
        REPLACE(O.Add9, CHAR(9), '') AS Add9,
        O.CTRY,
        REPLACE(O.EmailAddress, CHAR(9), '') AS EmailAddress,
        O.Dealer,
        O.sno,
        O.ccode,
        O.modelcode,
        O.lang,
        O.manuf,
        O.gender,
        O.qver,
        O.blank,
        O.etype,
        O.reminder,
        O.week,
        O.test,
        O.SampleFlag,
        O.SalesServiceFile,
        O.ITYPE,
        O.Expired,
        REPLACE(O.VIN, CHAR(9), '') AS VIN,
        REPLACE(CONVERT(VARCHAR(10), O.EventDate, 102), '.', '-') AS EventDate,
        O.DealerCode,
        REPLACE(O.Telephone, CHAR(9), '') AS Telephone,
        REPLACE(O.WorkTel, CHAR(9), '') AS WorkTel,
        REPLACE(O.MobilePhone, CHAR(9), '') AS MobilePhone,
        O.ManufacturerDealerCode,
        O.ModelYear,
        REPLACE(O.CustomerIdentifier, CHAR(9), '') AS CustomerIdentifier,
        O.OwnershipCycle,
        O.OutletPartyID,
        O.PartyID,
        O.GDDDealerCode,
        O.ReportingDealerPartyID,
        O.VariantID,
        O.ModelVariant,
        CASE	WHEN O.Itype ='T' THEN  CONVERT(NVARCHAR(10), @dtCATI, 121)		-- V1.2
				ELSE CONVERT(NVARCHAR(10), @NOW, 121) END AS SelectionDate,		-- V1.2
		CONVERT(NVARCHAR(100), CONVERT(VARCHAR(10), ISNULL(O.etype, '')) + '_'
			+ CASE	WHEN ISNULL(O.ITYPE, '') = '' THEN 'blank'
					ELSE O.ITYPE END + '_' 
			+ CONVERT(VARCHAR(10), ISNULL(O.ccode, '')) + '_'
			+ CASE	WHEN O.manuf = 2 THEN 'J'
					WHEN O.manuf = 3 THEN 'L'
					ELSE 'UknownManufacturer' END + '_' 
			+ CONVERT(VARCHAR(10), ISNULL(O.lang, ''))) AS CampaignId,
        REPLACE(O.EmailSignator, CHAR(10), '<br/>') AS EmailSignator	,			
		REPLACE(O.EmailSignatorTitle, CHAR(10), '<br/>') AS EmailSignatorTitle,	
		REPLACE(O.EmailContactText, CHAR(10), '<br/>') AS EmailContactText,	
		REPLACE(O.EmailCompanyDetails, CHAR(10), '<br/>') AS EmailCompanyDetails,
		REPLACE(O.JLRCompanyname, CHAR(10), '<br/>') AS JLRCompanyname,
		REPLACE(O.JLRPrivacyPolicy, CHAR(10), '<br/>') AS JLRPrivacyPolicy,			-- V1.7
		CASE	WHEN P.AudititemID IS NULL THEN O.EmployeeCode																		-- V1.13
				ELSE '' END AS EmployeeCode,																						-- V1.13
		CASE	WHEN P.AudititemID IS NULL THEN CASE	WHEN D.PAGCode IS NULL THEN O.EmployeeName									-- V1.13
														WHEN LEN(O.EmployeeName) > 0 THEN O.EmployeeName + ' (' + D.PAGCode + ')'	-- V1.13
														ELSE '' END																	-- V1.13
				ELSE '' END AS EmployeeName,																						-- V1.13
		CASE	WHEN D.PAGCode IS NULL THEN ISNULL(COALESCE(P.VISTACONTRACT_SALES_MAN_FULNAM, O.SalesAdvisorName), '')																				-- V1.13
				WHEN LEN(ISNULL(COALESCE(P.VISTACONTRACT_SALES_MAN_FULNAM, O.SalesAdvisorName), ''))>0 THEN COALESCE(P.VISTACONTRACT_SALES_MAN_FULNAM, O.SalesAdvisorName) + ' (' + D.PAGCode + ')'	-- V1.13
				ELSE '' END AS CRMSalesmanName,																																						-- V1.13
		ISNULL(COALESCE(P.VISTACONTRACT_SALESMAN_CODE, O.SalesAdvisorID), '') AS CRMSalesmanCode,			-- V1.13
		O.ModelSummary,
		AIS.Approved,
		ISNULL(VEH.SVOTypeID,0) AS SVOvehicle,										-- V1.3
		VEH.FOBCode,																-- V1.3
		O.BilingualFlag,					-- V1.5
		O.langBilingual,					-- V1.5
		O.DearNameBilingual,				-- V1.5
		O.EmailSignatorTitleBilingual,		-- V1.5
		O.EmailContactTextBilingual,		-- V1.5
		O.EmailCompanyDetailsBilingual,		-- V1.5
		O.JLRPrivacyPolicyBilingual,		-- V1.7
		O.HotTopicCodes,					-- V1.9
		O.EventID,							-- V1.11
		O.EngineType						-- V1.12
    FROM SelectionOutput.OnlineOutput O
		INNER JOIN Event.vwEventTypes ET ON	ET.EventTypeID = O.etype 
											AND ET.EventCategory = 'PreOwned' 
		INNER JOIN Event.EventTypes ET1 ON ET1.EventTypeID = O.etype										-- V1.13
		LEFT JOIN dbo.DW_JLRCSPDealers D ON O.OutletPartyID = D.OutletPartyID								-- V1.13
											AND ET1.RelatedOutletFunctionID = D.OutletFunctionID			-- V1.13
		INNER JOIN Event.AutomotiveEventBasedInterviews AEBI ON O.ID = AEBI.CaseID
		INNER JOIN Event.AdditionalInfoSales AIS ON AIS.EventID = AEBI.EventID
		INNER JOIN Vehicle.Vehicles VEH ON O.VIN = VEH.VIN								-- V1.3
		LEFT JOIN CTE_CRMInfoPreOwned CRM ON CRM.CaseID = O.ID							-- V1.13
		LEFT JOIN [$(ETLDB)].CRM.PreOwned P ON P.AuditItemID = CRM.AuditItemID			-- V1.13
		--LEFT JOIN [$(ETLDB)].China.Sales_WithResponses CSR ON O.ID = CSR.CaseID		-- V1.10										
	WHERE ((@RussiaOutput = 1 AND ISNULL(O.CTRY,'') = 'Russian Federation') OR (@RussiaOutput = 0 AND ISNULL(O.CTRY,'') <> 'Russian Federation'))	-- V1.9
		--AND CSR.CaseID IS NULL														-- V1.10