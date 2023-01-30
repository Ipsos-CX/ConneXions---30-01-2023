CREATE PROCEDURE [CustomerUpdate].[uspExtraVehicleFeed_Insert]

AS

/* 
	Purpose:		Insert new records into Vehicle.ExtraVehicleFeed table
	
	Version			Date			Developer			Comment										Status
	1.0				2017-04-21		Chris Ledger		Created										LIVE
	1.1				2017-08-23		Chris Ledger		BUG 14189 - Remove superfluous fields		DEPLOYED LIVE: CL 2017-08-25
	1.2				2020-03-13		Chris Ledger		BUG 18002 - Add Powertrain
	1.3				2021-03-29		Chris Ledger		Remove Powertrain

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
	
		-- ADD THE NEW ITEMS TO THE VEHICLE ExtraVehicleFeed table
		INSERT INTO [$(SampleDB)].Vehicle.ExtraVehicleFeed
		(
			VIN,
			ProductionDate,
			ProductionMonth,
			CountrySold,
			Plant,
			VehicleLine,
			ModelYear,
			BodyStyle,
			Drive,
			Transmission,
			Engine
		)
		SELECT C.VIN,
			C.ProductionDate,
			C.ProductionMonth,
			C.CountrySold,
			C.Plant,
			C.VehicleLine,
			C.ModelYear,
			C.BodyStyle,
			C.Drive,
			C.Transmission,
			C.Engine
		FROM CustomerUpdate.ExtraVehicleFeed C
		LEFT JOIN [$(SampleDB)].Vehicle.ExtraVehicleFeed V ON C.VIN = V.VIN												 		
		WHERE V.VIN IS NULL
			AND C.AuditItemID = C.ParentAuditItemID		

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

