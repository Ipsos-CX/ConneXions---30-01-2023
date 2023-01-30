CREATE PROCEDURE Stage.uspStandardise_LandRover_Italy_Service
AS

/*
	Purpose:	Convert the service date from a text string to a valid DATETIME type
	
	Version		Date			Developer			Comment
	1.0			20/09/2013		Martin Riverol		Created
	1.1			07/08/2019		Ben King			BUG 15311 - Prevent partial loaded batch of files
	1.2			18/09/2019		Ben King			BUG 15590 - Prevent partial load, update blank model yr to NULL
	1.3			18/05/2021		Eddie Thomas		BUG 18221 - CONVERT(BIGINT, ModelYear) errors if the field is a decimal value 
*/

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

SET LANGUAGE ENGLISH
SET DATEFORMAT DMY

BEGIN TRY

	UPDATE Stage.LandRover_Italy_Service
	SET VehiclePurchaseDateConverted = VehiclePurchaseDate
	WHERE ISDATE(VehiclePurchaseDate) = 1
	AND LEN(VehiclePurchaseDate) = 10
	
	UPDATE Stage.LandRover_Italy_Service
	SET VehicleRegistrationDateConverted = VehicleRegistrationDate
	WHERE ISDATE(VehicleRegistrationDate) = 1
	AND LEN(VehicleRegistrationDate) = 10
	
	UPDATE Stage.LandRover_Italy_Service
	SET VehicleDeliveryDateConverted = VehicleDeliveryDate
	WHERE ISDATE(VehicleDeliveryDate) = 1
	AND LEN(VehicleDeliveryDate) = 10
	
	UPDATE Stage.LandRover_Italy_Service
	SET ServiceEventDateConverted = ServiceEventDate
	WHERE ISDATE(ServiceEventDate) = 1
	AND LEN(ServiceEventDate) = 10

	--v1.2
	UPDATE	Stage.LandRover_Italy_Service
	SET		ModelYear = NULL
	WHERE	LEN(ModelYear) = 0

	--Move misaligned model year records to holding table then remove from staging.
	--Fix for IPSOS (also remove blank records loaded)

	IF EXISTS( 
				
			SELECT ModelYear 
			FROM   Stage.LandRover_Italy_Service
			WHERE (ISNUMERIC(ModelYear) <> 1
			AND ModelYear <> '')
			--OR (CONVERT(BIGINT, ModelYear) > 9999)
			--V1.3
			OR (1 = CASE 
					WHEN dbo.[udfIsInteger] (ModelYear) = 1 AND CONVERT(BIGINT, ModelYear) > 9999 THEN 1 
					ELSE 0
				END)

			OR LEN(ISNULL(CAST([Manufacturer] AS NVARCHAR),'') + '-' 
			+ ISNULL(CAST([CountryCode] AS NVARCHAR),'') + '-' 
			+ ISNULL(CAST([EventType] AS NVARCHAR),'')) < 5
				
			 )			 
	BEGIN 
			--Move misaligned model year records to holding table then remove from staging.
			INSERT INTO	Stage.Removed_Records_Staging_Tables (AuditID, FileName, ActionDate, PhysicalFileRow, VIN, Misaligned_ModelYear)
			SELECT	I.AuditID, F.FileName, F.ActionDate, I.PhysicalRowID, I.VIN, I.ModelYear
			FROM	Stage.LandRover_Italy_Service I
			INNER JOIN [$(AuditDB)].DBO.Files F ON I.AuditID = F.AuditID
			WHERE (ISNUMERIC(I.ModelYear) <> 1
			AND I.ModelYear <> '')
			--OR (CONVERT(BIGINT, ModelYear) > 9999)
			--V1.3
			OR (1 = CASE 
					WHEN dbo.[udfIsInteger] (ModelYear) = 1 AND CONVERT(BIGINT, ModelYear) > 9999 THEN 1 
					ELSE 0
				END)

			OR LEN(ISNULL(CAST(I.[Manufacturer] AS NVARCHAR),'') + '-' 
			+ ISNULL(CAST(I.[CountryCode] AS NVARCHAR),'') + '-' 
			+ ISNULL(CAST(I.[EventType] AS NVARCHAR),'')) < 5
			
			DELETE 
			FROM   Stage.LandRover_Italy_Service
			WHERE (ISNUMERIC(ModelYear) <> 1
			AND ModelYear <> '')
			--OR (CONVERT(BIGINT, ModelYear) > 9999)
			--V1.3
			OR (1 = CASE 
					WHEN dbo.[udfIsInteger] (ModelYear) = 1 AND CONVERT(BIGINT, ModelYear) > 9999 THEN 1 
					ELSE 0
				END)

			OR LEN(ISNULL(CAST([Manufacturer] AS NVARCHAR),'') + '-' 
			+ ISNULL(CAST([CountryCode] AS NVARCHAR),'') + '-' 
			+ ISNULL(CAST([EventType] AS NVARCHAR),'')) < 5

	END 
	
	
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
		
		
	-- CREATE A COPY OF THE STAGING TABLE FOR USE IN PRODUCTION SUPPORT
	DECLARE @TimestampString CHAR(15)
	SELECT @TimestampString = [$(ErrorDB)].dbo.udfGetTimestampString(GETDATE())
	
	EXEC('
		SELECT *
		INTO [$(ErrorDB)].Stage.LandRover_Italy_Service_' + @TimestampString + '
		FROM Stage.LandRover_Italy_Service
	')
	
	-- FINALLY RAISE THE ERROR
	RAISERROR ( @ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine )
END CATCH