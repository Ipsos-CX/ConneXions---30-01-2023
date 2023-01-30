CREATE PROCEDURE [SelectionOutput].[uspUpdateAdhocSelectionStatus]

@ReqID INT

AS
SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

BEGIN TRAN
	
		DECLARE @Date DATETIME
		SET @Date = GETDATE()

		UPDATE	Requirement.AdhocSelectionRequirements
		SET		SelectionStatusTypeID = (
											SELECT	SelectionStatusTypeID 
											FROM	Requirement.SelectionStatusTypes 
											WHERE	SelectionStatusType = 'Outputted'
										),
				DateOutput	= @Date

		WHERE	REQUIREMENTID = @ReqID


		DELETE  SelectionOutput.AdhocSelection_OnlineOutput
		WHERE	REQUIREMENTID = @ReqID


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
