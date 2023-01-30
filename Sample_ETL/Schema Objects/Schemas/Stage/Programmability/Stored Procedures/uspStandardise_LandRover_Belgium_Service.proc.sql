CREATE PROCEDURE Stage.uspStandardise_LandRover_Belgium_Service
AS

/*
	Purpose:	Convert the service date from a text string to a valid DATETIME type
	
	Version		Date			Developer			Comment
	1.0			17/03/2014		Martin Riverol		Created
	1.1			22/02/2017		Chris Ledger		BUG 13444: Add Check on OwnershipCycle
	1.2			19/09/2019		Ben King			BUG 15592 - Prevent partial load, update blank model yr to NULL
	1.3			19/09/2019		Ben King			BUG 15311 - Prevent partial loaded batch of files
	1.4			15/02/2021		Ben King			BUG 18106 - Belgium Preferred Language
	1.5         13/05/2021      Ben King            BUG 18200 - Belgium Service Loader - Remove Non-applicable countryCodes
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

	UPDATE Stage.LandRover_Belgium_Service
	SET VehiclePurchaseDateConverted = VehiclePurchaseDate
	WHERE ISDATE(VehiclePurchaseDate) = 1
	AND LEN(VehiclePurchaseDate) = 10
	
	UPDATE Stage.LandRover_Belgium_Service
	SET VehicleRegistrationDateConverted = VehicleRegistrationDate
	WHERE ISDATE(VehicleRegistrationDate) = 1
	AND LEN(VehicleRegistrationDate) = 10
	
	UPDATE Stage.LandRover_Belgium_Service
	SET VehicleDeliveryDateConverted = VehicleDeliveryDate
	WHERE ISDATE(VehicleDeliveryDate) = 1
	AND LEN(VehicleDeliveryDate) = 10
	
	UPDATE Stage.LandRover_Belgium_Service
	SET ServiceEventDateConverted = ServiceEventDate
	WHERE ISDATE(ServiceEventDate) = 1
	AND LEN(ServiceEventDate) = 10

	--V1.2
	UPDATE  Stage.LandRover_Belgium_Service
	SET		ModelYear = NULL
	WHERE	LEN(ModelYear) = 0

	----------------------------------------------------------------------------
	-- SET OwnershipCycle TO 0 IF NULL
	----------------------------------------------------------------------------
	UPDATE Stage.LandRover_Belgium_Service
	SET OwnershipCycle = 0
	WHERE ISNULL(NULLIF(OwnershipCycle,''),0) = 0

	--V1.4
	--NO DEFULAT PERMITTED FOR BELGIUM
	UPDATE S
	SET LanguageID = CASE 
						WHEN S.PreferredLanguage = 'FR' THEN (SELECT LanguageID FROM [$(SampleDB)].dbo.Languages WHERE ISOAlpha2 ='FR')
						WHEN S.PreferredLanguage = 'NL' THEN (SELECT LanguageID FROM [$(SampleDB)].dbo.Languages WHERE ISOAlpha2 ='NL')
						ELSE 0
					 END
	FROM Stage.LandRover_Belgium_Service S
	WHERE S.CountryCode = 'BE'


	--APPLY FRENCH DEFAULT IF NO LANGUAGE CODE GIVEN
	UPDATE S
	SET LanguageID = CASE 
						WHEN S.PreferredLanguage = 'FR' THEN (SELECT LanguageID FROM [$(SampleDB)].dbo.Languages WHERE ISOAlpha2 ='FR')
						WHEN S.PreferredLanguage = 'NL' THEN (SELECT LanguageID FROM [$(SampleDB)].dbo.Languages WHERE ISOAlpha2 ='NL')
						ELSE (SELECT LanguageID FROM [$(SampleDB)].dbo.Languages WHERE ISOAlpha2 ='FR')--DEFAULT TO FRENCH
					 END
	FROM Stage.LandRover_Belgium_Service S
	WHERE S.CountryCode = 'LU'

	--V1.3
	--Move misaligned model year records to holding table then remove from staging.
	--Fix for IPSOS – also remove blank records loaded
	IF EXISTS( 
				
			SELECT ModelYear 
			FROM   Stage.LandRover_Belgium_Service
			WHERE (ISNUMERIC(ModelYear) <> 1
			AND ModelYear <> '')
			OR (CONVERT(BIGINT, ModelYear) > 9999)
			OR LEN(ISNULL(CAST([Manufacturer] AS NVARCHAR),'') + '-' 
			+ ISNULL(CAST([CountryCode] AS NVARCHAR),'') + '-' 
			+ ISNULL(CAST([EventType] AS NVARCHAR),'')) < 5
				
			 )			 
	BEGIN 
			--MOove misaligned model year records to holding table then remove from staging.
			INSERT INTO	Stage.Removed_Records_Staging_Tables (AuditID, FileName, ActionDate, PhysicalFileRow, VIN, Misaligned_ModelYear)
			SELECT	I.AuditID, F.FileName, F.ActionDate, I.PhysicalRowID, I.VIN, I.ModelYear
			FROM	Stage.LandRover_Belgium_Service I
			INNER JOIN [$(AuditDB)].DBO.Files F ON I.AuditID = F.AuditID
			WHERE (ISNUMERIC(I.ModelYear) <> 1
			AND I.ModelYear <> '')
			OR (CONVERT(BIGINT, I.ModelYear) > 9999)
			OR LEN(ISNULL(CAST(I.[Manufacturer] AS NVARCHAR),'') + '-' 
			+ ISNULL(CAST(I.[CountryCode] AS NVARCHAR),'') + '-' 
			+ ISNULL(CAST(I.[EventType] AS NVARCHAR),'')) < 5
			
			DELETE 
			FROM   Stage.LandRover_Belgium_Service
			WHERE (ISNUMERIC(ModelYear) <> 1
			AND ModelYear <> '')
			OR (CONVERT(BIGINT, ModelYear) > 9999)
			OR LEN(ISNULL(CAST([Manufacturer] AS NVARCHAR),'') + '-' 
			+ ISNULL(CAST([CountryCode] AS NVARCHAR),'') + '-' 
			+ ISNULL(CAST([EventType] AS NVARCHAR),'')) < 5

	END 
	

	--V1.5
	INSERT INTO [dbo].[Removed_Records_Prevent_PartialLoad] (AuditID, FileName, ActionDate, PhysicalFileRow, VIN, CountryCode, RemovalReason)
	SELECT 
		S.[AuditID], 
		F.[FileName], 
		F.[ActionDate],
		S.[PhysicalRowID],
		S.[VIN], 
		S.[CountryCode], 
		'Invalid Country Code'
	FROM Stage.LandRover_Belgium_Service S
	INNER JOIN [$(AuditDB)].dbo.Files F ON S.AuditID = F.AuditID
	WHERE S.CountryCode NOT IN ('BE', 'LU')
	OR LEN(ISNULL(S.CountryCode, '')) = 0

	
	DELETE S
	FROM Stage.LandRover_Belgium_Service S
	WHERE S.CountryCode NOT IN ('BE', 'LU')
	OR LEN(ISNULL(S.CountryCode, '')) = 0

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
		INTO [$(ErrorDB)].Stage.LandRover_Belgium_Service_' + @TimestampString + '
		FROM Stage.LandRover_Belgium_Service
	')
	
	-- FINALLY RAISE THE ERROR
	RAISERROR ( @ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine )
END CATCH