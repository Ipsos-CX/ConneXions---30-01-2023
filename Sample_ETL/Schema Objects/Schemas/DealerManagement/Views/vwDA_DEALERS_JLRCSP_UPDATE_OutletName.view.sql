CREATE VIEW [DealerManagement].[vwDA_DEALERS_JLRCSP_UPDATE_OutletName]

AS

	-- Purpose: Data Access view to enable inserts into Dealer name change table
	--
	--
	-- Version		Developer			Date			Comment
	-- 1.0			Martin Riverol		09/05/2012		Created

	SELECT 
		OutletFunction
		, Manufacturer
		, Market
		, OutletCode
		, OutletName
		, OutletName_Short
		, OutletName_NativeLanguage
		, IP_SystemUser
	FROM DealerManagement.DEALERS_JLRCSP_UPDATE_OutletName
	WHERE IP_ProcessedDate IS NULL