CREATE TRIGGER [DealerManagement].[TR_D_vwDA_DEALERS_JLRCSP_UPDATE_SubNationalTerritory_InvalidEntries] 
ON  [DealerManagement].[vwDA_DEALERS_JLRCSP_UPDATE_SubNationalTerritory_InvalidEntries]
INSTEAD OF DELETE

AS 

	--	Purpose:	Delete invalid rows only from Sub-national Region code change table
	--
	--
	--	Version			Developer			Date			Comment
	--	1.0				12/10/2016			Chris Ross		Created (copied from SubNationRegion)

	
	-- DISVBLE COUNTS
	SET NOCOUNT ON

	-- ROLLBACK ON ERROR
	SET XACT_ABORT ON
	
	-- DELETE ENTRIES
	
	BEGIN TRAN
	
		DELETE FROM DealerManagement.vwDA_DEALERS_JLRCSP_UPDATE_SubNationalTerritory_InvalidEntries
		WHERE IP_SubNationalTerritoryChangeID IN (SELECT IP_SubNationalTerritoryChangeID FROM deleted)
	
	COMMIT TRAN