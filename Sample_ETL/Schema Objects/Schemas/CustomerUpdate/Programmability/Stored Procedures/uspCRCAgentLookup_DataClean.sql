CREATE PROCEDURE [CustomerUpdate].[uspCRCAgentLookup_DataClean]
/* Purpose:	Remove any invalid ASCII characters from the imported Excel data
	
	Version			Date			Developer			Comment
	1.0				25/03/2020		Eddie Thomas		Created
*/
AS
SET NOCOUNT ON

	DECLARE @ErrorNumber INT
	DECLARE @ErrorSeverity INT
	DECLARE @ErrorState INT
	DECLARE @ErrorLocation NVARCHAR(500)
	DECLARE @ErrorLine INT
	DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY
	
		-- STRIP ANY SPECIAL CHARACTERS
		UPDATE	CustomerUpdate.CRCAgentLookUp 
		SET		Code		= [dbo].[udfReplaceASCII](Code),
				FullName	= [dbo].[udfReplaceASCII](FullName),
				FirstName	= [dbo].[udfReplaceASCII](FirstName),
				Brand		= [dbo].[udfReplaceASCII](Brand),
				MarketCode	= [dbo].[udfReplaceASCII](MarketCode)
		
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

GO
