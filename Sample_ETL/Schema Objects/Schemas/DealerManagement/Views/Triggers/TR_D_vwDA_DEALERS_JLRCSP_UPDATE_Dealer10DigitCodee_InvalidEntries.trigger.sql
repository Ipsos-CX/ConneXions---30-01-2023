CREATE TRIGGER [DealerManagement].[TR_D_vwDA_DEALERS_JLRCSP_UPDATE_Dealer10DigitCode_InvalidEntries] 
ON	[DealerManagement].[vwDA_DEALERS_JLRCSP_UPDATE_Dealer10DigitCode_InvalidEntries]
	INSTEAD OF DELETE
	AS SET NOCOUNT ON

	-- ROLLBACK ON ERROR
	SET XACT_ABORT ON
	
	-- DELETE ENTRIES
	
	BEGIN TRAN
	
		DELETE FROM DealerManagement.vwDA_DEALERS_JLRCSP_UPDATE_Dealer10DigitCode_InvalidEntries
		WHERE IP_Dealer10DigitCodeChangeID IN (SELECT IP_Dealer10DigitCodeChangeID FROM deleted)
	
	COMMIT TRAN