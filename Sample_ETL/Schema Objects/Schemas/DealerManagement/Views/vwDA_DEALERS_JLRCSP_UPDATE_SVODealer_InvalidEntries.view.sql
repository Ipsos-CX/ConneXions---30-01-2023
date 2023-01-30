CREATE VIEW [DealerManagement].[vwDA_DEALERS_JLRCSP_UPDATE_SVODealer_InvalidEntries]
AS
	SELECT 
			IP_SVODealerChangeID
			, ID
			, OutletFunction
			, Manufacturer
			, Market
			, IP_OutletPartyID
			, OutletCode
			, SVODealer
			, FleetDealer
			, IP_SystemUser
			, IP_DataValidated
			, IP_ValidationFailureReasons
	
	FROM	DealerManagement.DEALERS_JLRCSP_UPDATE_SVODealer
	WHERE	IP_ProcessedDate IS NULL 
			AND IP_DataValidated = 0