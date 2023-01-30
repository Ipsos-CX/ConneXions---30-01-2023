CREATE  PROCEDURE [dbo].[uspVWT_DedupeVehicles]

AS

/*
	Purpose:	Deduplicate 'VehicleIdentificationNumber' in the VWT
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created from [Prophet-ETL].dbo.uspDEDUPE_VWTVehicles
	1.1				10/03/2014		Ali Yuksel			Bug 10048 : Records without a VIN and Reg Number cant create a Vehicle
	

*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	-- GET THE VehicleParentAuditItemID FOR ROWS WE HAVE A VIN FOR
	UPDATE V
	SET V.VehicleParentAuditItemID = AI.VehicleParentAuditItemID
	FROM dbo.VWT V
	INNER JOIN (
		SELECT 
			MIN(AuditItemID) AS VehicleParentAuditItemID,
			VehicleIdentificationNumber
		FROM dbo.VWT
		WHERE ISNULL(VehicleIdentificationNumber, '') <> ''
		GROUP BY VehicleIdentificationNumber
	) AI ON V.VehicleIdentificationNumber = AI.VehicleIdentificationNumber
	
	-- FOR ROWS WHERE THE VIN IS NULL OR BLANK USE THE REGISTRATION NUMBER TO GENERATE THE VehicleParentAuditItemID
	UPDATE V
	SET V.VehicleParentAuditItemID = AI.VehicleParentAuditItemID
	FROM dbo.VWT V
	INNER JOIN (
		SELECT
			MIN(AuditItemID) AS VehicleParentAuditItemID,
			VehicleRegistrationNumber
		FROM dbo.VWT
		WHERE ISNULL(VehicleIdentificationNumber, '') = ''
		AND ISNULL(VehicleRegistrationNumber, '') <> ''
		GROUP BY VehicleRegistrationNumber
	) AI ON V.VehicleRegistrationNumber = AI.VehicleRegistrationNumber
	WHERE V.VehicleParentAuditItemID IS NULL
	
	
	--Bug 10048 
	--update all other records with own AuditItemID to cover records without a VIN and Reg Number
	UPDATE dbo.VWT
	SET VehicleParentAuditItemID = AuditItemID
	WHERE VehicleParentAuditItemID IS NULL
	
	
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