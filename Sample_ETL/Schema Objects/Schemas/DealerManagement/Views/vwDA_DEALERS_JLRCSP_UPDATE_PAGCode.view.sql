CREATE VIEW [DealerManagement].[vwDA_DEALERS_JLRCSP_UPDATE_PAGCode]

AS
	SELECT 
			OutletFunction
			, Manufacturer
			, Market
			, OutletCode
			, PAGCode
			, PAGName
			, IP_SystemUser
	
	FROM	DealerManagement.DEALERS_JLRCSP_UPDATE_PAGCode
	WHERE	IP_ProcessedDate IS NULL