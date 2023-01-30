CREATE VIEW [DealerManagement].[vwDA_DEALERS_JLRCSP_UPDATE_DealerGroup]

AS

	-- Purpose: Data Access view to enable inserts into DealerGroup change table
	--
	--
	-- Version		Developer			Date			Comment
	-- 1.0			Martin Riverol		11/05/2012		Created

	SELECT 
		OutletFunction
		, Manufacturer
		, Market
		, OutletCode
		, DealerGroup
		, NewDealerGroup
		, IP_SystemUser
	FROM DealerManagement.DEALERS_JLRCSP_UPDATE_DealerGroup
	WHERE IP_ProcessedDate IS NULL