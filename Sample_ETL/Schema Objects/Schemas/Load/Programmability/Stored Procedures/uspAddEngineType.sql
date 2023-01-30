CREATE PROCEDURE [Load].[uspAddEngineType]
AS

/*
	Purpose: Populate EngineTypeID field 
	
	Version		Date			Developer			Comment
	1.0			2022-07-12		Eddie Thomas		Created : BUGTRACKER 19508 
*/

SET NOCOUNT ON

	DECLARE @ErrorNumber INT
	DECLARE @ErrorSeverity INT
	DECLARE @ErrorState INT
	DECLARE @ErrorLocation NVARCHAR(500)
	DECLARE @ErrorLine INT
	DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY
	 DECLARE @EngineTypeUnknownID INT 


	--BEV
	UPDATE		VEH
	SET			VEH.EngineTypeID =	PHV.EngineTypeID
	FROM		[$(SampleDB)].Vehicle.Vehicles		VEH
	INNER JOIN	[$(SampleDB)].Vehicle.PHEVModels	PHV ON VEH.ModelID = PHV.ModelID	
	WHERE		(LEFT(VEH.VIN,4)			= PHV.VINPrefix) AND 
				(SUBSTRING(VEH.VIN, 8, 1)	= PHV.VINCharacter) AND 
				(PHV.EngineDescription LIKE '%BEV%') AND
				(VEH.EngineTypeID IS NULL) 

	--PHEV
	UPDATE		VEH
	SET			VEH.EngineTypeID =	PHV.EngineTypeID
	FROM		[$(SampleDB)].Vehicle.Vehicles		VEH
	INNER JOIN	[$(SampleDB)].Vehicle.PHEVModels	PHV ON VEH.ModelID = PHV.ModelID	
	WHERE		(LEFT(VEH.VIN,4)			= PHV.VINPrefix) AND 
				(SUBSTRING(VEH.VIN, 8, 1)	= PHV.VINCharacter) AND 
				(PHV.EngineDescription LIKE '%PHEV%') AND
				(VEH.EngineTypeID IS NULL) 


	SELECT		@EngineTypeUnknownID = EngineTypeID FROM Lookup.EngineType WHERE EngineTypeDescription ='Non BHEV/PHEV'

	UPDATE		[$(SampleDB)].Vehicle.Vehicles
	SET			EngineTypeID =	@EngineTypeUnknownID
	FROM		[$(SampleDB)].Vehicle.Vehicles
	WHERE		EngineTypeID IS NULL AND
				VIN NOT IN ('SAJ_CRC_Unknown_V','SAL_CRC_Unknown_V')
				
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
