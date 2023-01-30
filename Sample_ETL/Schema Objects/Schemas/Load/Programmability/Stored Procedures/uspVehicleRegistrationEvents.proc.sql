CREATE PROCEDURE Load.uspVehicleRegistrationEvents

AS

/*
	Purpose:	Write the link between the Registration Number, the Vehicle and the Event to the Sample database
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created from [Prophet-ETL].dbo.uspODSLOAD_VehicleRegistrationEvents

*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	INSERT INTO [$(SampleDB)].Vehicle.vwDA_VehicleRegistrationEvents
	(
		AuditItemID,
		VehicleID,
		RegistrationID,
		EventID,
		RegNumber,
		RegistrationDate,
		RegistrationDateOrig
	)
	SELECT
		AuditItemID,
		MatchedODSVehicleID AS VehicleID,
		ODSRegistrationID AS RegistrationID,
		MatchedODSEventID AS EventID,
		VehicleRegistrationNumber AS RegNumber,
		RegistrationDate,
		RegistrationDateOrig
	FROM Load.vwVehicleRegistrationEvents
	
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


