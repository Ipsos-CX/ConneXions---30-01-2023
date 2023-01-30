CREATE VIEW [DealerManagement].[vwDA_DEALERS_JLRCSP_UPDATE_SubNationalRegion_InvalidEntries]

AS

	-- Purpose: Data Access view to display/enable invalid entries into the Sub-nationalRegion change table to be 
	--			removed and then re-inserted.
	--
	--
	-- Version		Developer			Date			Comment
	-- 1.0			Martin Riverol		11/05/2012		Created

	SELECT 
		IP_SubNationalRegionChangeID
		, ID
		, OutletFunction
		, Manufacturer
		, Market
		, IP_OutletPartyID
		, OutletCode
		, SubNationalRegion
		, NewSubNationalRegion
		, IP_SystemUser
		, IP_DataValidated
		, IP_ValidationFailureReasons
	FROM DealerManagement.DEALERS_JLRCSP_UPDATE_SubNationalRegion
	WHERE IP_ProcessedDate IS NULL
	AND IP_DataValidated = 0