CREATE PROCEDURE [CustomerUpdate].[uspExtraVehicleFeed_Dedupe]

AS

/*
	Purpose:	De-dupes the VINs by setting the ParentAuditItemID column to be the maximum AuditItemID for each pair
	
	Version			Date				Developer			Comment
	1.0				2017-04-21			Chris Ledger		Created from CustomerUpdate.uspPerson_Dedupe

*/


SET NOCOUNT ON

	DECLARE @ErrorNumber INT
	DECLARE @ErrorSeverity INT
	DECLARE @ErrorState INT
	DECLARE @ErrorLocation NVARCHAR(500)
	DECLARE @ErrorLine INT
	DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	UPDATE EVF
	SET EVF.ParentAuditItemID = M.ParentAuditItemID
	FROM CustomerUpdate.ExtraVehicleFeed EVF
	INNER JOIN (
		SELECT
			MAX(AuditItemID) AS ParentAuditItemID,
			VIN
		FROM CustomerUpdate.ExtraVehicleFeed
		GROUP BY VIN
	) M ON M.VIN = EVF.VIN
			
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