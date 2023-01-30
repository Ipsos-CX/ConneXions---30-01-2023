CREATE PROCEDURE [Load].[uspFlagSVOvehicles]

AS

/*
	Purpose: Updatr SVOTypeID in Vehicles table
	
	Version		Date			Developer			Comment
	1.1			2021-07-15		Chris Ledger		Task 552: Update SaleType
*/

SET NOCOUNT ON

	DECLARE @ErrorNumber INT
	DECLARE @ErrorSeverity INT
	DECLARE @ErrorState INT
	DECLARE @ErrorLocation NVARCHAR(500)
	DECLARE @ErrorLine INT
	DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	UPDATE VEH
	SET VEH.SVOTypeID = SVT.SVOTypeID 
	FROM [$(SampleDB)].Vehicle.Vehicles VEH
		INNER JOIN Lookup.SVOLookup LK ON VEH.VIN = LK.Vin
		LEFT JOIN dbo.SVOTypes SVT ON LTRIM(RTRIM(LK.SaleType)) = SVT.SVODescription	

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
