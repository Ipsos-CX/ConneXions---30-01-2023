CREATE PROCEDURE [Load].[uspTitles]
AS

/*
	Purpose:	Loads in any new titles to the sampling database and then reruns the standardisation to pick
				up the TitleIDs of the new titles
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created from [Prophet-ETL].dbo.uspODSLOAD_Titles

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

		INSERT INTO [$(SampleDB)].Party.vwDA_Titles
		(
			AuditItemID, 
			TitleID, 
			Title
		)
		SELECT 
			AuditItemID, 
			TitleID, 
			Title
		FROM dbo.vwVWT_Titles
		WHERE TitleID = 0

		-- UPDATE VWT WITH IDS OF TITLES JUST INSERTED
		EXEC dbo.uspVWT_StandardiseTitles
		
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