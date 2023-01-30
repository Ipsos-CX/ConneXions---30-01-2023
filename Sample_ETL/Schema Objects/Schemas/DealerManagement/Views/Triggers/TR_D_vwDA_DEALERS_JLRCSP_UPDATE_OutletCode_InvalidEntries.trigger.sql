CREATE TRIGGER [DealerManagement].[TR_D_vwDA_DEALERS_JLRCSP_UPDATE_OutletCode_InvalidEntries] ON  [DealerManagement].[vwDA_DEALERS_JLRCSP_UPDATE_OutletCode_InvalidEntries]
INSTEAD OF DELETE

AS 

	--	Purpose:	Delete invalid rows only from Dealer code change table
	--
	--
	--	Version			Developer			Date			Comment
	--	1.0				Martin Riverol		10/05/2012		Created
	
	-- DISVBLE COUNTS
	SET NOCOUNT ON

	-- ROLLBACK ON ERROR
	SET XACT_ABORT ON
	
	-- DELETE ENTRIES
	
	BEGIN TRAN
	
		DELETE FROM DealerManagement.DEALERS_JLRCSP_UPDATE_OutletCode
		WHERE IP_OutletCodeChangeID IN (SELECT IP_OutletCodeChangeID FROM deleted)
	
	COMMIT TRAN