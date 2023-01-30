CREATE PROCEDURE [CaseUpdate].[uspResponseFile_AuditFileRows]

AS
/*
	Purpose:	Generate AuditItems and write them to Audit and the internal update table
	
	Version			Date			Developer			Comment
	1.0				04/07/2013		Martin Riverol		Created
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

		-- GENERATE THE AUDITITEMS
		DECLARE @MaxAuditItemID dbo.AuditItemID
		
		SELECT @MaxAuditItemID = MAX(AuditItemID) FROM [$(AuditDB)].dbo.AuditItems

		UPDATE CaseUpdate.ResponseFile
		SET AuditItemID = ID + @MaxAuditItemID

		-- INSERT NEW AUDITITEMS INTO AuditItems
		INSERT INTO [$(AuditDB)].dbo.AuditItems
		(
			AuditID,
			AuditItemID
		)
		SELECT
			AuditID,
			AuditItemID
		FROM CaseUpdate.ResponseFile

		-- INSERT A FILE ROW FOR EACH AUDITITEM
		INSERT INTO [$(AuditDB)].dbo.FileRows
		(
			AuditItemID,
			PhysicalRow
		)
		SELECT
			AuditItemID,
			-- THERE MAY BE MORE THAN ONE FILE SO CALCULATE ROW NUMBERS BY FILE
			RANK() OVER (PARTITION BY AuditID ORDER BY ID)
		FROM CaseUpdate.ResponseFile

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