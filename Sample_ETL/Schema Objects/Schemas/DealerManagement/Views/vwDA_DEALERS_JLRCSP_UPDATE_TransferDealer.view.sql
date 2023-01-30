CREATE VIEW [DealerManagement].[vwDA_DEALERS_JLRCSP_UPDATE_TransferDealer]

AS

	-- Purpose: Data Access view to enable inserts into update transfer dealer table
	--
	--
	-- Version		Developer			Date			Comment
	-- 1.0			Martin Riverol		14/05/2012		Created


	SELECT 
		OutletFunction
		, Manufacturer
		, Market
		, OutletCode
		, TransferOutletCode
		, IP_SystemUser
	FROM [DealerManagement].[DEALERS_JLRCSP_UPDATE_TransferDealer]
	WHERE IP_ProcessedDate IS NULL