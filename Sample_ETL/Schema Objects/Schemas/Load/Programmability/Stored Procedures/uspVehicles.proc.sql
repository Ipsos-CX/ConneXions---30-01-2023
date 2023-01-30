CREATE PROCEDURE Load.uspVehicles

AS

/*
		Purpose:	Write vehicle information to Sample database
	
		Version		Date			Developer			Comment
LIVE	1.0			$(ReleaseDate)	Simon Peacock		Created from [Prophet-ETL].dbo.uspODSLOAD_Vehicles
LIVE	1.1			2022-03-28		Chris Ledger		Task 729 - add ModelVariantID			

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

		-- WRITE THE VEHICLE INFORMATION
		INSERT INTO [$(SampleDB)].Vehicle.vwDA_Vehicles
		(	
			AuditItemID, 
			VehicleParentAuditItemID,
			VehicleID, 
			ModelID,
			ModelVariantID,									-- V1.1
			VIN, 
			VehicleIdentificationNumberUsable,
			ModelDescription,
			BodyStyleDescription,
			EngineDescription,
			TransmissionDescription,
			BuildDateOrig,
			BuildYear
		)
		SELECT
			AuditItemID, 
			VehicleParentAuditItemID,
			ISNULL(MatchedODSVehicleID, 0) AS VehicleID, 
			MatchedODSModelID AS ModelID,
			MatchedModelVariantID AS ModelVariantID,		-- V1.1
			VehicleIdentificationNumber AS VIN, 
			VehicleIdentificationNumberUsable,
			ModelDescription,
			BodyStyleDescription,
			EngineDescription,
			TransmissionDescription,
			BuildDateOrig,
			BuildYear
		FROM Load.vwVehicles


		-- WRITE VEHICLE PARTY ROLE TYPES
		INSERT INTO [$(SampleDB)].Vehicle.vwDA_VehiclePartyRoles 
		(
			AuditItemID,
			PartyID, 
			VehicleRoleTypeID, 
			VehicleID, 	
			FromDate, 
			ThroughDate
		)
		SELECT DISTINCT
			AuditItemID,
			PartyID, 
			VehicleRoleTypeID, 
			VehicleID, 
			CURRENT_TIMESTAMP, 
			CAST(NULL AS DATETIME2)
		FROM Load.vwVehiclePartyRoles
		
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