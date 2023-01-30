CREATE VIEW DealerManagement.vwDA_DEALERS_JLRCSP_UPDATE_OutletCode_InvalidEntries

AS

	-- Purpose: Data Access view to display/enable invalid entries into the outlet code change table to be 
	--			removed and then re-inserted.
	--
	--
	-- Version		Developer			Date			Comment
	-- 1.0			Martin Riverol		10/05/2012		Created

	SELECT 
		IP_OutletCodeChangeID
		, ID
		, OutletFunction
		, Manufacturer
		, Market
		, IP_OutletPartyID
		, OutletCode
		, NewOutletCode
		, IP_SystemUser
		, IP_DataValidated
		, IP_ValidationFailureReasons
	FROM DealerManagement.DEALERS_JLRCSP_UPDATE_OutletCode
	WHERE IP_ProcessedDate IS NULL
	AND IP_DataValidated = 0