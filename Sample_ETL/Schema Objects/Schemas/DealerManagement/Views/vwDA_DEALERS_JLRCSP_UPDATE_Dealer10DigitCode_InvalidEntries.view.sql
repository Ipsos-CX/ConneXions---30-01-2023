CREATE VIEW [DealerManagement].[vwDA_DEALERS_JLRCSP_UPDATE_Dealer10DigitCode_InvalidEntries]
AS
	SELECT 
			IP_Dealer10DigitCodeChangeID
			, ID
			, OutletFunction
			, Manufacturer
			, Market
			, IP_OutletPartyID
			, OutletCode
			, Dealer10DigitCode
			, IP_SystemUser
			, IP_DataValidated
			, IP_ValidationFailureReasons
	
	FROM	DealerManagement.DEALERS_JLRCSP_UPDATE_Dealer10DigitCode
	WHERE	IP_ProcessedDate IS NULL 
			AND IP_DataValidated = 0