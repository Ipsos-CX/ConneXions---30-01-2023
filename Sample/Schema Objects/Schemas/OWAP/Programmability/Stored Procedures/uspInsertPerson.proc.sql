CREATE       PROCEDURE [OWAP].[uspInsertPerson]
(
	@AuditItemID BIGINT = 0,
	@SessionID NVARCHAR(100) = N'',
	@SourcePartyID INT = NULL,
	@PreNominalTitleID TINYINT = 34, --no title information,
	@Initials NVARCHAR(30) = N'',
	@FirstName NVARCHAR(200) = N'',
	@MiddleName NVARCHAR(200) = N'',
	@LastName NVARCHAR(200) = N'',
	@SecondLastName NVARCHAR(200) = N'',
	@TitleID TINYINT = 11, --no title information,
	@GenderID TINYINT = 0, --unknown,
	@MaritalStatusID TINYINT = 0, --unknown,
	@PartyID INT = 0 OUTPUT,
	@ErrorCode INT = 0 OUTPUT
)
AS

/*
	Description
	-----------

	Version		Date			Author				Why
	------------------------------------------------------------------------------------------------------
	1.0			04/12/2003		Mark Davidson		Created
	1.1			29/03/2004		Mark Davidson		Added Initials field
	1.2			29/03/2004		Mark Davidson		Return PartyID From Audit rather than ODS
	1.3			26/01/2010		Martin Riverol		Default AssociateNameUpdate to 0 on insert to vwDA_People.
	1.4			18/06/2012		Pardip Mudhar		Migrated for new OWAP

	Parameters
	-----------
	@AuditItemID UniqueID for row in [Sample_Audit].WebSiteTransactions If > 0 needs to be created
	@SessionID
	@SourcePartyID The source of the information In this instance the ID of the operator is probably sufficient
	@SecurityRole The Security Role of the Operator
	@TitleID ID of PreNominalTitles i.e. Mr, Mrs, Signor
	@FirstName
	@MiddleName
	@LastName
	@SecondLastName i.e. in Spain
	@GenderID TINYINT
	ID of Genders
	@PartyID Output parameter returning 
	ID of row just inserted into [Sample].People
	@ErrorCode
*/
	DECLARE @ErrorNumber INT
	DECLARE @ErrorSeverity INT
	DECLARE @ErrorState INT
	DECLARE @ErrorLocation NVARCHAR(500)
	DECLARE @ErrorLine INT
	DECLARE @ErrorMessage NVARCHAR(2048)
	--
	--Disable Counts
	--
	SET NOCOUNT ON
	--
	-- Rollback on error
	--
	SET XACT_ABORT ON
	--
	-- Declare local variables
	--
	DECLARE @PreNominalTitle NVARCHAR(200)
	DECLARE @PostNominalTitle NVARCHAR(200)
	DECLARE @AuditID INT
	DECLARE @RoleTypeID SMALLINT
	DECLARE @UserID INT
	
	BEGIN TRY
	
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
	/*
	See if AuditItemID has been provided
	If not, add new one and get ID
	*/

	IF @AuditItemID = 0
	BEGIN
	--
	-- Add audit item
	--
		EXEC [OWAP].[uspAuditSession] @AuditID, @SourcePartyID, @RoleTypeID, @AuditItemID OUTPUT, @ErrorCode OUTPUT
	END
	--
	--
	-- Initialise local variables
	--  Title
	--
	SELECT
		@PreNominalTitle = pre.Title
	FROM
		[Party].Titles AS pre
	WHERE
		pre.TitleID = @PreNominalTitleID
	--
	-- Perform Insert
	--
	INSERT INTO [Party].vwDA_People

		(
			AuditItemID,
			ParentAuditItemID,
			FromDate,
			PartyID,
			TitleID,
			Title,
			Initials,
			FirstName,
			MiddleName,
			LastName,
			SecondLastName,
			GenderID
		)
	VALUES
	(
		@AuditItemID,
		@AuditItemID,
		CURRENT_TIMESTAMP,
		ISNULL(@PartyID, 0),
		ISNULL(@PreNominalTitleID, 0),
		@PreNominalTitle,
		@Initials,
		@FirstName,
		@MiddleName,
		@LastName,
		@SecondLastName,
		ISNULL(@GenderID, 0)
	)

--Get PartyID just inserted
/*
	SELECT
		@PartyID = MAX(PartyID)
	FROM
		People
*/
	SELECT
		@PartyID = p.PartyID
	FROM
		[Sample_Audit].[Audit].People AS p
	WHERE
		p.AuditItemID = @AuditItemID
	--
	-- Return Error
	--
	SELECT @ErrorCode = @@error
	
	END TRY
	BEGIN CATCH

		IF ( @@TRANCOUNT > 0 )
		BEGIN
			ROLLBACK
		END
		
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



/* ##### End of Procedure uspINSERT_Person #### */
GO
