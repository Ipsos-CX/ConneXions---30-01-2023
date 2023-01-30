CREATE VIEW DealerManagement.vwDA_DEALERS_JLRCSP_Appointments

AS

	-- Purpose: Data Access view to enable inserts into Dealer Appointments table
	--
	--
	-- Version		Developer			Date			Comment
	-- 1.0			Martin Riverol		20/04/2012		Created
	-- 1.1			Martin Riverol		12/04/2012		Added GDD code
	-- 1.2			Eddie Thomas		10/09/2013		Added PAG Code
	-- 1.3			Chris Ross			25/02/2015		BUG 11026 - Added in BusinessRegion column 
	-- 1.4			Chris Ross			12/10/2016		BUG 13171 - Added in SubNationalTerritory column
	-- 1.5			Chris Ledger		13/11/2017		BUG 14365 - Added SVODealer & FleetDealer
	-- 1.6			Chris Ledger		17/01/2020		BUG 16793 - Added Dealer10DigitCode

	SELECT 
		Functions
		, Manufacturer
		, SuperNationalRegion
		, BusinessRegion			-- v1.3
		, Market
		, SubNationalTerritory		-- v1.4
		, SubNationalRegion			
		, CombinedDealer
		, OutletName
		, OutletName_NativeLanguage
		, OutletName_Short
		, OutletCode
		, OutletCode_Manufacturer
		, OutletCode_Warranty
		, OutletCode_Importer
		, OutletCode_GDD
		, PAGCode
		, PAGName
		, ImporterPartyID
		, Town
		, Region
		, FromDate
		, LanguageID
		, SVODealer					-- V1.5
		, FleetDealer				-- V1.5
		, Dealer10DigitCode			-- V1.6
		, IP_SystemUser
	FROM DealerManagement.DEALERS_JLRCSP_Appointments
	WHERE IP_ProcessedDate IS NULL
	AND IP_DataValidated = 1;