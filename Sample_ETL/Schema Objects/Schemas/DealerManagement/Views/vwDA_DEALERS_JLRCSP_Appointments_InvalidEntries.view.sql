CREATE VIEW [DealerManagement].[vwDA_DEALERS_JLRCSP_Appointments_InvalidEntries]

AS

	-- Purpose: Data Access view to display/enable invalid entries into the Dealer Appointments table to be 
	--			removed and then re-inserted.
	--
	--
	-- Version		Developer			Date			Comment
	-- 1.0			Martin Riverol		23/04/2012		Created
	-- 1.1			Eddie Thomas		10/09/2014		Added PAG Code
	-- 1.2			Chris Ross			26/02/2015		BUG 11026 - Add in BusinessRegion column#
	-- 1.3			Chris Ross			16/01/2017		BUG 13171 - Add in SubNationalTerritory column
	-- 1.4			Chris Ledger		13/11/2017		BUG 14365 - Add in SVODealer & FleetDealer
	-- 1.5			Chris Ledger		17/01/2020		BUG 16793 - Added Dealer10DigitCode


	SELECT 
		Functions
		, Manufacturer
		, SuperNationalRegion
		, BusinessRegion						-- v1.2
		, Market
		, SubNationalTerritory					-- v1.3
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
		, SVODealer							-- V1.4
		, FleetDealer						-- V1.4
		, Dealer10DigitCode					-- V1.5
		, IP_SystemUser
		, IP_DataValidated
		, IP_ValidationFailureReasons
	FROM DealerManagement.DEALERS_JLRCSP_Appointments
	WHERE IP_ProcessedDate IS NULL
	AND IP_DataValidated = 0