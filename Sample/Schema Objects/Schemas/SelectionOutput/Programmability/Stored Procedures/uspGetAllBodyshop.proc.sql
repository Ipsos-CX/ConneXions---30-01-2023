CREATE PROCEDURE [SelectionOutput].[uspGetAllBodyshop]
	@RussiaOutput INTEGER = 0		-- V1.15
AS
/*

	Description: Gets All Bodyshop. Called by: Selection Output.dtsx (Output All Bodyshop - Data Flow Task)	

	Version		Created			Author			History		
	-------		-------			------			-------			
	1.0			16-08-2017		Eddie Thomas	Original version.  BUG 14141.  
	1.13		25-10-2017		Chris Ledger	BUG 14245 - Add Bilingual Fields
	1.14		01-06-2018		Eddie Thomas	BUG 14763 - Adding JLR PP fields
	1.15		16-09-2019		Chris Ledger	BUG 15571 - Separate Russia Output
	1.16		27-05-2021		Chris Ledger	Tidy formatting
*/

SET NOCOUNT ON		-- V1.6
    
	DECLARE @NOW	DATETIME,	
			@dtCATI	DATETIME	-- V1.12
    
    SET	@NOW = GETDATE()
	SET	@dtCATI	= DATEADD(week, DATEDIFF(day, 0, @NOW)/7, 4)	-- V1.12

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
        CONVERT(NVARCHAR(100), CONVERT(VARCHAR(10), ISNULL(O.etype, '')) + '_' 
			+ CASE	WHEN ISNULL(O.ITYPE, '') = '' THEN 'blank'
					ELSE O.ITYPE END + '_' 
			+ CONVERT(VARCHAR(10), ISNULL(O.ccode, '')) + '_' 
			+ CASE	WHEN O.manuf = 2 THEN 'J'
					WHEN O.manuf = 3 THEN 'L'
					ELSE 'UnknownManufacturer' END + '_' 
			+ CONVERT(VARCHAR(10), ISNULL(O.lang, ''))) AS CampaignId,
        REPLACE(O.EmailSignator, CHAR(10), '<br/>') AS EmailSignator,				-- V1.1
		REPLACE(O.EmailSignatorTitle, CHAR(10), '<br/>') AS EmailSignatorTitle,	
		REPLACE(O.EmailContactText, CHAR(10), '<br/>') AS EmailContactText,	
		REPLACE(O.EmailCompanyDetails, CHAR(10), '<br/>') AS EmailCompanyDetails,
		REPLACE(O.JLRCompanyname, CHAR(10), '<br/>') AS JLRCompanyname,
		REPLACE(O.JLRPrivacyPolicy, CHAR(10), '<br/>') AS JLRPrivacyPolicy,			-- V1.14
		O.EmployeeCode,
		O.EmployeeName,
		O.PilotCode,
		ISNULL(O.RockarDealer,0) AS RockarDealer,									-- V1.7
		ISNULL(O.SVOvehicle,0) AS SVOvehicle,										-- V1.8
		ISNULL(O.SVODealer,0) AS SVODealer,											-- V1.8
		O.RepairOrderNumber,														-- V1.9
		O.FOBCode,																	-- V1.11
		O.UnknownLang,																-- V1.11
		O.BilingualFlag,					-- V1.13
		O.langBilingual,					-- V1.13
		O.DearNameBilingual,				-- V1.13
		O.EmailSignatorTitleBilingual,		-- V1.13
		O.EmailContactTextBilingual,		-- V1.13
		O.EmailCompanyDetailsBilingual,		-- V1.13
		O.JLRPrivacyPolicyBilingual			-- V1.14
    FROM SelectionOutput.OnlineOutput O
		INNER JOIN Event.vwEventTypes ET ON	ET.EventTypeID = O.etype 
											AND ET.EventCategory = 'Bodyshop'
	WHERE ((@RussiaOutput = 1 AND ISNULL(O.CTRY,'') = 'Russian Federation') OR (@RussiaOutput = 0 AND ISNULL(O.CTRY,'') <> 'Russian Federation'))	-- V1.15
