
CREATE PROCEDURE [OWAPv2].[uspDeleteFromInviteMatrix]
	
	@Brand  NVARCHAR(510), @Market VARCHAR(200), @Questionnaire VARCHAR(100), @EmailLanguage VARCHAR(100), @RowCount INT=0 OUTPUT, @ErrorCode INT=0 OUTPUT, @RecordRemoved BIT =0 OUTPUT

AS

/*
Description
-----------
Add Signatory record into the Invite Matrix 

Version		Date		Author			Why
------------------------------------------------------------------------------------------------------
1.0			07-11-2017	Ben King		BUG 14154
1.1			20-01-2020	Chris Ledger	Bug 15372 - Fix database references

*/
	--Disable Counts
	SET NOCOUNT ON

	DECLARE @ErrorNumber INT
	DECLARE @ErrorSeverity INT
	DECLARE @ErrorState INT
	DECLARE @ErrorLocation NVARCHAR(500)
	DECLARE @ErrorLine INT
	DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY
		
					BEGIN
					DELETE FROM SelectionOutput.OnlineEmailContactDetails 
					WHERE  Brand = LTRIM(RTRIM(@Brand))
					AND	   Market = LTRIM(RTRIM(@Market))
					AND    Questionnaire = LTRIM(RTRIM(@Questionnaire))
					AND    EmailLanguage = 	LTRIM(RTRIM(@EmailLanguage))
																		
					--Record successfully removed
					SELECT @RecordRemoved  = CAST(1 AS BIT)
					
					END


	--Get the Error Code for the statement just executed.
	SELECT 
		@RowCount = @@ROWCOUNT,
		@ErrorCode = @@ERROR

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
		
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH
GO