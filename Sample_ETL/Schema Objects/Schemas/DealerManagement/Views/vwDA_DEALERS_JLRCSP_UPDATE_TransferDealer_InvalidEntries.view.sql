CREATE VIEW [DealerManagement].[vwDA_DEALERS_JLRCSP_UPDATE_TransferDealer_InvalidEntries]

AS

	-- Purpose: Data Access view to display/enable invalid entries into the dealer transfer change table to be 
	--			removed and then re-inserted.
	--
	--
	-- Version		Developer			Date			Comment
	-- 1.0			Martin Riverol		14/05/2012		Created

	SELECT 
		IP_TransferDealerChangeID
		, ID
		, OutletFunction
		, Manufacturer
		, Market
		, OutletCode
		, IP_OutletPartyID
		, TransferOutletCode
		, IP_TransferOutlet
		, IP_TransferOutletPartyID
		, IP_SystemUser
		, IP_DataValidated
		, IP_ValidationFailureReasons
	FROM DealerManagement.DEALERS_JLRCSP_UPDATE_TransferDealer
	WHERE IP_ProcessedDate IS NULL
	AND IP_DataValidated = 0