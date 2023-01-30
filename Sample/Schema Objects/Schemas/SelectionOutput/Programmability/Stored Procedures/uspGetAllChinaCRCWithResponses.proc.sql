/*
	Description: Gets All Bodyshop Re-output. Called by: Selection Output.dtsx

	Version		Created			Author			History		
	-------		-------			------			-------			
	1.0			16-03-2018		Eddie Thomas	Original version.  BUG 14557 - China CRC With Responses
	1.1			10-04-2018		Eddie Thomas	Rewritten to repliceate the original source file
*/
CREATE PROCEDURE [SelectionOutput].[uspGetAllChinaCRCWithResponses]
AS
DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	DECLARE @NOW	DATETIME

	SET		@NOW = GETDATE()

	SELECT DISTINCT
	RWR.* 
    FROM    SelectionOutput.OnlineOutput AS O
	INNER JOIN	Sample_ETL.China.CRC_WithResponses RWR ON O.ID = RWR.CaseID

END TRY
BEGIN CATCH

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
		
	IF @@TRANCOUNT > 0
	BEGIN
		ROLLBACK TRAN
	END
	
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH