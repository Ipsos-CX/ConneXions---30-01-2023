CREATE PROCEDURE [OWAPv2].[uspUpdateDealerLevelInviteMatrix]
	
	@InviteMatrixDealerLevelID	INT, 
	@DealerID					INT,
	@BrandID					INT, 
	@CountryID					INT,
	@QuestionnaireID			INT, 
	@LanguageID					INT,
	@JLRCompany					NVARCHAR(200) ='', 
	@EmailSignator				NVARCHAR(500), 
	@EmailSignatorTitle			NVARCHAR(500), 
	@EmailContactText			NVARCHAR(2000), 
	@EmailCompanyDetails		NVARCHAR(2000), 
	@JLRPrivacyPolicy			NVARCHAR(2000),

	@RowCount					INT=0 OUTPUT, 
	@ErrorCode					INT=0 OUTPUT, 
	@RecordUpdated				BIT=0 OUTPUT
	
	AS

	/*
	Description
	-----------
	Update Signatory record into the Invite Matrix 

	Version		Date		Author			Why
	------------------------------------------------------------------------------------------------------
	1.0			02-07-2018	Eddie Thomas	Created
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


	IF  NOT EXISTS (	SELECT	cdd.InviteMatrixDealerLevelID
						FROM		SelectionOutput.OnlineEmailContactDealerDetails cdd
						WHERE		cdd.DealerPartyID		= @DealerID AND
									cdd.BrandID				= @BrandID AND 
									cdd.CountryID			= @CountryID AND 
									cdd.QuestionnaireID		= @QuestionnaireID AND 
									cdd.LanguageID			= @LanguageID AND 
									cdd.InviteMatrixDealerLevelID <> @InviteMatrixDealerLevelID
							
					)		


					BEGIN
			
						UPDATE		cdd
						SET			cdd.DealerPartyID		= @DealerID,
									cdd.BrandID				= @BrandID,
									cdd.CountryID			= @CountryID,
									cdd.QuestionnaireID		= @QuestionnaireID,
									cdd.LanguageID			= @LanguageID,
									cdd.JLRCompanyname		= @JLRCompany,
									cdd.EmailSignator		= LTRIM(RTRIM(@EmailSignator)), 
									cdd.EmailSignatorTitle	= LTRIM(RTRIM(@EmailSignatorTitle)), 
									cdd.EmailContactText	= LTRIM(RTRIM(@EmailContactText)), 
									cdd.EmailCompanyDetails	= LTRIM(RTRIM(@EmailCompanyDetails)),
									cdd.JLRPrivacyPolicy	= LTRIM(RTRIM(@JLRPrivacyPolicy))
						FROM		SelectionOutput.OnlineEmailContactDealerDetails cdd

						WHERE		cdd.InviteMatrixDealerLevelID= @InviteMatrixDealerLevelID


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
