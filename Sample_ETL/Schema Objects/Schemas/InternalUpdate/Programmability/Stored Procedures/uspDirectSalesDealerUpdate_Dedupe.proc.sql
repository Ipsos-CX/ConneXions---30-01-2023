CREATE PROCEDURE [InternalUpdate].[uspDirectSalesDealerUpdate_Dedupe]
	AS
SET NOCOUNT ON

	DECLARE @ErrorNumber INT
	DECLARE @ErrorSeverity INT
	DECLARE @ErrorState INT
	DECLARE @ErrorLocation NVARCHAR(500)
	DECLARE @ErrorLine INT
	DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	UPDATE	du
	SET		du.ParentAuditItemID = M.ParentAuditItemID
	FROM	InternalUpdate.DirectSalesDealerUpdate du
	INNER JOIN (
		SELECT
				MAX(AuditItemID) AS ParentAuditItemID, [MatchedODSVehicleID], [MatchedODSEventID]
		FROM	InternalUpdate.DirectSalesDealerUpdate
		GROUP BY [MatchedODSVehicleID], [MatchedODSEventID]
	) M ON M.[MatchedODSVehicleID] = du.[MatchedODSVehicleID] AND M.[MatchedODSEventID] = du.[MatchedODSEventID]


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

