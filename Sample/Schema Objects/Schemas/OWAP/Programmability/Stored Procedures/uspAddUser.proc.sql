CREATE  PROCEDURE [OWAP].[uspAddUser]
(
	@AuditID BIGINT = 0,
	@SessionID NVARCHAR(100),
	@SourcePartyID INT = 0,
	@UserRoleTypeID SMALLINT,
	@UserName NVARCHAR(50),
	@Password NVARCHAR(255),
	@TitleID TINYINT = 34, --no title information,
	@FirstName NVARCHAR(255) = N'',
	@MiddleName NVARCHAR(255) = N'',
	@LastName NVARCHAR(255) = N'',
	@SecondLastName NVARCHAR(255) = N'',
	@GenderID TINYINT = 0, --unknown,
	@ErrorCode INT = 0 OUTPUT
)
AS
/*
Description
-----------

Version		Date		Aurthor		Why
------------------------------------------------------------------------------------------------------
1.0		24/11/2003	Mark Davidson	Created

Parameters
-----------
@SessionID

@SourcePartyID: The source of the information. In this instance the ID of the operator is probably sufficient
@SecurityRole:	The Security Role of the Operator
@UserID INT Person PartyID of user to be added
If supplied, then no need to create new person just add appropriate role
@UserRoleTypeID Specific role to add user to
@UserName User name to be used to authenticate user
@Password Password to be used to authenticate user
@TitleID ID of PreNominalTitles i.e. Mr, Mrs, Signor
@FirstName 
@MiddleName 
@LastName 
@SecondLastName i.e. in Spain
@PostNominalTitleID
ID of PostNominalTitles i.e. MSc, MP, OBE
@GenderID TINYINT
ID of Genders
@ErrorCode
*/
	--
	-- Disable Counts
	--
	SET NOCOUNT ON
	--
	-- Rollback on error
	--
	SET XACT_ABORT ON
	--
	-- Validate parameters
	--
	--	Declare local variables
	--
	DECLARE @ErrorNumber INT
	DECLARE @ErrorSeverity INT
	DECLARE @ErrorState INT
	DECLARE @ErrorLocation NVARCHAR(500)
	DECLARE @ErrorLine INT
	DECLARE @ErrorMessage NVARCHAR(2048)

	DECLARE @AuditItemID INT
	DECLARE @RoleTypeID SMALLINT
	DECLARE @UserID INT
	DECLARE @UserPartyID INT = 0
	DECLARE @ActionDate DATETIME
	--
	-- Validate parameters
	--
	SET @AuditItemID = ISNULL(@AuditItemID, 0)
	SET @ActionDate = GETDATE()
	
BEGIN TRY
	--
	-- If user already exists on the system than return error
	--
	IF ( ( SELECT COUNT(U.UserName) FROM [OWAP].[Users] U WHERE U.UserName = @UserName ) >= 1 )
	BEGIN
		SET @ErrorCode = 999999
		RETURN
	END
	
	BEGIN TRAN
	--
	-- Get AuditID from SessionID
	--
	EXEC [OWAP].[uspGetAuditID] @SessionID, @AuditID OUTPUT 
	--
	-- Get User details
	--
	EXEC [OWAP].[uspGetUserAndRoleFromAudit] @AuditID, @UserID OUTPUT, @RoleTypeID OUTPUT
	--
	-- If no source party provided, make it the user
	--
	SET @SourcePartyID = ISNULL(@SourcePartyID, @UserID)

	--
	-- See if AuditItemID has been provided
	-- If not, add new one and get ID
	--
	IF ( @AuditItemID = 0 )
	BEGIN
		--
		-- AUDIT THE ACTION AND GET THE RESULTANT AuditItemID
		--
		EXEC OWAP.uspAuditAction @AuditID, @ActionDate, @UserPartyID, @UserRoleTypeID, @AuditItemID OUTPUT, @ErrorCode OUTPUT
	END
	--
	-- If Party already exists just add role
	--
	SET @UserPartyID = ISNULL(@UserPartyID, 0)

	IF @UserPartyID = 0
	BEGIN
		--
		-- Add Person
		--
		EXEC [OWAP].[uspInsertPerson]
			@AuditItemID = @AuditItemID,
			@SessionID = @SessionID,
			@SourcePartyID = @SourcePartyID,
			@TitleID = @TitleID,
			@FirstName = @FirstName,
			@MiddleName = @MiddleName,
			@LastName = @LastName,
			@SecondLastName = @SecondLastName,
			@GenderID = @GenderID,
			@PartyID = @UserPartyID OUTPUT ,
			@ErrorCode = @ErrorCode OUTPUT
	END
	--
	-- Add to Role
	--
	EXEC [Sample].[OWAP].[uspAddUserToRole]
		@AuditItemID,
		@UserPartyID,
		@UserRoleTypeID,
		@UserName,
		@Password,
		@ErrorCode OUTPUT
	--
	-- Error handling
	--
	SET @ErrorCode = 0
	
	COMMIT
/* ##### End of Procedure uspUSERS_AddUser #### */
END TRY
BEGIN CATCH
	IF ( @@TRANCOUNT > 0 )
	BEGIN
		ROLLBACK
	END
	
	SET @ErrorCode = @ErrorNumber
	
	SELECT
		 @ErrorNumber = Error_Number()
		,@ErrorSeverity = Error_Severity()
		,@ErrorState = Error_State()
		,@ErrorLocation = Error_Procedure()
		,@ErrorLine = Error_Line()
		,@ErrorMessage = Error_Message()

	EXEC [Sample_Errors].dbo.uspLogDatabaseError
		 @ErrorNumber
		,@ErrorSeverity
		,@ErrorState
		,@ErrorLocation
		,@ErrorLine
		,@ErrorMessage
		
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)

END CATCH
