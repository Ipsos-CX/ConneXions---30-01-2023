CREATE PROCEDURE Stage.uspAsiaPacificImporters_Dedupe

AS

/*
		Purpose:	De-dupes the unique records (e_bp_uniquerecordid_txt) by setting the ParentAuditItemID column to be the maximum AuditItemID for each pair
	
		Version		Date				Developer			Comment
LIVE	1.0			2021-10-11			Chris Ledger		Created
*/

SET NOCOUNT ON

	DECLARE @ErrorNumber INT
	DECLARE @ErrorSeverity INT
	DECLARE @ErrorState INT
	DECLARE @ErrorLocation NVARCHAR(500)
	DECLARE @ErrorLine INT
	DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	UPDATE API
	SET API.ParentAuditItemID = M.ParentAuditItemID
	FROM Stage.AsiaPacificImporters API
		INNER JOIN (	SELECT MAX(AuditItemID) AS ParentAuditItemID,
							API.e_bp_uniquerecordid_txt
						FROM Stage.AsiaPacificImporters API
						GROUP BY API.e_bp_uniquerecordid_txt) M ON M.e_bp_uniquerecordid_txt = API.e_bp_uniquerecordid_txt

	UPDATE API
	SET API.VehicleParentAuditItemID = M.VehicleParentAuditItemID
	FROM Stage.AsiaPacificImporters API
		INNER JOIN (	SELECT MAX(AuditItemID) AS VehicleParentAuditItemID,
							API.e_jlr_vehicle_identification_number_text
						FROM Stage.AsiaPacificImporters API
						GROUP BY API.e_jlr_vehicle_identification_number_text) M ON M.e_jlr_vehicle_identification_number_text = API.e_jlr_vehicle_identification_number_text
				
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