CREATE TRIGGER LostLeads.TR_I_CaseLostLeadStatuses ON LostLeads.CaseLostLeadStatuses
AFTER INSERT

AS

/*
	Purpose:	Creates an ExtrenalEventID for each newly added EventId. This is used in the output to make the LostLeadID (CustomerID) unique.
	
	Version			Date			Developer			Comment
	1.0				09-04-2018		Chris Ross			Created as part of BUG 14413.

*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	BEGIN TRAN

		-- Add any new events into the ExternalID table
		INSERT INTO LostLeads.ExternalEventID (EventID)
		SELECT DISTINCT EventID
		FROM INSERTED i
		WHERE NOT EXISTS (SELECT eei.EventID 
						  FROM LostLeads.ExternalEventID eei
						  WHERE i.EventID = eei.EventID)



	COMMIT TRAN

END TRY
BEGIN CATCH

	IF @@TRANCOUNT > 0
	BEGIN
		ROLLBACK TRAN
	END

	SELECT
		 @ErrorNumber = Error_Number()
		,@ErrorSeverity = Error_Severity()
		,@ErrorState = Error_State()
		,@ErrorLocation = Error_Procedure()
		,@ErrorLine = Error_Line()
		,@ErrorMessage = Error_Message()

	EXEC [$(ErrorDB)].dbo.uspLogDatabaseError
		 @ErrorNumber
		,@ErrorSeverity
		,@ErrorState
		,@ErrorLocation
		,@ErrorLine
		,@ErrorMessage
		
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH