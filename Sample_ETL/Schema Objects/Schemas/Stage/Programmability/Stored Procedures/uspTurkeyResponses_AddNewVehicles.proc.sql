CREATE PROCEDURE Stage.uspTurkeyResponses_AddNewVehicles

AS

/*
		Purpose:	SP to load new vehicles
	
		Version		Date				Developer			Comment
LIVE	1.0			2021-10-12			Chris Ledger		Created
LIVE	1.1			2022-03-31			Chris Ledger		Task 729 - new model matching
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

		-- HOLDS REC ID'S FOR NEW VEHICLES ABOUT TO BE LOADED INTO THE DATABASE
		DECLARE	@NewVehicles TABLE
		(
			ID INT IDENTITY(1, 1), 
			VehicleID BIGINT,
			ModelID SMALLINT,
			ModelVariantID SMALLINT,				-- V1.1
			VIN NVARCHAR(50),
			BuildDateOrig VARCHAR(20),
			AuditItemID BIGINT,
			VehicleIdentificationNumberUsable BIT
		)


		-- GET NEW VEHICLE RECS FROM VWT
		INSERT @NewVehicles
		(
			ModelID,
			ModelVariantID,							-- V1.1
			VIN,
			BuildDateOrig,
			AuditItemID,
			VehicleIdentificationNumberUsable
		)
		SELECT DISTINCT 
			TR.ModelID,
			TR.ModelVariantID,	-- V1.1
			TR.e_jlr_vehicle_identification_number_text AS VIN,
			CAST(TR.e_jlr_model_year_auto AS VARCHAR) AS BuildDateOrig,
			TR.AuditItemID,
			0 AS VehicleIdentificationNumberUsable
		FROM Stage.TurkeyResponses TR
		WHERE ISNULL(TR.VehicleID, 0) = 0
			AND TR.AuditItemID = TR.VehicleParentAuditItemID

		-- GENERATE NEW VEHCILEIDS
		DECLARE @Max_VehicleID BIGINT
		SELECT @Max_VehicleID = MAX(VehicleID) FROM [$(SampleDB)].Vehicle.Vehicles
	
		UPDATE @NewVehicles
		SET VehicleID = ID + @Max_VehicleID

	
		-- INSERT THE NEW VEHICLES INTO THE VEHICLES TABLE
		INSERT INTO [$(SampleDB)].Vehicle.Vehicles 
		(
			VehicleID, 
			ModelID,
			ModelVariantID,						-- V1.1
			VIN, 
			VehicleIdentificationNumberUsable
		)
		SELECT	
			VehicleID, 
			ModelID,
			ModelVariantID,						-- V1.1
			VIN, 
			VehicleIdentificationNumberUsable
		FROM @NewVehicles


		-- V1.1 UPDATE MODEL YEAR
		EXEC [$(SampleDB)].Vehicle.uspUpdateVehicleBuildYear


		-- V1.1 UPDATE MODELVARIANTID BY MODEL YEAR
		EXEC [$(SampleDB)].Vehicle.uspUpdateVehicleModelVariantIDByModelYear


		INSERT INTO [$(AuditDB)].Audit.Vehicles 
		(
			AuditItemID,
			VehicleID,
			ModelID,
			ModelVariantID,							-- V1.1
			VIN, 
			VehicleIdentificationNumberUsable,
			BuildDateOrig, 
			BuildYear,								-- V1.1
			ModelDescription
		)
		SELECT	
			TR.AuditItemID,
			COALESCE(COALESCE(NULLIF(NV.VehicleID, 0), NULLIF(TR.VehicleID, 0)), 0),
			TR.ModelID,
			V.ModelVariantID,						-- V1.1
			TR.e_jlr_vehicle_identification_number_text AS VIN, 
			1 AS VehicleIdentificationNumberUsable,
			CAST(TR.e_jlr_model_year_auto AS VARCHAR) AS BuildDateOrig, 
			V.BuildYear,							-- V1.1
			TR.e_jlr_model_description_text AS ModelDescription
		FROM Stage.TurkeyResponses TR
			LEFT JOIN @NewVehicles NV ON TR.VehicleParentAuditItemID = NV.AuditItemID
			LEFT JOIN [$(SampleDB)].Vehicle.Vehicles V ON COALESCE(COALESCE(NULLIF(NV.VehicleID, 0), NULLIF(TR.VehicleID, 0)), 0) = V.VehicleID		-- V1.1
			LEFT JOIN [$(AuditDB)].Audit.Vehicles  AV ON AV.AuditItemID = TR.AuditItemID
		WHERE AV.AuditItemID IS NULL

	
		-- UPDATE TURKEY RESPONSES WITH NEWLY ADDED VEHICLES VEHICLEID'S
		UPDATE TR
		SET TR.VehicleID = NV.VehicleID,
			TR.ModelVariantID = V.ModelVariantID				-- V1.1
		FROM @NewVehicles NV
			INNER JOIN Stage.TurkeyResponses TR ON NV.AuditItemID = TR.VehicleParentAuditItemID
			LEFT JOIN [$(SampleDB)].Vehicle.Vehicles V ON COALESCE(COALESCE(NULLIF(NV.VehicleID, 0), NULLIF(TR.VehicleID, 0)), 0) = V.VehicleID		-- V1.1

		-- UPDATE FOBCODE
		EXEC [$(SampleDB)].Vehicle.uspUpdateVehicleFOBCode


		-- UPDATE SVOTYPEID
		EXEC Load.uspFlagSVOvehicles

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