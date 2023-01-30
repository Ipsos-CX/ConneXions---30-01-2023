CREATE  PROCEDURE [dbo].[uspVWT_StandardiseVehicleIdentificationNumberUsable]

AS

/*
		Purpose:	Sets the VehicleIdentificationNumberUsable in the VWT based on VIN	
	
		Version		Date			Developer			Comment
LIVE	1.0			2022-03-17		Chris Ledger		Created
*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	UPDATE V
	SET V.VehicleIdentificationNumber = RTRIM(LTRIM(V.VehicleIdentificationNumber)),
		V.VehicleIdentificationNumberUsable = CASE	WHEN LEN(RTRIM(LTRIM(V.VehicleIdentificationNumber))) = 17 AND V.VehicleIdentificationNumber NOT LIKE '%[^a-zA-Z0-9]%' THEN 1
													ELSE 0 END
	FROM dbo.VWT V
	
	

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