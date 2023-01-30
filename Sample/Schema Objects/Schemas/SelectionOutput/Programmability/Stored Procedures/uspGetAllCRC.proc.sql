CREATE PROCEDURE SelectionOutput.uspGetAllCRC
	@RussiaOutput INTEGER = 0		-- V1.11
AS

/*
------------------------------------------------------------------------
Description: Gets CRC Records for Selection Output  
Called by: Selection Output.dtsx (Output All Roadside - Data Flow Task)
------------------------------------------------------------------------

------------------------------------------------------------------------
Version		Created			Author			History		
1.0			2016-11-09		Chris Ledger	Original Version
1.1			2016-11-09		Chris Ledger	BUG 13318 Add Table Variable in place of temporary variable and include JOIN on MarketCode
1.2			2017-01-03		Eddie Thomas	BUG 13439 Add new Invite Matrix field
1.3			2017-01-26		Eddie Thomas	BUG 13507 North America - selection output filename
1.4			2017-04-07		Eddie Thomas	BUG 13703 - CATI - Expiration/Selection date changes
1.5			2017-10-25		Chris Ledger	BUG 14245 - Add Bilingual Fields
1.6			2018-02-09		Eddie Thomas	BUG 14362 Online files – Re-output records to be output once a week / reverse NA Pilot changes
1.7			2018-02-20		Eddie Thomas	Was taking too long to output CRM CRC selections
1.8			2018-03-16		Eddie Thomas	Filter out any potential China CRC with Responses Cases
1.9			2018-06-01		Eddie Thomas	BUG 14763 - Adding JLR PP fields
1.10		2018-07-27		Eddie Thomas	Slow outputting CRC Selections 
1.11		2019-09-11		Chris Ledger	BUG 15571 - Separate Russia Output
1.12		2021-03-26		Eddie Thomas	BUG 18152 New CRC Look up
1.13		2021-05-27		Chris Ledger	Remove China.CRC_WithResponses
1.14		2021-07-02		Chris Ledger	TASK 535: Add EventID
1.15		2021-07-12		Chris Ledger	TASK 553: Set CRCOwnerCode as DisplayOnQuestionnaire and add CDSID field
1.16		2021-07-20		Chris Ledger	TASK 558: Add EngineType
1.17		2021-07-21		Chris Ledger	TASK 552: Add SVOTypeID
*/
 
DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	DECLARE @NOW	DATETIME,	
			@dtCATI	DATETIME	-- V1.4
    
	SET	@NOW = GETDATE()
	SET	@dtCATI	= DATEADD(week, DATEDIFF(day, 0, @NOW)/7, 4) -- V1.4

	----------------------------------------------------------
	-- USE TABLE VARIABLE V1.1
	----------------------------------------------------------
	DECLARE @DeDupedEvents TABLE
	(  
		ODSEventID INT NULL,
		AuditItemID INT NULL,
		UNIQUE CLUSTERED (ODSEventID)		-- V1.10
	)

	INSERT INTO @DeDupedEvents (ODSEventID, AuditItemID)
	SELECT ODSEventID, 
		MAX(AuditItemID) AS AuditItemID
	FROM [$(ETLDB)].CRC.CRCEvents
	GROUP BY ODSEventID
	----------------------------------------------------------

	--1.10 Defining tmp table instead of SELECT INTO
	CREATE TABLE #TMP_AllCRC
	(
		[Password] VARCHAR(10) NULL,
		[ID] INT NULL,
		FullModel VARCHAR(100) NULL,
		Model VARCHAR(100) NULL,
		sType NVARCHAR(1020) NULL,
		CarReg NVARCHAR(2000) NULL,
		Title NVARCHAR(2000) NULL,
		Initial NVARCHAR(2000) NULL,
		Surname NVARCHAR(2000) NULL,
		Fullname NVARCHAR(2000) NULL,
		DearName NVARCHAR(2000) NULL,
		CoName NVARCHAR(2000) NULL,
		Add1 NVARCHAR(2000) NULL,
		Add2 NVARCHAR(2000) NULL,
		Add3 NVARCHAR(2000) NULL,
		Add4 NVARCHAR(2000) NULL,
		Add5 NVARCHAR(2000) NULL,
		Add6 NVARCHAR(2000) NULL,
		Add7 NVARCHAR(2000) NULL,
		Add8 NVARCHAR(2000) NULL,
		Add9 NVARCHAR(2000) NULL,
		CTRY VARCHAR(200) NULL,
		EmailAddress NVARCHAR(2000) NULL,
		Dealer NVARCHAR(300) NULL,
		sno VARCHAR(200) NULL,
		ccode SMALLINT NULL,
		modelcode INT NULL,
		lang SMALLINT NULL,
		manuf INT NULL,
		gender TINYINT NULL,
		qver TINYINT NULL,
		blank VARCHAR(150) NULL,
		etype SMALLINT NULL,
		reminder INT NULL,
		week INT NULL,
		test INT NULL,
		CRCsurveyfile VARCHAR(1) NULL,
		ITYPE VARCHAR(5) NULL,
		Expired datetime2 NULL,
		VIN NVARCHAR(2000) NULL,
		EventDate VARCHAR(10) NULL,
		DealerCode NVARCHAR(40) NULL,
		Telephone VARCHAR(70) NULL,
		WorkTel VARCHAR(70) NULL,
		MobilePhone VARCHAR(1) NULL,
		ManufacturerDealerCode VARCHAR(210) NULL,
		ModelYear INT NULL,
		CustomerIdentifier NVARCHAR(2000) NULL,
		OwnershipCycle TINYINT NULL,
		OutletPartyID INT NULL,
		PartyID INT NULL,
		GDDDealerCode NVARCHAR(40) NULL,
		ReportingDealerPartyID INT NULL,
		VariantID SMALLINT NULL,
		ModelVariant VARCHAR(50) NULL,
		SelectionDate NVARCHAR(20) NULL,
		CampaignId NVARCHAR(200) NULL,
		EmailSignator NVARCHAR(2000) NULL,
		EmailSignatorTitle NVARCHAR(2000) NULL,
		EmailContactText NVARCHAR(2000) NULL,
		EmailCompanyDetails NVARCHAR(2000) NULL,
		JLRCompanyname NVARCHAR(2000) NULL,
		JLRPrivacyPolicy NVARCHAR(2000) NULL,
		EmployeeCode NVARCHAR(200) NULL,
		EmployeeName NVARCHAR(200) NULL,
		PilotCode VARCHAR(10) NULL,
		CRCCode NVARCHAR(2000) NULL,
		MarketCode NVARCHAR(2000) NULL,
		SampleYear INT NULL,
		VehicleMileage NVARCHAR(2000) NULL,
		VehicleMonthsinService NVARCHAR(2000) NULL,
		RowId NVARCHAR(2000) NULL,
		SRNumber NVARCHAR(2000) NULL,
		BilingualFlag bit NULL,
		langBilingual SMALLINT NULL,
		DearNameBilingual NVARCHAR(1000) NULL,
		EmailSignatorTitleBilingual NVARCHAR(1000) NULL,
		EmailContactTextBilingual NVARCHAR(2000) NULL,
		EmailCompanyDetailsBilingual NVARCHAR(2000) NULL,
		JLRPrivacyPolicyBilingual NVARCHAR(2000) NULL,
		PreferredLanguageID INT NULL,
		ClosedBy NVARCHAR(2000) NULL,
		Owner NVARCHAR(2000) NULL,
		BrandCode NVARCHAR(2000) NULL,
		EventID BIGINT NULL,								-- V1.14
		EngineType INT NULL,								-- V1.16
		SVOvehicle	INT NULL								-- V1.17
	)

	INSERT INTO #TMP_AllCRC
	SELECT DISTINCT
		O.[Password],
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
		ISNULL(O.dealer, '') AS Dealer,
		O.sno,
		O.ccode,
		CASE	WHEN O.VIN LIKE '%_CRC_Unknown_V' OR O.Model = 'Unknown Vehicle' THEN '99999' 
				ELSE O.modelcode END AS modelcode,
		O.lang,
		O.manuf,
		O.gender,
		O.qver,
		O.blank,
		O.etype,
		O.reminder,
		O.week,
		O.test,    
		O.SalesServiceFile AS CRCsurveyfile,
		O.ITYPE,
		O.Expired,
		REPLACE(O.VIN, CHAR(9), '') AS VIN,
		CAST(REPLACE(CONVERT(VARCHAR(10), O.EventDate, 102), '.', '-') AS VARCHAR(10)) AS EventDate, 
		O.DealerCode,
		'' AS Telephone,
		'' AS WorkTel,
		'' AS MobilePhone,
		O.ManufacturerDealerCode,
		O.ModelYear,
		REPLACE(CRC.UniqueCustomerId, CHAR(9), '') AS CustomerIdentifier,
		O.OwnershipCycle,
		O.OutletPartyID,
		O.PartyID,
		O.GDDDealerCode,
		O.ReportingDealerPartyID,
		O.VariantID,
		O.ModelVariant,
		CASE	WHEN O.Itype ='T' THEN CONVERT(NVARCHAR(10), @dtCATI, 121)		-- V1.4
				ELSE CONVERT(NVARCHAR(10), @NOW, 121) END AS SelectionDate,		-- V1.4
		CONVERT(NVARCHAR(100), CONVERT(VARCHAR(10), ISNULL(O.etype, '')) + '_'
			+ CASE WHEN ISNULL(O.ITYPE, '') = '' THEN 'blank'
				   ELSE O.ITYPE END + '_' 
			+ CONVERT(VARCHAR(10), ISNULL(O.ccode, '')) + '_'
			+ CASE WHEN O.manuf = 2 THEN 'J'
				   WHEN O.manuf = 3 THEN 'L'
				   ELSE 'UknownManufacturer' END + '_' 
			+ CONVERT(VARCHAR(10), ISNULL(O.lang, ''))) AS CampaignId,
		REPLACE(O.EmailSignator, CHAR(10), '<br/>') AS EmailSignator,					
		REPLACE(O.EmailSignatorTitle, CHAR(10), '<br/>') AS EmailSignatorTitle,	
		REPLACE(O.EmailContactText, CHAR(10), '<br/>') AS EmailContactText,	
		REPLACE(O.EmailCompanyDetails, CHAR(10), '<br/>') AS EmailCompanyDetails,
		REPLACE(O.JLRCompanyname, CHAR(10), '<br/>') AS JLRCompanyname,				-- V1.2
		REPLACE(O.JLRPrivacyPolicy, CHAR(10), '<br/>') AS JLRPrivacyPolicy,			-- V1.9
		O.EmployeeCode,
		O.EmployeeName,
		O.PilotCode,					
		CRC.CRCCode,
		CRC.MarketCode,
		YEAR (GETDATE())  AS SampleYear,
		CRC.VehicleMileage,
		CRC.VehicleMonthsinService,
		CRC.RowId,
		CRC.CaseNumber AS SRNumber,
		O.BilingualFlag,					-- V1.5
		O.langBilingual,					-- V1.5
		O.DearNameBilingual,				-- V1.5
		O.EmailSignatorTitleBilingual,		-- V1.5
		O.EmailContactTextBilingual,		-- V1.5
		O.EmailCompanyDetailsBilingual,		-- V1.5
		O.JLRPrivacyPolicyBilingual,		-- V1.9
		CRC.PreferredLanguageID,
		CRC.ClosedBy,
		CRC.[Owner],
		CRC.BrandCode,
		O.EventID,							-- V1.14
		O.EngineType,						-- V1.16
		O.SVOvehicle						-- V1.17
    FROM SelectionOutput.OnlineOutput O
		INNER JOIN Event.vwEventTypes ET ON	ET.EventTypeID = O.etype 
											AND ET.EventCategory = 'CRC' 
		INNER JOIN Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = O.ID 
		INNER JOIN @DeDupedEvents RED ON RED.ODSEventID = AEBI.EventID
		INNER JOIN [$(ETLDB)].CRC.CRCEvents CRC	ON CRC.AuditItemID = RED.AuditItemID
	WHERE ((@RussiaOutput = 1 AND ISNULL(O.CTRY,'') = 'Russian Federation') OR  (@RussiaOutput = 0 AND ISNULL(O.CTRY,'') <> 'Russian Federation'))	-- V1.11
	
	
	-- V1.7
	SELECT DISTINCT
		CRC.[Password],
		CRC.ID,
		CRC.FullModel,
		CRC.Model,
		CRC.sType,
		CRC.CarReg,
		CRC.Title,
		CRC.Initial,
		CRC.Surname,
		CRC.Fullname,
		CRC.DearName,
		CRC.CoName,
		CRC.Add1,
		CRC.Add2,
		CRC.Add3,
		CRC.Add4,
		CRC.Add5,
		CRC.Add6,
		CRC.Add7,
		CRC.Add8,
		CRC.Add9,
		CRC.CTRY,
		CRC.EmailAddress,
		CRC.Dealer,
		CRC.sno,
		CRC.ccode,
		CRC.modelcode,
		CRC.lang,
		CRC.manuf,
		CRC.gender,
		CRC.qver,
		CRC.blank,
		CRC.etype,
		CRC.reminder,
		CRC.week,
		CRC.test,
		R.Region AS sampleFlag,
		CRC.CRCsurveyfile,
		CRC.ITYPE,
		CRC.Expired,
		CRC.VIN,
		CRC.EventDate,
		CRC.DealerCode,
		CRC.Telephone,
		CRC.WorkTel,
		CRC.MobilePhone,
		CRC.ManufacturerDealerCode,
		CRC.ModelYear,
		CRC.CustomerIdentifier,
		CRC.OwnershipCycle,
		CRC.OutletPartyID,
		CRC.PartyID,
		CRC.GDDDealerCode,
		CRC.ReportingDealerPartyID,
		CRC.VariantID,
		CRC.ModelVariant,
		CRC.SelectionDate,
		CRC.CampaignId,
		CRC.EmailSignator,
		CRC.EmailSignatorTitle,
		CRC.EmailContactText,
		CRC.EmailCompanyDetails,
		CRC.JLRPrivacyPolicy,
		CRC.JLRCompanyname,
		CRC.EmployeeCode,
		CRC.EmployeeName,
		CRC.PilotCode,
		COALESCE(LTRIM(RTRIM(CRC.[Owner])), LTRIM(RTRIM(CRC.ClosedBY)), '') AS [Owner],		-- V1.12
		CASE	WHEN LKO.CDSID IS NOT NULL THEN LKO.DisplayOnQuestionnaire					-- V1.15 WE'VE GOT A MATCH IN THE LOOKUP TABLE, USE IT. 
				WHEN LKF.CDSID IS NOT NULL THEN LKF.DisplayOnQuestionnaire					-- V1.15
				ELSE CRC.[Owner] END AS OwnerCode,											-- V1.12 V1.15
		CRC.CRCCode,
		CRC.MarketCode,
		CRC.SampleYear,
		CRC.VehicleMileage,
		CRC.VehicleMonthsinService,
		CRC.RowId,
		CRC.SRNumber,
		CRC.BilingualFlag,
		CRC.langBilingual,
		CRC.DearNameBilingual,
		CRC.EmailSignatorTitleBilingual,
		CRC.EmailContactTextBilingual,
		CRC.EmailCompanyDetailsBilingual,
		CRC.JLRPrivacyPolicyBilingual,
		CRC.EventID,																			-- V1.14
		CASE	WHEN LKO.CDSID IS NOT NULL THEN LKO.CDSID										-- V1.15 WE'VE GOT A MATCH IN THE LOOKUP TABLE, USE IT. 
				WHEN LKF.CDSID IS NOT NULL THEN LKF.CDSID										-- V1.15
				ELSE CRC.[Owner] END AS CDSID,													-- V1.12 V1.15
		CRC.EngineType,																			-- V1.16
		CRC.SVOvehicle																			-- V1.17
	FROM #TMP_AllCRC CRC
		LEFT JOIN dbo.Languages L ON CRC.PreferredLanguageID = L.LanguageID
		LEFT JOIN ContactMechanism.Countries C ON CRC.MarketCode = C.ISOAlpha3  
		LEFT JOIN Markets M	ON C.CountryID = M.CountryID 
		LEFT JOIN dbo.Regions R ON R.RegionID = M.RegionID
		LEFT JOIN [$(ETLDB)].Lookup.CRCAgents_GlobalList LKO ON LTRIM(RTRIM(CRC.[Owner])) = LKO.CDSID 
																AND CRC.MarketCode = LKO.MarketCode			-- V1.12
		LEFT JOIN [$(ETLDB)].Lookup.CRCAgents_GlobalList LKF ON LTRIM(RTRIM(CRC.[Owner])) = LKF.FullName 
																AND CRC.MarketCode =  LKF.MarketCode		-- V1.12
	--	LEFT JOIN Sample_ETL.China.CRC_WithResponses CWR ON CRC.ID = CWR.CASEID								-- V1.13
	--WHERE CWR.CaseID is NULL																				-- V1.13

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
		
	IF @@TRANCOUNT > 0
	BEGIN
		ROLLBACK TRAN
	END
	
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH