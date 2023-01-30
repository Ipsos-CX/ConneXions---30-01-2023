CREATE PROCEDURE [GermanyRedFlagReport].[uspGermanyRedFlagReport_AuditFileRows]

AS

/*
		Purpose:	Generate AuditItems and write them to Audit and the internal update table
	
		Version		Date			Developer			Comment
LIVE	1.0			2022-08-23		Chris Ledger		Created
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
		DECLARE @MaxAuditItemID INT
		
		SELECT @MaxAuditItemID = MAX(AuditItemID) FROM [$(AuditDB)].dbo.AuditItems

		UPDATE GermanyRedFlagReport.GermanyRedFlagReportData
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
		FROM GermanyRedFlagReport.GermanyRedFlagReportData

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
		FROM GermanyRedFlagReport.GermanyRedFlagReportData

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
