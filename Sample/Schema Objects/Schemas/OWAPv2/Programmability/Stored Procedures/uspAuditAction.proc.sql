CREATE PROCEDURE [OWAPv2].[uspAuditAction]
@AuditID INT, @ActionDate DATETIME2 (7), @UserPartyID INT=NULL, @UserRoleTypeID SMALLINT=NULL, @AuditItemID INT=0 OUTPUT, @ErrorCode INT=0 OUTPUT
AS

/*
	Purpose:	OWAP Audit
		
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)	Pardip Mudhar		Created
	1.1				21/01/2020		Chris Ledger		BUG 15372: Fix Hard coded references to databases.	
*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	-- INSERT THE OWAP ACTION
	INSERT INTO [$(AuditDB)].OWAP.vwDA_Actions
	(
		AuditItemID, 
		AuditID, 
		ActionDate, 
		UserPartyID, 
		UserRoleTypeID
	)
	VALUES
	(
		0,
		@AuditID, 
		@ActionDate,
		@UserPartyID, 
		@UserRoleTypeID
	)

	-- GET THE GENERATED AuditItemID
	SELECT @AuditItemID = MAX(A.AuditItemID)
	FROM [$(AuditDB)].OWAP.Actions A
	INNER JOIN [$(AuditDB)].dbo.AuditItems AI ON AI.AuditItemID = A.AuditItemID
	WHERE AI.AuditID = @AuditID
	AND A.UserPartyID = @UserPartyID
	AND A.UserRoleTypeID = @UserRoleTypeID	
	
	
	SET @ErrorCode = ISNULL(Error_Number(), 0)

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