
CREATE PROCEDURE [OWAPv2].[uspInsertIntoInviteMatrixV2]
	
	@Brand  NVARCHAR(510), @Market VARCHAR(200), @Questionnaire VARCHAR(100), @EmailLanguage VARCHAR(100), @RowCount INT=0 OUTPUT, @ErrorCode INT=0 OUTPUT, @RecordAdded BIT =0 OUTPUT

AS

/*
Description
-----------
Add Brand, Market, Questionnaire and Language to Invite Matrix

Version		Date		Author			Why
------------------------------------------------------------------------------------------------------
1.0			07-11-2017	Ben King    	BUG 14154
1.1			21-01-2020	Chris Ledger	BUG 15372: Fix Hard coded references to databases.

*/
	--Disable Counts
	SET NOCOUNT ON

	DECLARE @ErrorNumber INT
	DECLARE @ErrorSeverity INT
	DECLARE @ErrorState INT
	DECLARE @ErrorLocation NVARCHAR(500)
	DECLARE @ErrorLine INT
	DECLARE @ErrorMessage NVARCHAR(2048)

	--Set these to blank as table has NOT NULL constraint
	DECLARE @EmailSignatorTitle NVARCHAR(500) = ''
	DECLARE @EmailContactText NVARCHAR(2000) = ''
	DECLARE @EmailCompanyDetails  NVARCHAR(2000) = ''

BEGIN TRY

	IF NOT EXISTS ( SELECT * FROM SelectionOutput.OnlineEmailContactDetails
					WHERE	Brand = LTRIM(RTRIM(@Brand)) AND 
							Market =  LTRIM(RTRIM(@Market)) AND 			
							Questionnaire =  LTRIM(RTRIM(@Questionnaire)) AND 
							EmailLanguage =  LTRIM(RTRIM(@EmailLanguage))
					)		
					BEGIN
					INSERT SelectionOutput.OnlineEmailContactDetails (	Brand, 
																		Market, 
																		Questionnaire, 
																		EmailLanguage,
																		EmailSignatorTitle,
																		EmailContactText,
																		EmailCompanyDetails)
																		
					VALUES	(
								LTRIM(RTRIM(@Brand)), 
								LTRIM(RTRIM(@Market)),
								LTRIM(RTRIM(@Questionnaire)),
								LTRIM(RTRIM(@EmailLanguage)),
								@EmailSignatorTitle,
								@EmailContactText,
								@EmailCompanyDetails
							)

					--Record successfully added
					SELECT @RecordAdded  = CAST(1 AS BIT)
					
					END
	
	ELSE
	BEGIN
	RAISERROR(	N'Combination Brand, Market, Questionnaire and Language already exists', 
						16,
						1
					 )
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
