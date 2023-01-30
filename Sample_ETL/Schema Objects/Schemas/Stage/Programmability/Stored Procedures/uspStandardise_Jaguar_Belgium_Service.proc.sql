CREATE PROCEDURE Stage.uspStandardise_Jaguar_Belgium_Service
AS

/*
	Purpose:	Convert the service date from a text string to a valid DATETIME type
	
	Version		Date			Developer			Comment
	1.0			11/03/2014		Martin Riverol		Created
	1.1			22/02/2017		Chris Ledger		BUG 13444: Add Check on OwnershipCycle
	1.2			15/02/2021		Ben King			BUG 18106 - Belgium Preferred Language
	1.3         13/05/2021      Ben King            BUG 18200 - Belgium Service Loader - Remove Non-applicable countryCodes
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

	UPDATE Stage.Jaguar_Belgium_Service
	SET VehiclePurchaseDateConverted = VehiclePurchaseDate
	WHERE ISDATE(VehiclePurchaseDate) = 1
	AND LEN(VehiclePurchaseDate) = 10
	
	UPDATE Stage.Jaguar_Belgium_Service
	SET VehicleRegistrationDateConverted = VehicleRegistrationDate
	WHERE ISDATE(VehicleRegistrationDate) = 1
	AND LEN(VehicleRegistrationDate) = 10
	
	UPDATE Stage.Jaguar_Belgium_Service
	SET VehicleDeliveryDateConverted = VehicleDeliveryDate
	WHERE ISDATE(VehicleDeliveryDate) = 1
	AND LEN(VehicleDeliveryDate) = 10
	
	UPDATE Stage.Jaguar_Belgium_Service
	SET ServiceEventDateConverted = ServiceEventDate
	WHERE ISDATE(ServiceEventDate) = 1
	AND LEN(ServiceEventDate) = 10

	----------------------------------------------------------------------------
	-- SET OwnershipCycle TO 0 IF NULL
	----------------------------------------------------------------------------
	UPDATE Stage.Jaguar_Belgium_Service
	SET OwnershipCycle = 0
	WHERE ISNULL(NULLIF(OwnershipCycle,''),0) = 0

	--V1.2
	--NO DEFULAT PERMITTED FOR BELGIUM
	UPDATE S
	SET LanguageID = CASE 
						WHEN S.PreferredLanguage = 'FR' THEN (SELECT LanguageID FROM [$(SampleDB)].dbo.Languages WHERE ISOAlpha2 ='FR')
						WHEN S.PreferredLanguage = 'NL' THEN (SELECT LanguageID FROM [$(SampleDB)].dbo.Languages WHERE ISOAlpha2 ='NL')
						ELSE 0
					 END
	FROM Stage.Jaguar_Belgium_Service S
	WHERE S.CountryCode = 'BE'


	--APPLY FRENCH DEFAULT IF NO LANGUAGE CODE GIVEN
	UPDATE S
	SET LanguageID = CASE 
						WHEN S.PreferredLanguage = 'FR' THEN (SELECT LanguageID FROM [$(SampleDB)].dbo.Languages WHERE ISOAlpha2 ='FR')
						WHEN S.PreferredLanguage = 'NL' THEN (SELECT LanguageID FROM [$(SampleDB)].dbo.Languages WHERE ISOAlpha2 ='NL')
						ELSE (SELECT LanguageID FROM [$(SampleDB)].dbo.Languages WHERE ISOAlpha2 ='FR')--DEFAULT TO FRENCH
					 END
	FROM Stage.Jaguar_Belgium_Service S
	WHERE S.CountryCode = 'LU'
	
	
	--V1.3
	INSERT INTO [dbo].[Removed_Records_Prevent_PartialLoad] (AuditID, FileName, ActionDate, PhysicalFileRow, VIN, CountryCode, RemovalReason)
	SELECT 
		S.[AuditID], 
		F.[FileName], 
		F.[ActionDate],
		S.[PhysicalRowID],
		S.[VIN], 
		S.[CountryCode], 
		'Invalid Country Code'
	FROM Stage.Jaguar_Belgium_Service S
	INNER JOIN [$(AuditDB)].dbo.Files F ON S.AuditID = F.AuditID
	WHERE S.CountryCode NOT IN ('BE', 'LU')
	OR LEN(ISNULL(S.CountryCode, '')) = 0

	
	DELETE S
	FROM Stage.Jaguar_Belgium_Service S
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
		INTO [$(ErrorDB)].Stage.Jaguar_Belgium_Service_' + @TimestampString + '
		FROM Stage.Jaguar_Belgium_Service
	')
	
	-- FINALLY RAISE THE ERROR
	RAISERROR ( @ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine )
END CATCH