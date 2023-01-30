CREATE PROCEDURE [CustomerUpdate].[uspExtraVehicleFeed_Update]

AS

/*
	Purpose:	Updates Vehicle.ExtraVehicleFeed
	
	Version			Date				Developer			Comment										Status
	1.0				2017-04-21			Chris Ledger		Update										LIVE
	1.1				2017-08-23			Chris Ledger		BUG 14189 - Remove superfluous fields		DEPLOYED LIVE: CL 2017-08-25
	1.2				2020-01-10			Chris Ledger		BUG 15372 - Fix Hard coded references to databases
	1.3				2020-03-13			Chris Ledger		BUG 18002 - Add Powertrain
	1.4				2021-03-29			Chris Ledger		Remove Powertrain
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
	

		-- UPDATE THE VEHICLE TABLE		
		UPDATE	V
		SET V.ProductionDate = C.ProductionDate,
			V.ProductionMonth = C.ProductionMonth,
			V.CountrySold = C.CountrySold,
			V.Plant = C.Plant,
			V.VehicleLine = C.VehicleLine,
			V.ModelYear = C.ModelYear,
			V.BodyStyle = C.BodyStyle,
			V.Drive = C.Drive,
			V.Transmission = C.Transmission,
			V.Engine = C.Engine
		FROM [$(SampleDB)].Vehicle.ExtraVehicleFeed V
			INNER JOIN CustomerUpdate.ExtraVehicleFeed C ON V.VIN = C.VIN
		WHERE C.ParentAuditItemID = C.AuditItemID


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