CREATE PROCEDURE dbo.uspVWT_SetAddressChecksum
AS

/*
	Purpose:	Generate the AddressChecksum value that will be used for matching and loading
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created

*/


SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	UPDATE dbo.VWT
	SET AddressChecksum = dbo.udfGenerateAddressChecksum(BuildingName, SubStreetNumber, SubStreet, StreetNumber, Street, SubLocality, Locality, Town, Region, PostCode, CountryID)
	
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