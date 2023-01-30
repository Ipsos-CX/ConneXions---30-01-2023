CREATE PROCEDURE [China].[uspReportVINsAuditFileRows]

AS

/*
	Purpose:	Generate AuditItems and write them to Audit and the customer update table
	
					Version			Date			Developer			Comment
	LIVE			1.0				16/03/2021		Ben King			BUG 18109 - China VINs Report
	LIVE			1.1				2022-03-17      ben King            TASK 824 - Incoming Feed China VINs change

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

		-- GENERATE THE AuditItems
		DECLARE @MaxAuditItemID dbo.AuditItemID
		
		SELECT @MaxAuditItemID = MAX(AuditItemID) FROM [$(AuditDB)].dbo.AuditItems

		UPDATE Stage.Chinese_VINs
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
		FROM Stage.Chinese_VINs

		-- INSERT A FILE ROW FOR EACH AUDITITEM
		INSERT INTO [$(AuditDB)].dbo.FileRows
		(
			AuditItemID,
			PhysicalRow
		)
		SELECT
			AuditItemID,
			ID
		FROM Stage.Chinese_VINs


		-- V1.1
		UPDATE V
		SET V.VehicleParentAuditItemID = M.VehicleParentAuditItemID
		FROM Stage.Chinese_VINs V
		INNER JOIN (	SELECT MAX(AuditItemID) AS VehicleParentAuditItemID,
								V.VIN	
						FROM Stage.Chinese_VINs V
						GROUP BY V.VIN	) M ON M.VIN = V.VIN


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
GO