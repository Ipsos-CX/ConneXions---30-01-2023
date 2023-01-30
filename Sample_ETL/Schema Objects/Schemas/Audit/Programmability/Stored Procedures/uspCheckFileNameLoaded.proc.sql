CREATE PROC [Audit].uspCheckFileNameLoaded
	@FileName VARCHAR(100)
AS


SET NOCOUNT ON

	DECLARE @ErrorNumber INT
	DECLARE @ErrorSeverity INT
	DECLARE @ErrorState INT
	DECLARE @ErrorLocation NVARCHAR(500)
	DECLARE @ErrorLine INT
	DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

/*
	Purpose:	Checks to see if a file with the same name has previously been loaded successfully.
	
	Version			Date			Developer					Comment
	1.0				11/09/2015		Peter Doyle/Chris Ross		Original version

*/

        IF EXISTS ( SELECT  F.AuditID
                    FROM    [$(AuditDB)].dbo.Files F
                            INNER JOIN [$(AuditDB)].dbo.IncomingFiles I ON F.AuditID = I.AuditID
                    WHERE   FileName = @FileName
                            AND LoadSuccess = 1 )
            BEGIN
                SELECT  CONVERT(BIT, 1) AS FileExists;
            END;
        ELSE
            BEGIN
                SELECT  CONVERT(BIT, 0) AS FileExists;
            END;


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
