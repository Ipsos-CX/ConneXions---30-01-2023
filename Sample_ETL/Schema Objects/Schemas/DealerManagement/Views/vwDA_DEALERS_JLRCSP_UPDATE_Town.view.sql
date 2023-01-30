CREATE VIEW [DealerManagement].[vwDA_DEALERS_JLRCSP_UPDATE_Town]

AS

	-- Purpose: Data Access view to enable inserts into Dealer Town change table
	--
	--
	-- Version		Developer			Date			Comment
	-- 1.0			Martin Riverol		11/05/2012		Created

	SELECT 
		Manufacturer
		, Market
		, OutletCode
		, Town
		, NewTown
		, IP_SystemUser
	FROM DealerManagement.DEALERS_JLRCSP_UPDATE_Town
	WHERE IP_ProcessedDate IS NULL