CREATE PROCEDURE [Enprecis].[uspGetAllSales]

/*
	Purpose:	Produces on-line output for Enprecis/CQI
		
	Version			Date				Developer			Comment
	1.0				04/05/2016			Chris Ledger		Created
	1.1				25/01/2017			Chris Ledger		BUG 13160: Add Model Summary & LanguageID
	1.2				27/01/2017			Chris Ledger		BUG 13160: Add Interval
	1.3				25/04/2017			Chris Ledger		BUG 13854: Add Extra Vehicle Feed
	1.4				27/04/2017			Chris Ledger		BUG 13854: Fix bug in outputting ProductionMonth and remove fields
	1.5				10/05/2017			Chris Ledger		BUG 13854: Change formatting of ProductionDate and WarrantyStartDate
	1.6				12/06/2017			Chris Ledger		BUG 14000: Add UnknownLang
	1.7				23/08/2017			Chris Ledger		BUG 14189: Change EVF fields
	1.8				05/07/2018			Eddie Thomas		BUG 14763: GDPR - Invite Matrix including JLR PP link
	1.9				18/09/2018			Chris Ledger		BUG 14995: Add JLRCompanyname field
	1.10			08/10/2018			Chris Ledger		BUG 14964: EVF Data no longer manditory
	1.11			13/03/2020			Chris Ledger		BUG 18002: Add Powertrain
	1.12			29/03/2021			Chris Ledger		Remove Powertrain
*/


AS
DECLARE @NOW DATETIME
    SET @NOW = GETDATE()


    SELECT DISTINCT
		O.Password ,
        O.ID ,
        O.FullModel ,
        O.Model ,
        O.sType ,
        REPLACE(O.CarReg, CHAR(9), '') AS CarReg,
        REPLACE(O.Title , CHAR(9), '') AS Title,
        REPLACE(O.Initial , CHAR(9), '') AS Initial,
        REPLACE(O.Surname , CHAR(9), '') AS Surname,
        REPLACE(O.Fullname , CHAR(9), '') AS Fullname,
        REPLACE(O.DearName , CHAR(9), '') AS DearName,
        REPLACE(O.CoName , CHAR(9), '') AS CoName,
        REPLACE(O.Add1 , CHAR(9), '') AS Add1,
        REPLACE(O.Add2 , CHAR(9), '') AS Add2,
        REPLACE(O.Add3 , CHAR(9), '') AS Add3,
        REPLACE(O.Add4 , CHAR(9), '') AS Add4,
        REPLACE(O.Add5 , CHAR(9), '') AS Add5,
        REPLACE(O.Add6 , CHAR(9), '') AS Add6,
        REPLACE(O.Add7 , CHAR(9), '') AS Add7,
        REPLACE(O.Add8 , CHAR(9), '') AS Add8,
        REPLACE(O.Add9 , CHAR(9), '') AS Add9,
        O.CTRY ,
        REPLACE(O.EmailAddress , CHAR(9), '') AS EmailAddress,
        O.Dealer ,
        O.sno ,
        O.ccode ,
        O.modelcode ,
        O.lang ,
        O.manuf ,
        O.gender ,
        O.qver ,
        O.blank ,
        0 AS etype ,
        O.reminder ,
        O.week ,
        O.test ,
        O.SampleFlag ,
        O.SalesServiceFile ,
        O.ITYPE ,
        O.Expired ,
        REPLACE(O.VIN , CHAR(9), '') AS VIN,
        REPLACE(CONVERT(VARCHAR(10), O.EventDate, 102), '.', '-') AS EventDate ,
        O.DealerCode ,
        REPLACE(O.Telephone , CHAR(9), '') AS Telephone,
        REPLACE(O.WorkTel , CHAR(9), '') AS WorkTel,
        REPLACE(O.MobilePhone , CHAR(9), '') AS MobilePhone,
        O.ManufacturerDealerCode ,
        EVF.ModelYear ,																				-- V1.7
        REPLACE(O.CustomerIdentifier , CHAR(9), '') AS CustomerIdentifier,
        O.OwnershipCycle ,
        O.OutletPartyID ,
        O.PartyID ,
        O.GDDDealerCode ,
        O.ReportingDealerPartyID ,
        O.VariantID ,
        O.ModelVariant ,
        CONVERT(NVARCHAR(10), @NOW, 121) AS SelectionDate ,
		CONVERT(NVARCHAR(100),
        CONVERT(VARCHAR(10), ISNULL(O.etype, '')) + '_'
        + CASE	WHEN ISNULL(O.ITYPE, '') = '' THEN 'blank'
                ELSE O.ITYPE END + '_' 
		+ CONVERT(VARCHAR(10), ISNULL(O.ccode, '')) + '_'
        + CASE	WHEN O.manuf = 2 THEN 'J'
                WHEN O.manuf = 3 THEN 'L'
                ELSE 'UknownManufacturer' END + '_' 
		+ CONVERT(VARCHAR(10), ISNULL(O.lang, ''))) AS CampaignId,
        REPLACE(O.EmailSignator, CHAR(10), '<br/>') AS EmailSignator	,							-- V1.1
		REPLACE(O.EmailSignatorTitle, CHAR(10), '<br/>') AS EmailSignatorTitle,	
		REPLACE(O.EmailContactText, CHAR(10), '<br/>') AS EmailContactText,	
		REPLACE(O.EmailCompanyDetails, CHAR(10), '<br/>') AS EmailCompanyDetails,
		REPLACE(O.JLRPrivacyPolicy, CHAR(10), '<br/>') AS JLRPrivacyPolicy,							-- V1.8
		REPLACE(O.JLRCompanyname, CHAR(10), '<br/>') AS JLRCompanyname,								-- V1.9
		O.EmployeeCode,
		O.EmployeeName,
		O.ModelSummary,
		'' AS LanguageID,
		O.IntervalPeriod,
		--EVF.EngineSerialNumber,																	-- V1.3
		ISNULL(CONVERT(VARCHAR(10), EVF.ProductionDate, 103),'') AS ProductionDate,					-- V1.5	V1.8
		ISNULL(CONVERT(VARCHAR, YEAR(EVF.ProductionMonth))+ '-' + RIGHT('0'+CONVERT(VARCHAR, MONTH(EVF.ProductionMonth)), 2), '') AS ProductionMonth,		-- V1.4	V1.8
		--REPLACE(CONVERT(VARCHAR(10), EVF.SoldDate, 102), '.', '-') AS SoldDate,					-- V1.3
		--EVF.CTRYSold,																				-- V1.3 V1.7
		ISNULL(EVF.CountrySold,'') AS CountrySold,													-- V1.7	V1.8
		ISNULL(EVF.Plant,'') AS Plant,																-- V1.3	V1.8
		--CONVERT(VARCHAR(10), EVF.WarrantyStartDate, 103) AS WarrantyStartDate,					-- V1.5 V1.7
		ISNULL(EVF.VehicleLine,'') AS VehicleLine,													-- V1.3	V1.8
		ISNULL(EVF.BodyStyle,'') AS BodyStyle,														-- V1.3	V1.8
		ISNULL(EVF.Drive,'') AS Drive,																-- V1.3	V1.8
		ISNULL(EVF.Transmission,'') AS Transmission,												-- V1.3	V1.8
		ISNULL(EVF.Engine,'') AS Engine,															-- V1.3	V1.8
		O.UnknownLang																				-- V1.6					
    FROM SelectionOutput.OnlineOutput AS O
		LEFT JOIN Vehicle.ExtraVehicleFeed EVF ON O.VIN = EVF.VIN									-- V1.8
			