CREATE PROCEDURE SelectionOutput.uspGetAllGeneralEnquiry
	@RussiaOutput INTEGER = 0		-- V1.11
AS

/*
------------------------------------------------------------------------
Description: Gets CRC GeneralEnquiry Records for Selection Output  
Called by: Selection Output Child - CRC General Enquiry
------------------------------------------------------------------------

------------------------------------------------------------------------
Version		Created			Author			History		
1.0			2021-07-06		Eddie Thomas	Original Version
1.1			2021-07-12		Chris Ledger	TASK 553: Set CRCOwnerCode as DisplayOnQuestionnaire and add CDSID field
1.2			2021-07-20		Chris Ledger	TASK 558: Add EngineType
1.3			2021-07-21		Chris Ledger	TASK 552: Add SVOvehicle
*/
 
DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	DECLARE @NOW	DATETIME,	
			@dtCATI	DATETIME
    
	SET	@NOW = GETDATE()
	SET	@dtCATI	= DATEADD(week, DATEDIFF(day, 0, @NOW)/7, 4)

	----------------------------------------------------------
	-- USE TABLE VARIABLE V1.1
	----------------------------------------------------------
	DECLARE @DeDupedEvents TABLE
	(  
		ODSEventID INT NULL,
		AuditItemID INT NULL,
		UNIQUE CLUSTERED (ODSEventID)
	)

	INSERT INTO @DeDupedEvents (ODSEventID, AuditItemID)
	SELECT ODSEventID, 
		MAX(AuditItemID) AS AuditItemID
	FROM [$(ETLDB)].GeneralEnquiry.GeneralEnquiryEvents
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
		GeneralEnquirysurveyfile VARCHAR(1) NULL,
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
		EmployeeResponsibleName NVARCHAR(2000),					-- V1.1
		ClosedBy NVARCHAR(2000) NULL,
		Owner NVARCHAR(2000) NULL,
		BrandCode NVARCHAR(2000) NULL,
		EventID BIGINT NULL,
		EngineType INT NULL,									-- V1.2
		SVOvehicle INT NULL										-- V1.3
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
		O.SalesServiceFile AS GeneralEnquirysurveyfile,
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
		CASE	WHEN O.Itype ='T' THEN CONVERT(NVARCHAR(10), @dtCATI, 121)	
				ELSE CONVERT(NVARCHAR(10), @NOW, 121) END AS SelectionDate,	
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
		REPLACE(O.JLRCompanyname, CHAR(10), '<br/>') AS JLRCompanyname,	
		REPLACE(O.JLRPrivacyPolicy, CHAR(10), '<br/>') AS JLRPrivacyPolicy,
		O.EmployeeCode,
		O.EmployeeName,
		O.PilotCode,					
		--CRC.CRCCode,
		CRC.CRCCentreCode,
		CRC.MarketCode,
		YEAR (GETDATE())  AS SampleYear,
		CRC.VehicleMileage,
		CRC.VehicleMonthsinService,
		CRC.RowId,
		CRC.CaseNumber AS SRNumber,
		O.BilingualFlag,
		O.langBilingual,
		O.DearNameBilingual,
		O.EmailSignatorTitleBilingual,
		O.EmailContactTextBilingual,
		O.EmailCompanyDetailsBilingual,
		O.JLRPrivacyPolicyBilingual,
		CRC.PreferredLanguageID,
		CRC.EmployeeResponsibleName,											-- V1.1
		CRC.ClosedBy,
		CRC.[Owner],
		CRC.BrandCode,
		O.EventID,
		O.EngineType,															-- V1.2
		O.SVOvehicle															-- V1.3
    FROM SelectionOutput.OnlineOutput O
		INNER JOIN Event.vwEventTypes ET ON	ET.EventTypeID = O.etype 
											AND ET.EventCategory = 'CRC General Enquiry' 
		INNER JOIN Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = O.ID 
		INNER JOIN @DeDupedEvents RED ON RED.ODSEventID = AEBI.EventID
		INNER JOIN [$(ETLDB)].GeneralEnquiry.GeneralEnquiryEvents CRC ON CRC.AuditItemID = RED.AuditItemID
	WHERE ((@RussiaOutput = 1 AND ISNULL(O.CTRY,'') = 'Russian Federation') OR (@RussiaOutput = 0 AND ISNULL(O.CTRY,'') <> 'Russian Federation'))
	
	
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
		CRC.GeneralEnquirysurveyfile,
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
		COALESCE(LTRIM(RTRIM(CRC.EmployeeResponsibleName)), LTRIM(RTRIM(CRC.Owner)), LTRIM(RTRIM(CRC.ClosedBy)), '') AS [Owner],	-- V1.1		
		CASE	WHEN LKO.CDSID IS NOT NULL THEN LKO.DisplayOnQuestionnaire															-- V1.1 
				WHEN LKF.CDSID IS NOT NULL THEN LKF.DisplayOnQuestionnaire															-- V1.1
				ELSE COALESCE(LTRIM(RTRIM(CRC.EmployeeResponsibleName)), LTRIM(RTRIM(CRC.Owner)), '') END AS OwnerCode,				-- V1.1
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
		CRC.EventID,
		CASE	WHEN LKO.CDSID IS NOT NULL THEN LKO.CDSID						-- V1.1 
				WHEN LKF.CDSID IS NOT NULL THEN LKF.CDSID						-- V1.1
				ELSE COALESCE(LTRIM(RTRIM(CRC.EmployeeResponsibleName)), LTRIM(RTRIM(CRC.Owner)), '') END AS CDSID,					-- V1.1
		CRC.EngineType,																												-- V1.2
		CRC.SVOvehicle																												-- V1.3
	FROM #TMP_AllCRC CRC
		LEFT JOIN dbo.Languages L ON CRC.PreferredLanguageID = L.LanguageID
		LEFT JOIN ContactMechanism.Countries C ON CRC.MarketCode = C.ISOAlpha3  
		LEFT JOIN Markets M	ON C.CountryID = M.CountryID 
		LEFT JOIN dbo.Regions R ON R.RegionID = M.RegionID
		LEFT JOIN [$(ETLDB)].Lookup.CRCAgents_GlobalList LKO ON COALESCE(LTRIM(RTRIM(CRC.EmployeeResponsibleName)), LTRIM(RTRIM(CRC.Owner)), '') = LKO.CDSID		-- V1.1
																AND CRC.MarketCode = LKO.MarketCode	
		LEFT JOIN [$(ETLDB)].Lookup.CRCAgents_GlobalList LKF ON COALESCE(LTRIM(RTRIM(CRC.EmployeeResponsibleName)), LTRIM(RTRIM(CRC.Owner)), '') = LKF.FullName		-- V1.1
																AND CRC.MarketCode =  LKF.MarketCode


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