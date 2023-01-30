CREATE PROCEDURE [OWAP].[uspGetSelectionFileName]
(
	@SelectionRequirementID dbo.RequirementID
)

AS

/*
	Purpose:	Returns a file name for a given selection for download from the OWAP
		
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

	DECLARE @DateStamp VARCHAR(8)
	DECLARE @Date DATETIME2

	SET @Date = GETDATE()

	SET @DateStamp = CAST(YEAR(@Date) AS CHAR(4)) +
					CASE LEN(CAST(MONTH(@Date) AS VARCHAR(2))) WHEN 1 THEN '0' + CAST(MONTH(@Date) AS CHAR(1)) ELSE CAST(MONTH(@Date) AS CHAR(2)) END + 
					CASE LEN(CAST(DAY(@Date) AS VARCHAR(2))) WHEN 1 THEN '0' + CAST(DAY(@Date) AS CHAR(1)) ELSE CAST(DAY(@Date) AS CHAR(2)) END

	SELECT S.Requirement + '_' + @DateStamp + '.txt'
	FROM Requirement.SelectionRequirements SR
	INNER JOIN Requirement.Requirements S ON S.RequirementID = SR.RequirementID
	WHERE SR.RequirementID = @SelectionRequirementID

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




