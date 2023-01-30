CREATE VIEW [DealerManagement].[vwDA_DEALERS_JLRCSP_UPDATE_OutletCode]

AS


	--	Purpose:	Data access view to add data to DealerManagement.DEALERS_JLRCSP_UPDATE_OutletCode to enable dealer code changes
	--				
	--	Version		Date			Developer			Comment
	--	1.0			10/05/2012		Martin Riverol		Created
	

		SELECT DISTINCT
			OutletFunction
			, Manufacturer
			, Market
			, OutletCode
			, NewOutletCode
			, IP_SystemUser
		FROM DealerManagement.DEALERS_JLRCSP_UPDATE_OutletCode
		WHERE IP_ProcessedDate IS NULL