CREATE PROCEDURE [OWAP].[uspAuthenticateUser]
(
	@SessionID dbo.SessionID, 
	@UserName VARCHAR(100), 
	@Password VARCHAR(255),
	@UserFullName dbo.NameDetail OUTPUT,
	@AuditID dbo.AuditID OUTPUT, 
	@PartyRoleID dbo.PartyRoleID OUTPUT,
	@RoleTypeId [dbo].[RoleTypeID] OUTPUT, 
	@PartyID [dbo].[PartyID] OUTPUT,
	@ErrorCode INT = 0 OUTPUT
)
AS


/*
	Purpose:	Check the username and password supplied, audits, the authentication event using the SessionID and
				returns the AuditID and PartyRoleID for the user.  If these are 0 then the user failed
				authentication.  
		
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)	Simon Peacock		Created
	1.1				18-05-2012		Pardip Mudhar		Updated to returne RoleTypeID

*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	-- SET THE DEFAULT VALUES TO RETURN IF WE FAIL TO AUTHENTICATE THE USER
	SET @AuditID = 0
	SET @PartyRoleID = 0
	SET @RoleTypeID = 0
	
	-- CHECK THE USER EXISTS
	SELECT
		 @PartyRoleID = PartyRoleID
		,@RoleTypeId = RoleTypeID
		,@UserFullName = UserFullName
		,@PartyID = PartyID
	FROM OWAP.vwUsers
	WHERE UserName = @UserName
	AND Password = @Password
	
	-- IF THE USER DOESN'T EXIST RAISE AN APPROPRIATE ERROR AND RETURN AN ERROR CODE
	IF @PartyRoleID = 0
	BEGIN
		SET @ErrorCode = 60001
		RAISERROR(60001, 1, 1)
		RETURN
	END		
	
	-- AUDIT THE AUTHENTICATION EVENT
	EXEC OWAP.uspAuditSession @SessionID, @PartyRoleID, @AuditID OUTPUT, @ErrorCode OUTPUT	

	-- SET THE ERROR CODE
	SELECT @ErrorCode = ISNULL(Error_Number(), 0)

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



