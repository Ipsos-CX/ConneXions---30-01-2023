

CREATE PROCEDURE [OWAP].[uspLogRunTime]
@UserName nvarchar(100),
@AuditID [dbo].[AuditID],
@PartyRoleID [dbo].[PartyRoleID],
@SessionID [dbo].[SessionID],  
@LogStr nvarchar(2048),
@ErrorCode INT=0 OUTPUT
AS
SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	-- RECORDS THE SESSION IN AUDIT
	
	INSERT INTO [OWAP].[RunTimeLog]
	(
		LogDateTime ,
		UserName ,
		AuditID ,
		UserPartyRoleID ,
		SessionID ,
		LogStr 
	)
	VALUES
	(
		GETDATE(), 
		@UserName,
		@AuditID, 
		@PartyRoleID, 
		@SessionID,
		@LogStr 
	)

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

	EXEC [Sample_Errors].dbo.uspLogDatabaseError
		 @ErrorNumber
		,@ErrorSeverity
		,@ErrorState
		,@ErrorLocation
		,@ErrorLine
		,@ErrorMessage
		
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH


