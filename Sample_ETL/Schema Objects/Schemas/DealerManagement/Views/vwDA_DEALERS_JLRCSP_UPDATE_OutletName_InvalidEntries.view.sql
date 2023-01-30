CREATE VIEW [DealerManagement].[vwDA_DEALERS_JLRCSP_UPDATE_OutletName_InvalidEntries]

AS

	-- Purpose: Data Access view to display/enable invalid entries into the outlet name change table to be 
	--			removed and then re-inserted.
	--
	--
	-- Version		Developer			Date			Comment
	-- 1.0			Martin Riverol		09/05/2012		Created

	SELECT 
		IP_OutletNameChangeID
		, ID
		, OutletFunction
		, Manufacturer
		, Market
		, OutletCode
		, IP_OutletPartyID
		, OutletName
		, OutletName_Short
		, OutletName_NativeLanguage
		, IP_SystemUser
		, IP_DataValidated
		, IP_ValidationFailureReasons
	FROM DealerManagement.DEALERS_JLRCSP_UPDATE_OutletName
	WHERE IP_ProcessedDate IS NULL
	AND IP_DataValidated = 0