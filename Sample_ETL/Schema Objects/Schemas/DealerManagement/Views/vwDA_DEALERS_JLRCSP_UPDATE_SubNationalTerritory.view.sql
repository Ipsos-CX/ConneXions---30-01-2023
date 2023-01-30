CREATE VIEW [DealerManagement].[vwDA_DEALERS_JLRCSP_UPDATE_SubNationalTerritory]

AS

	-- Purpose: Data Access view to enable inserts into Dealer Sub-national Territory change table
	--
	--
	-- Version		Developer			Date			Comment
	-- 1.0			Chris Ross			12/10/2016		Created (copied from Sub-National Region view)
	

	SELECT 
		OutletFunction
		, Manufacturer
		, Market
		, OutletCode
		, SubNationalTerritory
		, NewSubNationalTerritory
		, NewSubNationalRegion
		, IP_SystemUser
	FROM DealerManagement.DEALERS_JLRCSP_UPDATE_SubNationalTerritory
	WHERE IP_ProcessedDate IS NULL