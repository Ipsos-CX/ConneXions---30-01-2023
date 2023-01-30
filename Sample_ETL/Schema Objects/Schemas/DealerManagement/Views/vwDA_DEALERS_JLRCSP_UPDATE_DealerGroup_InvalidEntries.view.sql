CREATE VIEW [DealerManagement].[vwDA_DEALERS_JLRCSP_UPDATE_DealerGroup_InvalidEntries]

AS

	-- Purpose: Data Access view to display/enable invalid entries into the dealer group change table to be 
	--			removed and then re-inserted.
	--
	--
	-- Version		Developer			Date			Comment
	-- 1.0			Martin Riverol		11/05/2012		Created

	SELECT 
		IP_DealerGroupChangeID
		, ID
		, OutletFunction
		, Manufacturer
		, Market
		, IP_OutletPartyID
		, OutletCode
		, DealerGroup
		, NewDealerGroup
		, IP_SystemUser
		, IP_DataValidated
		, IP_ValidationFailureReasons
	FROM DealerManagement.DEALERS_JLRCSP_UPDATE_DealerGroup
	WHERE IP_ProcessedDate IS NULL
	AND IP_DataValidated = 0