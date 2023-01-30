CREATE VIEW [DealerManagement].[vwDA_DEALERS_JLRCSP_UPDATE_Dealer10DigitCode]

AS
	SELECT 
			OutletFunction
			, Manufacturer
			, Market
			, OutletCode
			, Dealer10DigitCode
			, IP_SystemUser
	
	FROM	DealerManagement.DEALERS_JLRCSP_UPDATE_Dealer10DigitCode
	WHERE	IP_ProcessedDate IS NULL