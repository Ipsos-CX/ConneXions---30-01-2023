CREATE TRIGGER [DealerManagement].[TR_D_vwDA_DEALERS_JLRCSP_Appointments_InvalidEntries] ON  [DealerManagement].[vwDA_DEALERS_JLRCSP_Appointments_InvalidEntries]
INSTEAD OF DELETE

AS 

	--	Purpose:	Populate the Dealer Appointment table checking the source columns to ensure that they comply
	--
	--	Version			Developer			Date			Comment
	--	1.0				Martin Riverol		23/04/2012		Created
	--
	--
	
	-- DISVBLE COUNTS
	SET NOCOUNT ON

	-- ROLLBACK ON ERROR
	SET XACT_ABORT ON
	
	-- DELETE ENTRIES
	
	BEGIN TRAN
	
		DELETE FROM DealerManagement.DEALERS_JLRCSP_Appointments
		WHERE IP_DealerAppointmentID IN (SELECT IP_DealerAppointmentID FROM deleted)
	
	COMMIT TRAN