
CREATE PROCEDURE [IAssistance].[uspSetIAssistanceAuditItemIDs]

AS 
/*
	Purpose:	Writes generated AuditItemIDs back to IAssistance.IAssistanceEvents
	
	Version			Date			Developer			Comment
	1.0				2018-10-26		Chris Ledger		Created from [Sample_ETL].Roadside.uspSetRoadsideAuditItemIDs

*/

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	-- CHECK IF IE HAVE ANY WORK TO DO
	DECLARE @RowsToUpdate INT

	SELECT @RowsToUpdate = COUNT(VWTID)
	FROM dbo.VWT
	WHERE IAssistanceID > 0

	-- UPDATE AuditItemID AND SET THE DateStamp
	IF @RowsToUpdate > 0
	BEGIN
		UPDATE IE
		SET
			IE.AuditItemID = V.AuditItemID, 
			IE.DateTransferredToVWT = CURRENT_TIMESTAMP
		FROM IAssistance.IAssistanceEvents IE
		INNER JOIN (
			SELECT
				AuditItemID, 
				IAssistanceID
			FROM dbo.VWT
			WHERE IAssistanceID > 0
			AND AuditItemID > 0
		) V ON IE.IAssistanceID = V.IAssistanceID
		WHERE (
			IE.AuditItemID IS NULL OR IE.AuditItemID = 0
		)
		AND IE.DateTransferredToVWT IS NULL
	END

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