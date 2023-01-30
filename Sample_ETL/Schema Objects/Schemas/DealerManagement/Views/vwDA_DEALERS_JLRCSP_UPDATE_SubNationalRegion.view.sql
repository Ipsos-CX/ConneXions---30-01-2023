CREATE VIEW [DealerManagement].[vwDA_DEALERS_JLRCSP_UPDATE_SubNationalRegion]

AS

	-- Purpose: Data Access view to enable inserts into Dealer Sub-national region change table
	--
	--
	-- Version		Developer			Date			Comment
	-- 1.0			Martin Riverol		11/05/2012		Created

	SELECT 
		OutletFunction
		, Manufacturer
		, Market
		, OutletCode
		, SubNationalRegion
		, NewSubNationalRegion
		, IP_SystemUser
	FROM DealerManagement.DEALERS_JLRCSP_UPDATE_SubNationalRegion
	WHERE IP_ProcessedDate IS NULL