CREATE PROCEDURE [OWAPv2].[uspInsertDealerLevelInviteMatrix]
	
	@DealerID				INT,
	@BrandID				INT, 
	@CountryID				INT,
	@QuestionnaireID		INT, 
	@LanguageID				INT,
	@JLRCompany				NVARCHAR(200) ='', 
	@EmailSignator			NVARCHAR(500), 
	@EmailSignatorTitle		NVARCHAR(500), 
	@EmailContactText		NVARCHAR(2000), 
	@EmailCompanyDetails	NVARCHAR(2000), 
	@JLRPrivacyPolicy		NVARCHAR(2000),

	@RowCount				INT=0 OUTPUT, 
	@ErrorCode				INT=0 OUTPUT, 
	@RecordUpdated			BIT =0 OUTPUT
	
	AS

	/*
	Description
	-----------
	Insert Signatory record into the Dealer level Invite Matrix 

	Version		Date		Author			Why
	------------------------------------------------------------------------------------------------------
	1.0			02-07-2018	Eddie Thomas	Created
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

BEGIN TRY


	IF  NOT EXISTS (	SELECT	cdd.InviteMatrixDealerLevelID
						FROM	SelectionOutput.OnlineEmailContactDealerDetails cdd
						WHERE	cdd.DealerPartyID		= @DealerID AND
								cdd.BrandID				= @BrandID AND 
								cdd.CountryID			= @CountryID AND 
								cdd.QuestionnaireID		= @QuestionnaireID AND 
								cdd.LanguageID			= @LanguageID  
					)		


					BEGIN
			
						INSERT SelectionOutput.OnlineEmailContactDealerDetails
						(
							DealerPartyID,
							BrandID,
							CountryID,
							QuestionnaireID,
							LanguageID,
							JLRCompanyname,
							EmailSignator, 
							EmailSignatorTitle, 
							EmailContactText, 
							EmailCompanyDetails,
							JLRPrivacyPolicy
						)
						VALUES
						(
							@DealerID,
							@BrandID,
							@CountryID,
							@QuestionnaireID,
							@LanguageID,
							@JLRCompany,
							@EmailSignator,
							@EmailSignatorTitle,
							@EmailContactText,
							@EmailCompanyDetails,
							@JLRPrivacyPolicy
						)

						--Records successfully added
						SELECT @RecordUpdated  = CAST(1 AS BIT)

					END
	
	--Get the Error Code for the statement just executed.
	SELECT 
		@RowCount = @@ROWCOUNT,
		@ErrorCode = ISNULL(@@ERROR,0)

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
