CREATE PROCEDURE [OWAPv2].[uspUpdateInviteMatrix]
	@ID						INT, 
	@Brand					NVARCHAR(510), 
	@Market					VARCHAR(200), 
	@JLRCompany				NVARCHAR(200) ='', 
	@Questionnaire			VARCHAR(100), 
	@EmailLanguage			VARCHAR(100), 
	@EmailSignator			NVARCHAR(500), 
	@EmailSignatorTitle		NVARCHAR(500), 
	@EmailContactText		NVARCHAR(2000), 
	@EmailCompanyDetails	NVARCHAR(2000),
	@JLRPrivacyPolicy		NVARCHAR(2000), 
	@RowCount				INT=0 OUTPUT, 
	@ErrorCode				INT=0 OUTPUT, 
	@RecordUpdated			BIT=0 OUTPUT

	AS


	/*
	Description
	-----------
	Update Signatory record into the Invite Matrix 

	Version		Date		Author			Why
	------------------------------------------------------------------------------------------------------
	1.0			29-11-2016	Eddie Thomas	Created
	1.1			27-01-2017	Eddie Thomas	Dealer parameter replaced with JLRCompanyName
	1.2			12-07-2018	Eddie Thomas	Added @JLRPrivacyPolicy
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


	IF  NOT EXISTS ( SELECT * FROM SelectionOutput.OnlineEmailContactDetails
					WHERE	Brand = LTRIM(RTRIM(@Brand)) AND 
							Market =  LTRIM(RTRIM(@Market)) AND 
							JLRcompanyName =  LTRIM(RTRIM(@JLRCompany)) AND 			
							Questionnaire =  LTRIM(RTRIM(@Questionnaire)) AND 
							EmailLanguage =  LTRIM(RTRIM(@EmailLanguage)) AND
							ID <> @ID
					)		
					BEGIN

					UPDATE	SelectionOutput.OnlineEmailContactDetails 
					
					SET Brand				= LTRIM(RTRIM(@Brand)), 
						Market				= LTRIM(RTRIM(@Market)), 
						JLRcompanyName		= LTRIM(RTRIM(@JLRCompany)), 
						Questionnaire		= LTRIM(RTRIM(@Questionnaire)), 
						EmailLanguage		= LTRIM(RTRIM(@EmailLanguage)), 
						EmailSignator		= LTRIM(RTRIM(@EmailSignator)), 
						EmailSignatorTitle	= LTRIM(RTRIM(@EmailSignatorTitle)), 
						EmailContactText	= LTRIM(RTRIM(@EmailContactText)), 
						EmailCompanyDetails	= LTRIM(RTRIM(@EmailCompanyDetails)),
						JLRPrivacyPolicy	= LTRIM(RTRIM(@JLRPrivacyPolicy))
					WHERE ID = @ID

			
					--Record successfully added
					SELECT @RecordUpdated  = CAST(1 AS BIT)
					
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

