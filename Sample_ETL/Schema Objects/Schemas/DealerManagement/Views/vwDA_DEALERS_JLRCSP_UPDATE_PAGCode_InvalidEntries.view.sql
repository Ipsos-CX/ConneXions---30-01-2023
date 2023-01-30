CREATE VIEW [DealerManagement].[vwDA_DEALERS_JLRCSP_UPDATE_PAGCode_InvalidEntries]
AS
	SELECT 
			IP_PAGCodeChangeID
			, ID
			, OutletFunction
			, Manufacturer
			, Market
			, IP_OutletPartyID
			, OutletCode
			, PAGCode
			, PAGName
			, IP_SystemUser
			, IP_DataValidated
			, IP_ValidationFailureReasons
	
	FROM	DealerManagement.DEALERS_JLRCSP_UPDATE_PAGCode
	WHERE	IP_ProcessedDate IS NULL 
			AND IP_DataValidated = 0