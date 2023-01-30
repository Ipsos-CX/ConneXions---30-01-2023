CREATE TRIGGER OWAP.TR_I_vwDA_Sessions ON OWAP.vwDA_Sessions
INSTEAD OF INSERT
AS 

/*
	Purpose:	Record a new OWAP session
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created from [Prophet-Audit].dbo.vwDA_WebsiteSessions.TR_I_vwDA_WebsiteSessions

*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	BEGIN TRAN
	
		-- INSERT THE DATA INTO A TEMP TABLE TO GENERATE AuditID(s)
		CREATE TABLE #Sessions
		(
			 ID INT IDENTITY(1,1) NOT NULL
			,AuditID BIGINT NULL
			,SessionID VARCHAR(100) NOT NULL
			,UserPartyRoleID INT NOT NULL
		)
		
		INSERT INTO #Sessions (SessionID, UserPartyRoleID)
		SELECT SessionID, UserPartyRoleID FROM INSERTED

		-- GET THE MAX AUDITID AND USE IT TO GENERATE NEW ONES
		DECLARE @MaxAuditID INT
		
		SELECT @MaxAuditID = MAX(AuditID) FROM dbo.Audit
		
		UPDATE #Sessions
		SET AuditID = ID + @MaxAuditID
		
		-- INSERT THE NEW AUDITIDS	
		INSERT INTO dbo.Audit (AuditID)
		SELECT AuditID FROM #Sessions
		
		-- FINALLY ADD THE SESSION INFORMATION
		INSERT INTO OWAP.Sessions
		(
			AuditID, 
			SessionID, 
			UserPartyRoleID,
			SessionTimeStamp
		)
		SELECT
			AuditID, 
			SessionID, 
			UserPartyRoleID,
			GETDATE()
		FROM #Sessions

	COMMIT TRAN

END TRY
BEGIN CATCH

	IF @@TRANCOUNT > 0
	BEGIN
		ROLLBACK TRAN
	END

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