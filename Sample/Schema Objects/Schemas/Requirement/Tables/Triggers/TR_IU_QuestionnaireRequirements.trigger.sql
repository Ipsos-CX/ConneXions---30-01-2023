CREATE TRIGGER Requirement.TR_UI_QuestionnaireRequirements
ON Requirement.QuestionnaireRequirements
AFTER UPDATE
AS

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	-- Check if the ValidSalesType flag has been updated from 0/NULL to 1 and if the ValidateSaleTypeFromDate has remained NULL 
	-- If both criteria are true then populate the ValidatesaleTypeFromDate column with today's date
		
		UPDATE qr
			SET qr.ValidateSaleTypeFromDate = GETDATE()
		FROM INSERTED i
		INNER JOIN Requirement.QuestionnaireRequirements qr ON qr.RequirementID = i.RequirementID
		INNER JOIN DELETED d ON d.RequirementID = i.RequirementID   -- we do inner join to ensure only records being updated are included
		WHERE ISNULL(i.ValidateSaleTypes, 0) = 1
		  AND ISNULL(d.ValidateSaleTypes, 0) = 0
		  AND i.ValidateSaleTypeFromDate IS NULL
		  AND d.ValidateSaleTypeFromDate IS NULL

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
