CREATE PROCEDURE Stage.uspStandardise_LandRover_UK_Service_LoyaltyLogistix
AS

/*
	Purpose:	Convert the service date from a text string to a valid DATETIME type
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)	Chris Ross			Initial version
	1.1				03/04/2019		Ben King			BUG 15311 - Prevent partial file loads (UAT)
	1.2				16/12/2019		Chris Ledger		BUG 16840 - Set OwnershipCycle to '' when 'NULL'
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

	UPDATE	Stage.LandRover_UK_Service_LoyaltyLogistix
	SET		ConvertedVehicleDeliveryDate = CONVERT( DATETIME, VehicleDeliveryDate )
	WHERE	isdate ( VehicleDeliveryDate ) = 1
	AND		LEN(VehicleDeliveryDate) >= 8

	UPDATE	Stage.LandRover_UK_Service_LoyaltyLogistix
	SET		ConvertedVehicleRegistrationDate = convert( DATETIME, VehicleRegistrationDate )
	WHERE	ISDATE( VehicleRegistrationDate ) = 1
	AND		LEN( VehicleRegistrationDate ) >= 8
	
	UPDATE	Stage.LandRover_UK_Service_LoyaltyLogistix
	SET		ConvertedServiceEventDate = CONVERT( DATETIME, ServiceEventDate )
	WHERE	ISDATE( ServiceEventDate ) = 1
	AND		LEN( ServiceEventDate ) >= 8
	
	UPDATE	Stage.LandRover_UK_Service_LoyaltyLogistix
	SET		ConvertedVehiclePurchaseDate = CONVERT( DATETIME, VehiclePurchaseDate )
	WHERE	ISDATE( VehiclePurchaseDate ) = 1
	AND		LEN( VehiclePurchaseDate ) >= 8


	--V1.1 Check Model Year is numeric. If not, when appended to VWT, data flow will fail.
	IF EXISTS( 
				
			SELECT ModelYear 
			FROM   Stage.LandRover_UK_Service_LoyaltyLogistix
			WHERE (ISNUMERIC(ModelYear) <> 1
			AND ModelYear <> '')
			OR CONVERT(BIGINT, ModelYear) > 9999
				
			 )			 
	BEGIN 
			--Move misaligned model year records to holding table then remove from staging.
			INSERT INTO	Stage.Removed_Records_Staging_Tables (AuditID, FileName, ActionDate, PhysicalFileRow, VIN, Misaligned_ModelYear)
			SELECT	LL.AuditID, F.FileName, F.ActionDate, LL.PhysicalRowID, LL.VIN, LL.ModelYear
			FROM	Stage.LandRover_UK_Service_LoyaltyLogistix LL
			INNER JOIN [$(AuditDB)].DBO.Files F ON LL.AuditID = F.AuditID
			WHERE (ISNUMERIC(LL.ModelYear) <> 1
			AND LL.ModelYear <> '')
			OR CONVERT(BIGINT, LL.ModelYear) > 9999
			
			DELETE 
			FROM   Stage.LandRover_UK_Service_LoyaltyLogistix
			WHERE (ISNUMERIC(ModelYear) <> 1
			AND ModelYear <> '')
			OR CONVERT(BIGINT, ModelYear) > 9999

	END 

	-- V1.2 Set OwnershipCycle to '' when 'NULL'
	UPDATE	Stage.LandRover_UK_Service_LoyaltyLogistix
	SET		OwnershipCycle = ''
	WHERE	OwnershipCycle = 'NULL'


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
		INTO [$(ErrorDB)].Stage.Jaguar_Australia_Service_' + @TimestampString + '
		FROM Stage.Jaguar_Australia_Service
	')
	
	-- FINALLY RAISE THE ERROR
	RAISERROR ( @ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine )
		
END CATCH




