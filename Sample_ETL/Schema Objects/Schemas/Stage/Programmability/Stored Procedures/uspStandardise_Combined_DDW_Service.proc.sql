CREATE PROCEDURE [Stage].[uspStandardise_Combined_DDW_Service]

AS

/*
	Purpose:	Convert the service date from a text string to a valid DATETIME type
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created from [Prophet-ETL].dbo.uspSTANDARDISE_STAGE_Jaguar_Australia_Sales_Dates
	1.1				18/12/2013		Chris Ross			BUG 9611 - Add in formatting of columns as now loading differently from .xlsx file

*/

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

SET LANGUAGE ENGLISH
SET DATEFORMAT YMD

BEGIN TRY

	UPDATE Stage.Combined_DDW_Service
	SET ConvertedRepairDate = CAST(RepairDate AS DATETIME2)
	WHERE ISDATE(RepairDate) = 1

	-- Remove NULLs to bring in line with pre-existing CSV load			-- v1.1
	UPDATE Stage.Combined_DDW_Service
	SET ProgramCode = ISNULL(ProgramCode, '') 

	-- Round values imported from spreadsheet to stop numbers 
	-- like "8.1600000000000001" being imported.						-- v1.1
	UPDATE Stage.Combined_DDW_Service
	SET WIAA02_TOTAL_LABOR_A = CONVERT(VARCHAR(20), CAST(ROUND(WIAA02_TOTAL_LABOR_A,2)AS MONEY), 0) 
	WHERE ISNUMERIC(WIAA02_TOTAL_LABOR_A) = 1


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
		
		
	-- CREATE A COPY OF THE STAGING TABLE FOR USE IN PRODUCTION SUPPORT
	DECLARE @TimestampString CHAR(15)
	SELECT @TimestampString = [$(ErrorDB)].dbo.udfGetTimestampString(GETDATE())
	
	EXEC('
		SELECT *
		INTO [$(ErrorDB)].Stage.Combined_DDW_Service_' + @TimestampString + '
		FROM Stage.Combined_DDW_Service
	')
	
	-- FINALLY RAISE THE ERROR
	RAISERROR ( @ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine )

END CATCH
