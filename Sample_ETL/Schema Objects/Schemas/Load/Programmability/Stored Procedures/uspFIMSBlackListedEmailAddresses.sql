CREATE PROCEDURE [Load].[uspFIMSBlackListedEmailAddresses]

AS

/*
	Purpose:	Load Black Listed emails from FIMs file
	
	Release		Version			Date			Developer			Comment
	LIVE		1.0				2022-05-12		Ben King    		TASK 866 - 19490 - Add JLR Employees to the Excluded Email list
	LIVE		1.1				2022-05-13		Ben King			TASK 887 - Filter out URLs coming in the FIMs email address field when adding to the exclusion list
	
	 
*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

			TRUNCATE TABLE Stage.FIMSBlackListEmail
		
			INSERT INTO Stage.FIMSBlackListEmail (AuditID, AuditItemID, PhysicalRowID, Email, Operator, BlacklistTypeID, ContactMechanismTypeID, FromDate)
			SELECT DISTINCT
					F.AuditID,
					F.AuditItemID,
					F.PhysicalRowID,
					LTRIM(RTRIM(F.Email)),
					'=' AS Operator,
					(SELECT BlacklistTypeID FROM [$(SampleDB)].ContactMechanism.BlacklistTypes WHERE BlacklistType = 'Dealer specific email address - manually added') AS BlacklistTypeID,
					(SELECT [ContactMechanismTypeID] FROM [$(SampleDB)].[ContactMechanism].[ContactMechanismTypes] WHERE ContactMechanismType = 'E-mail address') AS ContactMechanismTypeID,
					GETDATE() AS FromDate
			FROM	Stage.Franchise_Hierarchy	F
			WHERE	F.Email NOT LIKE '%https://%' --V1.1


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