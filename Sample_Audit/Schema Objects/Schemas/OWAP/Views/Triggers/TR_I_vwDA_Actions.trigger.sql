CREATE TRIGGER OWAP.TR_I_vwDA_Actions ON OWAP.vwDA_Actions
INSTEAD OF INSERT
AS


/*
	Purpose:	Record a new OWAP action
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created from [Prophet-Audit].dbo.vwDA_WebsiteTransactions.TR_I_vwDA_WebsiteTransactions

*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY
	
	-- CREATE TABLE TO HOLD ACTION SO WE CAN GENERATE THE AuditItemIDs
	CREATE TABLE #Actions 
	(
		ID INT IDENTITY(1, 1) NOT NULL, 
		AuditID BIGINT NOT NULL, 
		AuditItemID BIGINT NULL, 
		ActionDate DATETIME2 NOT NULL, 
		UserPartyID INT NOT NULL, 
		UserRoleTypeID SMALLINT
	)
		
	INSERT INTO #Actions
	(
		AuditID, 
		ActionDate, 
		UserPartyID, 
		UserRoleTypeID
	)
	SELECT
		AuditID, 
		ActionDate, 
		UserPartyID, 
		UserRoleTypeID
	FROM INSERTED
	
	-- GET THE MAXIMUM AuditItemID AND USE IT TO GENERATE THE NEW ONES
	DECLARE @MaxAuditItemID dbo.AuditItemID
	
	SELECT @MaxAuditItemID = ISNULL(MAX(AuditItemID), 0)
	FROM dbo.AuditItems
	
	UPDATE #Actions
	SET AuditItemID = ID + @MaxAuditItemID

	-- INSERT ROWS INTO AuditItems
	INSERT INTO dbo.AuditItems
	(
		AuditItemID, 
		AuditID
	)
	SELECT
		AuditItemID, 
		AuditID
	FROM #Actions
	ORDER BY AuditItemID
	
	-- FINALLY, INSERT THE DATA INTO THE Actions TABLE
	INSERT INTO OWAP.Actions
	(
		AuditItemID, 
		ActionDate, 
		UserPartyID, 
		UserRoleTypeID
	)
	SELECT
		AuditItemID, 
		ActionDate, 
		UserPartyID, 
		UserRoleTypeID
	FROM #Actions
	ORDER BY AuditItemID


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

