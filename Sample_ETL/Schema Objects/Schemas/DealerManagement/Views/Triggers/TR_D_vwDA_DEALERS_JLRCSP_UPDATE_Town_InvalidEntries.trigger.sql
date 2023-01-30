CREATE TRIGGER [DealerManagement].[TR_D_vwDA_DEALERS_JLRCSP_UPDATE_Town_InvalidEntries] ON  [DealerManagement].[vwDA_DEALERS_JLRCSP_UPDATE_Town_InvalidEntries]
INSTEAD OF DELETE

AS 

	--	Purpose:	Delete invalid rows only from Dealer town change table
	--
	--
	--	Version			Developer			Date			Comment
	--	1.0				Martin Riverol		14/05/2012		Created
	
	-- DISVBLE COUNTS
	SET NOCOUNT ON

	-- ROLLBACK ON ERROR
	SET XACT_ABORT ON
	
	-- DELETE ENTRIES
	
	BEGIN TRAN
	
		DELETE FROM DealerManagement.vwDA_DEALERS_JLRCSP_UPDATE_Town_InvalidEntries
		WHERE IP_TownChangeID IN (SELECT IP_TownChangeID FROM deleted)
	
	COMMIT TRAN