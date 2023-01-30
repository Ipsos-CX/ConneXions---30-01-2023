CREATE PROCEDURE SelectionOutput.uspGetAllService
	@RussiaOutput INTEGER = 0		-- V1.17	
AS 

/*

	Version		Created			Author		History		
	-------		-------			------		-------			
	1.0			13-Feb-2015		P.Doyle		Gets All Service  Called by: Selection Output.dtsx (Output All Service - Data Flow Task)	
	1.1			09-Mar-2015		C.Ross		BUG 11329 - Add in new Online Email Output Columns and Remove Tabs from text columns
	1.2			17-07-2015		E.Thomas	BUG 11675 - Filter out CaseIds associated to China sample supplied with responses
	1.3			18-04-2016		C.Ross		BUG 12407 - Add in PilotCode for output.
	1.4			15-11-2016		C.Ross		BUG 13313 - Add in lookup and output of DMS_SERVICE_ADVISOR, DMS_SERVICE_ADVISOR_ID, DMS_TECHNICIAN_ID and DMS_TECHNICIAN 	
	1.5			23-01-2017		C.Ross		BUG 13646 - Add in ServiceAdvisorID, ServiceAdvisor, TechnicianID and TechnicianName columns from Event.AdditionalInfoSales
	1.6			26-01-2017		E.Thomas	BUG 13507 - North America - selection output filename
	1.7			16-02-2017		E. Thomas	BUG 13525 - Rockar questionnaire flagging
	1.8			16-02-2017		E. Thomas	BUG 13466 - Flagging SVO Vehicles	
	1.9			17-03-2017		C.Ledger	BUG 13670 - Add RepairOrderNumber
	1.10		27-03-2017		C.Ledger	BUG 13670 - Add FOBCode and UnknownLang 
	1.11		30-03-2017		C.Ledger	BUG 13970 - Map FOBCode and UnknownLang  		
 	1.12		06-04-2017		E.Thomas	BUG 13703 - CATI - Expiration/Selection date changes
	1.13		25-10-2017		C.Ledger	BUG 14245 - Add Bilingual Fields
	1.14		09-02-2018		E.Thomas	BUG 14362 - Online files – Re-output records to be output once a week / reverse NA Pilot changes
	1.15		01-06-2018		E.Thomas	BUG 14763 - Adding JLR PP fields
	1.16		19-11-2018		C.Ross		BUG 15079 - Add in HotTopicCodes column
	1.17		12-09-2019		C.Ledger	BUG 15571 - Separate Russia Output
	1.19		27-01-2020		C.Ledger    BUG 16891 - Addition of ServiceEventType
	1.20		27-01-2021		C.Ledger	Remove China.Service_WithResponses
	1.21		02-07-2021		C.Ledger	TASK 535 - Add EventID
	1.22		20-07-2021		C.Ledger	TASK 558 - Add EngineType
	1.23		19-10-2021		C.Ledger	TASK 664 - Add PAGCode to EmployeeName, ServiceTechnicianName & ServiceAdvisorName fields
*/

	SET NOCOUNT ON				--V1.6
    DECLARE @NOW	DATETIME,	
			@dtCATI	DATETIME	-- V1.12
    
    SET	@NOW = GETDATE()
	SET	@dtCATI	= DATEADD(week, DATEDIFF(day, 0, @NOW)/7, 4) -- V1.12


	;WITH CTE_CRMInfo (CaseID, AuditItemID)													-- V1.4
	AS (
		SELECT SL.CaseID, 
			MAX(SL.AuditItemID) AS AuditItemID
		FROM SelectionOutput.OnlineOutput O
			INNER JOIN Event.vwEventTypes ET ON	ET.EventTypeID = O.etype 
												AND	ET.EventCategory = 'Service'
			INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL ON SL.CaseID = O.ID
			INNER JOIN [$(ETLDB)].CRM.DMS_Repair_Service DRS ON SL.AuditItemID = DRS.AuditItemID
			--LEFT JOIN [$(ETLDB)].China.Service_WithResponses CSR ON O.ID = CSR.CaseID				-- V1.20										
		--WHERE CSR.CaseID IS NULL																	-- V1.20
		GROUP BY SL.CaseID
	)
    SELECT O.Password,
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
        CASE	WHEN O.Itype ='T' THEN  CONVERT(NVARCHAR(10), @dtCATI, 121)			-- V1.12
				ELSE CONVERT(NVARCHAR(10), @NOW, 121) END AS SelectionDate,			-- V1.12
        CONVERT(NVARCHAR(100), CONVERT(VARCHAR(10), ISNULL(O.etype, ''))
			+ '_' + CASE	WHEN ISNULL(O.ITYPE, '') = '' THEN 'blank'
							ELSE O.ITYPE END 
							+ '_' + CONVERT(VARCHAR(10), ISNULL(O.ccode, ''))
			+ '_' + CASE	WHEN O.manuf = 2 THEN 'J'
							WHEN O.manuf = 3 THEN 'L'
							ELSE 'UknownManufacturer' END 
			+ '_' + CONVERT(VARCHAR(10), ISNULL(O.lang, ''))) AS CampaignId,
        REPLACE(O.EmailSignator, CHAR(10), '<br/>') AS EmailSignator,						-- V1.1
		REPLACE(O.EmailSignatorTitle, CHAR(10), '<br/>') AS EmailSignatorTitle,	
		REPLACE(O.EmailContactText, CHAR(10), '<br/>') AS EmailContactText,	
		REPLACE(O.EmailCompanyDetails, CHAR(10), '<br/>') AS EmailCompanyDetails,
		REPLACE(O.JLRCompanyname, CHAR(10), '<br/>') AS JLRCompanyname,
		REPLACE(O.JLRPrivacyPolicy, CHAR(10), '<br/>') AS JLRPrivacyPolicy,					--V1.15
		CASE	WHEN DRS.AudititemID IS NULL THEN O.EmployeeCode 
				ELSE '' END AS EmployeeCode,
		CASE	WHEN DRS.AudititemID IS NULL THEN CASE	WHEN D.PAGCode IS NULL THEN O.EmployeeName									-- V1.23
														WHEN LEN(O.EmployeeName) > 0 THEN O.EmployeeName + ' (' + D.PAGCode + ')'	-- V1.23
														ELSE '' END																	-- V1.23
				ELSE '' END AS EmployeeName,																						-- V1.23
		O.PilotCode,																					-- V1.3
		ISNULL(COALESCE(DRS.[DMS_TECHNICIAN_ID], O.TechnicianID), '') AS ServiceTechnicianID,			-- V1.4	-- V1.5
		CASE	WHEN D.PAGCode IS NULL THEN ISNULL(COALESCE(DRS.[DMS_TECHNICIAN], O.TechnicianName), '')																	-- V1.23
				WHEN LEN(ISNULL(COALESCE(DRS.[DMS_TECHNICIAN], O.TechnicianName), ''))>0 THEN COALESCE(DRS.[DMS_TECHNICIAN], O.TechnicianName) + ' (' + D.PAGCode + ')'		-- V1.23
				ELSE '' END AS ServiceTechnicianName,																														-- V1.23
		CASE	WHEN D.PAGCode IS NULL THEN ISNULL(COALESCE(DRS.[DMS_SERVICE_ADVISOR], O.ServiceAdvisorName), '')																			-- V1.23
				WHEN LEN(ISNULL(COALESCE(DRS.[DMS_SERVICE_ADVISOR], O.ServiceAdvisorName), ''))>0 THEN COALESCE(DRS.[DMS_SERVICE_ADVISOR], O.ServiceAdvisorName) + ' (' + D.PAGCode + ')'	-- V1.23
				ELSE '' END AS ServiceAdvisorName,																																			-- V1.23
		ISNULL(COALESCE(DRS.[DMS_SERVICE_ADVISOR_ID], O.ServiceAdvisorID), '') AS ServiceAdvisorID,		-- V1.4 -- V1.5
		ISNULL(O.RockarDealer,0) AS RockarDealer,														-- V1.7
		ISNULL(O.SVOvehicle,0) As SVOvehicle,															-- V1.8
		ISNULL(O.SVODealer,0) AS SVODealer,																-- V1.8
		O.RepairOrderNumber,																			-- V1.9
		O.FOBCode,																						-- V1.11
		O.UnknownLang,																					-- V1.11
		O.BilingualFlag,					-- V1.13
		O.langBilingual,					-- V1.13
		O.DearNameBilingual,				-- V1.13
		O.EmailSignatorTitleBilingual,		-- V1.13
		O.EmailContactTextBilingual,		-- V1.13
		O.EmailCompanyDetailsBilingual,		-- V1.13
		O.JLRPrivacyPolicyBilingual,		-- V1.15
		O.HotTopicCodes,					-- V1.16
		O.ServiceEventType,					-- V1.19
		O.EventID,							-- V1.21
		O.EngineType						-- V1.22
    FROM SelectionOutput.OnlineOutput O
        INNER JOIN Event.vwEventTypes ET ON	ET.EventTypeID = O.etype 
											AND ET.EventCategory = 'Service'
		INNER JOIN Event.EventTypes ET1 ON ET1.EventTypeID = O.etype										-- V1.23
		LEFT JOIN dbo.DW_JLRCSPDealers D ON O.OutletPartyID = D.OutletPartyID								-- V1.23
											AND ET1.RelatedOutletFunctionID = D.OutletFunctionID			-- V1.23
		LEFT JOIN CTE_CRMInfo CRM ON CRM.CaseID = O.ID
		LEFT JOIN [$(ETLDB)].CRM.DMS_Repair_Service DRS ON DRS.AuditItemID = CRM.AuditItemID
		--LEFT JOIN [$(ETLDB)].China.Service_WithResponses CSR ON O.ID = CSR.CaseID						-- V1.20 										
	WHERE ((@RussiaOutput = 1 AND ISNULL(O.CTRY,'') = 'Russian Federation') OR (@RussiaOutput = 0 AND ISNULL(O.CTRY,'') <> 'Russian Federation'))	-- V1.10
		--	AND CSR.CaseID IS NULL																		-- V1.20