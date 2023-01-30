CREATE PROCEDURE SelectionOutput.uspGetAllLostLeads
	@NorthAmericaOnly INTEGER = 0,	-- V1.6 
	@RussiaOutput INTEGER = 0		-- V1.10
AS 

/*

	Purpose:	Gets all the LostLeads records to create the On-Line output file in "Selection Output.dtsx"
		
	Version			Date			Developer			Comment
	1.0				11/08/2016		Chris Ross			Copied from SelectionOutput.uspGetAllSales
	1.1				26/01/2017		Eddie Thomas		BUG 13507 North America - selection output filename
	1.2				06/04/2017		Eddie Thomas		BUG 13703 - CATI - Expiration/Selection date changes
	1.3				04/09/2017		Eddie Thomas		BUG 14088 - CATI - Expiration/Selection date changes for UK Lost Leads
	1.4				25/10/2017		Chris Ledger		BUG 14245 - Add Bilingual Fields
	1.5				09/02/2018		Eddie Thomas		BUG 14362 Online files – Re-output records to be output once a week / reverse NA Pilot changes
	1.6				12/03-2018		Chris Ledger		BUG 14272 Add NA selection output for Lost Leads back in
	1.7				01/06/2018		Eddie Thomas		BUG 14763 - Adding JLR PP fields
	1.8				26/09/2018		Eddie Thomas		BUG 14820 - Lost Leads -  Global loader change 
	1.9				01/03/2019		Eddie Thomas		BUG 15281 - Lost Leads Selection date 
	1.10			12/09/2019		Chris Ledger		BUG 15571 - Separate Russia Output
	1.11			25/10/2019		Chris Ledger		BUG 15490 - Add PreOwned LostLeads and DealerType field
	1.12			28/01/2020		Chris Ledger		BUG 16819 - Add Queue field
	1.13			27/05/2021		Chris Ledger		Remove China.Sales_WithResponses
	1.14			20/07/2021		Chris Ledger		TASK 558 - Add EventID & EngineType
	1.15			21/07/2021		Chris Ledger		TASK 552 - Add SVOvehicle
*/
	SET NOCOUNT ON	-- V1.1
	DECLARE @NOW			DATETIME,	
			@dtCATI			DATETIME,			-- V1.2
			@SelectionDate	DATETIME
			--@LLUKSelectionDate	DATETIME,	-- V1.3
			--@CurDay			VARCHAR(10)		-- V1.3
	
	SET	@NOW = GETDATE() 
	--SET @CurDay = (SELECT DATENAME(dw,@NOW))	-- V1.3

	--UK LOST LEADS SELECTION DATE IS NOW THE NEXT FOLLOWING MONDAY
	--IF @CurDay = 'Monday'														-- V1.3
		--SET @LLUKSelectionDate = @NOW											-- V1.3
	--ELSE																		-- V1.3
		--SET @LLUKSelectionDate = DATEADD(week, DATEDIFF(day, 0, @NOW)/7, 7)	-- V1.3
	
	SET	@dtCATI	= DATEADD(week, DATEDIFF(day, 0, @NOW)/7, 4) -- V1.2


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
		--CASE	WHEN O.CTRY ='United Kingdom' THEN CONVERT (NVARCHAR(10), @LLUKSelectionDate, 121)	-- V1.3
		--		ELSE CONVERT (NVARCHAR(10), @dtCATI, 121) END AS SelectionDate,						-- V1.3
		--CONVERT (NVARCHAR(10), @dtCATI, 121) AS SelectionDate,
		CONVERT (NVARCHAR(10), CS.CreationDate, 121) AS SelectionDate,								-- V1.9	
		CONVERT(NVARCHAR(100), CONVERT(VARCHAR(10), ISNULL(O.etype, '')) + '_'
			+ CASE	WHEN ISNULL(O.ITYPE, '') = '' THEN 'blank'
					ELSE O.ITYPE END + '_' 
			+ CONVERT(VARCHAR(10), ISNULL(O.ccode, '')) + '_'
			+ CASE	WHEN O.manuf = 2 THEN 'J'
					WHEN O.manuf = 3 THEN 'L'
					ELSE 'UknownManufacturer' END + '_' 
			+ CONVERT(VARCHAR(10), ISNULL(O.lang, ''))) AS CampaignId,
        REPLACE(O.EmailSignator, CHAR(10), '<br/>') AS EmailSignator,				
		REPLACE(O.EmailSignatorTitle, CHAR(10), '<br/>') AS EmailSignatorTitle,	
		REPLACE(O.EmailContactText, CHAR(10), '<br/>') AS EmailContactText,	
		REPLACE(O.EmailCompanyDetails, CHAR(10), '<br/>') AS EmailCompanyDetails,
		REPLACE(O.JLRCompanyname, CHAR(10), '<br/>') AS JLRCompanyname,
		REPLACE(O.JLRPrivacyPolicy, CHAR(10), '<br/>') AS JLRPrivacyPolicy,							-- V1.7
		O.EmployeeCode,
		O.EmployeeName,
		O.PilotCode,
		ISNULL(M.SelectionOutput_NSCFlag, 'N') AS NSCFlag, 
		O.BilingualFlag,									-- V1.4
		O.langBilingual,									-- V1.4
		O.DearNameBilingual,								-- V1.4
		O.EmailSignatorTitleBilingual,						-- V1.4
		O.EmailContactTextBilingual,						-- V1.4
		O.EmailCompanyDetailsBilingual,						-- V1.4	
		O.JLRPrivacyPolicyBilingual,						-- V1.7	
		O.JLREventType,										-- V1.8
		O.DealerType,										-- V1.11
		O.Queue,											-- V1.12
		O.EventID,											-- V1.14
		O.EngineType,										-- V1.16
		O.SVOvehicle										-- V1.17
    FROM SelectionOutput.OnlineOutput O
		INNER JOIN Event.vwEventTypes ET ON	ET.EventTypeID = O.etype 
											AND ET.EventCategory IN ('LostLeads', 'PreOwned LostLeads')		-- V1.11
		INNER JOIN Event.Cases CS ON O.ID = CS.CaseID		-- V1.9
		LEFT JOIN dbo.Markets M ON M.CountryID = O.ccode
		--LEFT JOIN [$(ETLDB)].China.Sales_WithResponses CSR ON O.ID = CSR.CaseID 							-- V1.13							
	WHERE ((@NorthAmericaOnly = 1 AND O.CTRY IN ('UNITED STATES OF AMERICA','Canada')) OR (@NorthAmericaOnly = 0 AND O.CTRY NOT IN ('UNITED STATES OF AMERICA','Canada')))						-- V1.6
		AND ((@RussiaOutput = 1 AND ISNULL(O.CTRY,'') = 'Russian Federation') OR  (@RussiaOutput = 0 AND ISNULL(O.CTRY,'') <> 'Russian Federation'))	-- V1.10
		--AND CSR.CaseID IS NULL																			-- V1.13
