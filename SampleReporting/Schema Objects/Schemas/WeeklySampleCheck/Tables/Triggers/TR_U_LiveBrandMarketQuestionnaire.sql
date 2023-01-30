CREATE TRIGGER [WeeklySampleCheck].[TR_U_LiveBrandMarketQuestionnaire]
    ON [WeeklySampleCheck].[LiveBrandMarketQuestionnaire]
    AFTER UPDATE
    AS SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	BEGIN TRAN

	IF UPDATE (MedianDaily) 
    BEGIN
        UPDATE M
        SET M.MedianDailyFromDate = GETDATE()
		FROM [WeeklySampleCheck].[LiveBrandMarketQuestionnaire] M
		INNER JOIN Inserted I ON M.Brand = I.Brand			
							 AND M.Questionnaire = I.Questionnaire
							 AND M.market = I.Market
    END 

	IF UPDATE (MedianWeekly) 
    BEGIN
        UPDATE M
        SET M.MedianWeeklyFromDate = GETDATE()
		FROM [WeeklySampleCheck].[LiveBrandMarketQuestionnaire] M
		INNER JOIN Inserted I ON M.Brand = I.Brand			
							 AND M.Questionnaire = I.Questionnaire
							 AND M.market = I.Market
    END 

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
GO

ALTER TABLE [WeeklySampleCheck].[LiveBrandMarketQuestionnaire] ENABLE TRIGGER [TR_U_LiveBrandMarketQuestionnaire]
GO