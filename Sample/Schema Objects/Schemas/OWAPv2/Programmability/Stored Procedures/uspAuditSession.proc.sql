CREATE PROCEDURE [OWAPv2].[uspAuditSession]
@SessionID [dbo].[SessionID], @PartyRoleID [dbo].[PartyRoleID], @AuditID [dbo].[AuditID]=0 OUTPUT, @ErrorCode INT=0 OUTPUT
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

	-- RECORDS THE SESSION IN AUDIT
	INSERT INTO [$(AuditDB)].OWAP.vwDA_Sessions
	(
		AuditID, 
		UserPartyRoleID, 
		SessionID
	)
	VALUES
	(
		0,
		@PartyRoleID, 
		@SessionID
	)
	
	-- GET THE AuditID FOR THE SESSION
	SELECT @AuditID = AuditID FROM [$(AuditDB)].OWAP.Sessions WHERE SessionID = @SessionID

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
