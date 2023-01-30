CREATE TRIGGER Vehicle.TR_I_vwDA_Vehicles ON Vehicle.vwDA_Vehicles
INSTEAD OF INSERT

AS

/*
	Purpose:	Handles insert into vwDA_Vehicles.
				All rows in VWT containing vehicle information should be inserted into this view.
				All rows are written to the Audit.Vehicles table where it is a new row

	
		Version		Date			Developer			Comment
LIVE	1.0			$(ReleaseDate)	Simon Peacock		Created from [Prophet-ODS].dbo.vwDA_vwDA_Vehicles.TR_I_vwDA_vwDA_Vehicles
LIVE	1.1			2022-03-24		Chris Ledger		TASK 729 - Changes for new models/modelvariants

*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	DROP TABLE IF EXISTS #NewVehicles											-- V1.1

	-- HOLDS REC ID'S FOR NEW VEHICLES ABOUT TO BE LOADED INTO THE DATABASE
	CREATE TABLE #NewVehicles 
	(
		ID INT IDENTITY(1, 1), 
		VehicleID BIGINT,
		ModelID SMALLINT,
		ModelVariantID SMALLINT,				-- V1.1
		VIN NVARCHAR(50),
		BuildDateOrig VARCHAR(20),
		BuildYear SMALLINT,
		AuditItemID BIGINT,
		VehicleIdentificationNumberUsable BIT
	)


	-- GET NEW VEHICLE RECS FROM VWT
	INSERT INTO #NewVehicles
	(
		ModelID,
		ModelVariantID,							-- V1.1
		VIN,
		BuildDateOrig,
		BuildYear,
		AuditItemID,
		VehicleIdentificationNumberUsable
	)
	SELECT DISTINCT 
		ModelID,
		ModelVariantID,							-- V1.1
		VIN,
		BuildDateOrig,
		BuildYear,
		AuditItemID,
		VehicleIdentificationNumberUsable
	FROM INSERTED
	WHERE ISNULL(VehicleID, 0) = 0
		AND AuditItemID = VehicleParentAuditItemID


	-- GENERATE NEW VEHCILEIDS
	DECLARE @Max_VehicleID BIGINT
	
	SELECT @Max_VehicleID = MAX(VehicleID) FROM Vehicle.Vehicles
	
	UPDATE #NewVehicles
	SET VehicleID = ID + @Max_VehicleID


	-- INSERT THE NEW VEHICLES INTO THE VEHICLES TABLE
	INSERT INTO Vehicle.Vehicles 
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
	FROM #NewVehicles


	-- V1.1 UPDATE MODEL YEAR
	EXEC Vehicle.uspUpdateVehicleBuildYear


	-- V1.1 UPDATE MODELVARIANTID BY MODEL YEAR
	EXEC Vehicle.uspUpdateVehicleModelVariantIDByModelYear


	INSERT INTO [$(AuditDB)].Audit.Vehicles 
	(
		AuditItemID,
		VehicleID,
		ModelID,
		ModelVariantID,							-- V1.1
		VIN, 
		VehicleIdentificationNumberUsable,
		BuildDateOrig, 
		BuildYear, 
		ThroughDate, 
		ModelDescription,
		BodyStyleDescription,
		EngineDescription,
		TransmissionDescription
	)
	SELECT	
		I.AuditItemID,
		COALESCE(COALESCE(NULLIF(NV.VehicleID, 0), NULLIF(I.VehicleID, 0)), 0) AS VehicleID,	-- V1.1
		I.ModelID,
		V.ModelVariantID,						-- V1.1
		I.VIN, 
		I.VehicleIdentificationNumberUsable,
		I.BuildDateOrig, 
		V.BuildYear,							-- V1.1
		I.ThroughDate, 
		I.ModelDescription,
		I.BodyStyleDescription,
		I.EngineDescription,
		I.TransmissionDescription
	FROM INSERTED I
		LEFT JOIN #NewVehicles NV ON I.VehicleParentAuditItemID = NV.AuditItemID													-- V1.1
		LEFT JOIN Vehicle.Vehicles V ON COALESCE(COALESCE(NULLIF(NV.VehicleID, 0), NULLIF(I.VehicleID, 0)), 0) = V.VehicleID		-- V1.1
		LEFT JOIN [$(AuditDB)].Audit.Vehicles AV ON AV.AuditItemID = I.AuditItemID
	WHERE AV.AuditItemID IS NULL


	-- UPDATE VWT WITH NEWLY ADDED VEHICLES VEHICLEID'S
	UPDATE V
	SET V.MatchedODSVehicleID = NV.VehicleID,
		V.MatchedODSModelID = V1.ModelID,				-- V1.1
		V.MatchedModelVariantID = V1.ModelVariantID,	-- V1.1
		V.MatchedModelYear = V1.BuildYear				-- V1.1
	FROM #NewVehicles NV
		INNER JOIN [$(ETLDB)].dbo.VWT V ON NV.AuditItemID = V.VehicleParentAuditItemID
		INNER JOIN Vehicle.Vehicles V1 ON NV.VehicleID = V1.VehicleID							-- V1.1

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

