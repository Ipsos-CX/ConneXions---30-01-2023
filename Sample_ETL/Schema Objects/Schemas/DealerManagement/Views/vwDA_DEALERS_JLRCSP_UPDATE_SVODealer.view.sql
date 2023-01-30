CREATE VIEW [DealerManagement].[vwDA_DEALERS_JLRCSP_UPDATE_SVODealer]

AS
	SELECT 
			OutletFunction
			, Manufacturer
			, Market
			, OutletCode
			, SVODealer
			, FleetDealer
			, IP_SystemUser
	
	FROM	DealerManagement.DEALERS_JLRCSP_UPDATE_SVODealer
	WHERE	IP_ProcessedDate IS NULL