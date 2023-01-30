CREATE PROCEDURE [OWAPv2].[uspInserIntoInviteMatrix]

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
	@RecordAdded			BIT=0 OUTPUT

AS

	/*
	Description
	-----------
	Add Signatory record into the Invite Matrix 

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

	IF NOT EXISTS ( SELECT * FROM SelectionOutput.OnlineEmailContactDetails
					WHERE	Brand = LTRIM(RTRIM(@Brand)) AND 
							Market =  LTRIM(RTRIM(@Market)) AND 
							JLRCompanyname	=  LTRIM(RTRIM(@JLRCompany)) AND 			
							Questionnaire	=  LTRIM(RTRIM(@Questionnaire)) AND 
							EmailLanguage	=  LTRIM(RTRIM(@EmailLanguage))
					)		
					BEGIN
					INSERT SelectionOutput.OnlineEmailContactDetails (	Brand, 
																		Market, 
																		JLRCompanyname, 
																		Questionnaire, 
																		EmailLanguage, 
																		EmailSignator, 
																		EmailSignatorTitle, 
																		EmailContactText, 
																		EmailCompanyDetails,
																		JLRPrivacyPolicy
																	 )

					VALUES	(
								LTRIM(RTRIM(@Brand)), 
								LTRIM(RTRIM(@Market)),
								LTRIM(RTRIM(@JLRCompany)),
								LTRIM(RTRIM(@Questionnaire)),
								LTRIM(RTRIM(@EmailLanguage)),
								LTRIM(RTRIM(@EmailSignator)),
								LTRIM(RTRIM(@EmailSignatorTitle)),
								LTRIM(RTRIM(@EmailContactText)),
								LTRIM(RTRIM(@EmailCompanyDetails)),
								LTRIM(RTRIM(@JLRPrivacyPolicy))
							)

					--Record successfully added
					SELECT @RecordAdded  = CAST(1 AS BIT)
					
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