CREATE VIEW [DealerManagement].[vwDA_DEALERS_JLRCSP_UPDATE_SubNationalTerritory_InvalidEntries]

AS

	-- Purpose: Data Access view to display/enable invalid entries into the Sub-nationalTerritory change table to be 
	--			removed and then re-inserted.
	--
	--
	-- Version		Developer			Date			Comment
	-- 1.0			Chris Ross			12/10/2016		Created (copied from Sub-National Region view)

	SELECT 
		IP_SubNationalTerritoryChangeID
		, ID
		, OutletFunction
		, Manufacturer
		, Market
		, IP_OutletPartyID
		, OutletCode
		, SubNationalTerritory
		, NewSubNationalTerritory
		, NewSubNationalRegion
		, IP_SystemUser
		, IP_DataValidated
		, IP_ValidationFailureReasons
	FROM DealerManagement.DEALERS_JLRCSP_UPDATE_SubNationalTerritory
	WHERE IP_ProcessedDate IS NULL
	AND IP_DataValidated = 0
	
	