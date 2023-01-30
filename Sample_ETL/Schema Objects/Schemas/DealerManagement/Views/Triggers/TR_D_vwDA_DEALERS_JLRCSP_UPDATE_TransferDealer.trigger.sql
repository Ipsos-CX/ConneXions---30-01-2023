CREATE TRIGGER [DealerManagement].[TR_D_vwDA_DEALERS_JLRCSP_UPDATE_TransferDealer] ON  [DealerManagement].[vwDA_DEALERS_JLRCSP_UPDATE_TransferDealer_InvalidEntries]
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
	
		DELETE FROM DealerManagement.vwDA_DEALERS_JLRCSP_UPDATE_TransferDealer_InvalidEntries
		WHERE IP_TransferDealerChangeID IN (SELECT IP_TransferDealerChangeID FROM deleted)
	
	COMMIT TRAN