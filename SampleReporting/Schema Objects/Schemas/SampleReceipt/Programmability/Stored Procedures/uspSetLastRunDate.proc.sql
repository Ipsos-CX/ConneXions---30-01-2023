CREATE PROCEDURE SampleReceipt.uspSetLastRunDate

AS

SET NOCOUNT ON;

DECLARE @ErrorNumber INT;
DECLARE @ErrorSeverity INT;
DECLARE @ErrorState INT;
DECLARE @ErrorLocation NVARCHAR(500);
DECLARE @ErrorLine INT;
DECLARE @ErrorMessage NVARCHAR(2048);

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

BEGIN TRY



/*
	Purpose:	Set the last run date value in the CRM.SystemValues table.
		
	Version		Date				Developer			Comment
	1.0			10/07/2017			Chris Ross			Created

*/


		------------------------------------------------------------------
		-- Set the last run date
		------------------------------------------------------------------

		UPDATE SampleReceipt.SystemValues 
		SET LastRunDate = GETDATE()




END TRY

BEGIN CATCH

    SELECT  @ErrorNumber = ERROR_NUMBER() ,
            @ErrorSeverity = ERROR_SEVERITY() ,
            @ErrorState = ERROR_STATE() ,
            @ErrorLocation = ERROR_PROCEDURE() ,
            @ErrorLine = ERROR_LINE() ,
            @ErrorMessage = ERROR_MESSAGE();

    EXEC [$(ErrorDB)].[dbo].uspLogDatabaseError @ErrorNumber,
        @ErrorSeverity, @ErrorState, @ErrorLocation, @ErrorLine,
        @ErrorMessage;
	
    RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine);
	
END CATCH;
