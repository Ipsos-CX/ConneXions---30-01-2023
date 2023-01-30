CREATE PROCEDURE SelectionOutput.uspGetAllSales
	@RussiaOutput INTEGER = 0		-- V1.16
AS 

/*

Version		Created			Author		History		
-------		-------			------		-------			
1.0			13-Feb-2015		P.Doyle		Gets All Sales.  Called by: Selection Output.dtsx (Output All Sales - Data Flow Task)	
1.1			09-Mar-2015		C.Ross		BUG 11329 - Add in new Online Email Output Column and Remove Tabs from text columns
1.2			17-07-2015		E.Thomas	BUG 11675 - Filter out CaseIds associated to China sample supplied with responses
1.3			18-04-2016		C.Ross		BUG 12407 - Add in PilotCode for output.
1.4			17-11-2016		C.Ross		BUG 13313 - Add in lookup and output of VISTACONTRACT_SALES_MAN_FULNAM and VISTACONTRACT_SALESMAN_CODE
1.5			26-01-2017		E. Thomas	BUG 13507 North America - selection output filename
1.5a		31-01-2017		C.Ross		Added JLRCompanyname back in.
1.6			31-01-2017		C.Ross		BUG 13510 - Add in SalesAdvisorID and SalesAdvisor columns.
1.7			08-02-2017		E.thomas	BUG 13525 - Rockar questionnaire flagging
1.8			16-02-2017		E.thomas	BUG 13466 - Flagging SVO Vehicles	
1.9			17-03-2017		C.Ledger	BUG 13670 - Add VistaContractOrderNumber and DealNo
1.10		27-03-2017		C.Ledger	BUG 13670 - Add FOBCode and UnknownLang
1.11		30-03-2017		C.Ledger	BUG 13970 - Map FOBCode and UnknownLang 
1.12		06-04-2017		E.Thomas	BUG 13703 - CATI - Expiration/Selection date changes
1.13		25-10-2017		C.Ledger	BUG 14245 - Add Bilingual Fields
1.14		09-02-2018		E.Thomas	BUG 14362 - Online files – Re-output records to be output once a week / reverse NA Pilot changes
1.15		01-06-2018		E.Thomas	BUG 14763 - Adding JLR PP fields
1.16		19-11-2018		C.Ross		BUG 15079 - Add in HotTopicCodes column
1.17		12-09-2019		C.Ledger	BUG 15571 - Separate Russia Output
1.18		27-05-2021		C.Ledger	Remove China.Sales_WithResponses
1.19		02-07-2021		C.Ledger	TASK 535 - Add EventID
1.20		20-07-2021		C.Ledger	TASK 558 - Add EngineType
1.21		19-10-2021		C.Ledger	TASK 664 - Add PAGCode to EmployeeName & CRMEmployeeName fields

*/

	SET NOCOUNT ON	--V1.5
    DECLARE @NOW	DATETIME,	
			@dtCATI	DATETIME	-- V1.12
    
    SET	@NOW = GETDATE()
	SET	@dtCATI	= DATEADD(week, DATEDIFF(day, 0, @NOW)/7, 4)			-- V1.12
	
	;WITH CTE_CRMInfo													-- V1.4
	AS (
		SELECT SL.CaseID, 
			MAX(SL.AuditItemID) AS AuditItemID
		FROM SelectionOutput.OnlineOutput O
			INNER JOIN Event.vwEventTypes ET ON	ET.EventTypeID = O.etype 
												AND	ET.EventCategory = 'Sales'
			INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL ON SL.CaseID = O.ID
			INNER JOIN [$(ETLDB)].CRM.Vista_Contract_Sales VCS ON SL.AudititemID = VCS.AudititemID
			--LEFT JOIN [$(ETLDB)].China.Sales_WithResponses CSR ON O.ID = CSR.CaseID				-- V1.18 										
		--WHERE CSR.CaseID IS NULL																	-- V1.18
		GROUP BY SL.CaseID
	)
    SELECT  O.Password,
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
        CASE	WHEN O.Itype ='T' THEN CONVERT(NVARCHAR(10), @dtCATI, 121)									-- V1.12
				ELSE CONVERT(NVARCHAR(10), @NOW, 121) END AS SelectionDate,									-- V1.12
		CONVERT(NVARCHAR(100), CONVERT(VARCHAR(10), ISNULL(O.etype, '')) + '_'
			+ CASE	WHEN ISNULL(O.ITYPE, '') = '' THEN 'blank'
					ELSE O.ITYPE END + '_' 
			+ CONVERT(VARCHAR(10), ISNULL(O.ccode, '')) + '_'
			+ CASE	WHEN O.manuf = 2 THEN 'J'
					WHEN O.manuf = 3 THEN 'L'
					ELSE 'UknownManufacturer' END + '_' 
			+ CONVERT(VARCHAR(10), ISNULL(O.lang, ''))) AS CampaignId,
        REPLACE(O.EmailSignator, CHAR(10), '<br/>') AS EmailSignator,										-- V1.1
		REPLACE(O.EmailSignatorTitle, CHAR(10), '<br/>') AS EmailSignatorTitle,	
		REPLACE(O.EmailContactText, CHAR(10), '<br/>') AS EmailContactText,	
		REPLACE(O.EmailCompanyDetails, CHAR(10), '<br/>') AS EmailCompanyDetails,
		REPLACE(O.JLRCompanyname, CHAR(10), '<br/>') AS JLRCompanyname,
		REPLACE(O.JLRPrivacyPolicy, CHAR(10), '<br/>') AS JLRPrivacyPolicy,									-- V1.15
		CASE	WHEN VCS.AudititemID IS NULL THEN O.EmployeeCode 
				ELSE '' END AS EmployeeCode,
		CASE	WHEN VCS.AudititemID IS NULL THEN CASE	WHEN D.PAGCode IS NULL THEN O.EmployeeName									-- V1.21
														WHEN LEN(O.EmployeeName) > 0 THEN O.EmployeeName + ' (' + D.PAGCode + ')'	-- V1.21
														ELSE '' END																	-- V1.21
				ELSE '' END AS EmployeeName,																						-- V1.21
		O.PilotCode,																						-- V1.3
		CASE	WHEN D.PAGCode IS NULL THEN ISNULL(COALESCE(VCS.VISTACONTRACT_SALES_MAN_FULNAM, O.SalesAdvisorName), '')																			-- V1.21
				WHEN LEN(ISNULL(COALESCE(VCS.VISTACONTRACT_SALES_MAN_FULNAM, O.SalesAdvisorName), ''))>0 THEN COALESCE(VCS.VISTACONTRACT_SALES_MAN_FULNAM, O.SalesAdvisorName) + ' (' + D.PAGCode + ')'	-- V1.21
				ELSE '' END AS CRMSalesmanName,																																						-- V1.21
		ISNULL(COALESCE(VCS.VISTACONTRACT_SALESMAN_CODE, O.SalesAdvisorID), '') AS CRMSalesmanCode,			-- V1.4	-- V1.6
		ISNULL(O.RockarDealer,0) AS RockarDealer,															-- V1.7
		ISNULL(O.SVOvehicle,0) As SVOvehicle,																-- V1.8
		ISNULL(O.SVODealer,0) AS SVODealer,																	-- V1.8	
		O.VistaContractOrderNumber,																			-- V1.9	
		O.DealNo,																							-- V1.9
		O.FOBCode,																							-- V1.11
		O.UnknownLang,																						-- V1.11
		O.BilingualFlag,					-- V1.13
		O.langBilingual,					-- V1.13
		O.DearNameBilingual,				-- V1.13
		O.EmailSignatorTitleBilingual,		-- V1.13
		O.EmailContactTextBilingual,		-- V1.13
		O.EmailCompanyDetailsBilingual,		-- V1.13
		O.JLRPrivacyPolicyBilingual,		-- V1.15	  
   		O.HotTopicCodes,					-- V1.16
		O.EventID,							-- V1.19
		O.EngineType						-- V1.20
    FROM SelectionOutput.OnlineOutput O
        INNER JOIN Event.vwEventTypes ET ON	ET.EventTypeID = O.etype
											AND ET.EventCategory = 'Sales' 
		INNER JOIN Event.EventTypes ET1 ON ET1.EventTypeID = O.etype										-- V1.21
		LEFT JOIN dbo.DW_JLRCSPDealers D ON O.OutletPartyID = D.OutletPartyID								-- V1.21
											AND ET1.RelatedOutletFunctionID = D.OutletFunctionID			-- V1.21
		LEFT JOIN CTE_CRMInfo CRM ON CRM.CaseID = O.ID
		LEFT JOIN [$(ETLDB)].CRM.Vista_Contract_Sales VCS ON VCS.AudititemID = CRM.AudititemID
		--LEFT JOIN [$(ETLDB)].China.Sales_WithResponses CSR ON O.ID = CSR.CaseID 							-- V1.18								
	WHERE ((@RussiaOutput = 1 AND ISNULL(O.CTRY,'') = 'Russian Federation') OR (@RussiaOutput = 0 AND ISNULL(O.CTRY,'') <> 'Russian Federation'))	-- V1.17
		--AND CSR.CaseID IS NULL																			-- V1.18