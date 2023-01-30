CREATE PROCEDURE [CaseUpdate].[uspCRMHeaderFile_Insert]


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
	Purpose:	Insert into from ResponseLoad.CRMHeader into Event.Case (and audit)

	
	Version		Date			Developer			Comment
	1.0			26-08-2015		Chris Ross			Original version
	1.1			10-01-2020		Chris Ledger		BUG 15372 - Fix Hard coded references to databases
*/

	BEGIN TRAN


		-- Check the CaseID and PartyID combination is valid
		UPDATE CH
		SET CH.CasePartyCombinationValid = 1
		--select * 
		FROM CaseUpdate.CRMHeaderFile CH
		INNER JOIN [$(SampleDB)].Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = CH.CaseID
										AND AEBI.PartyID = CH.PartyID


		-- Set single datetime for update
		DECLARE @date   DATETIME2
		SET @date = GETDATE()

		-- Add the new person details to the
		INSERT INTO [$(SampleDB)].Event.CaseCRM
		(
			CaseID, 
			ResponseDate, 
			RedFlag, 
			GoldFlag,
			LoadedToConnexions
		)
		SELECT DISTINCT
			CaseID, 
			ResponseDate, 
			CASE RedFlag WHEN 'Y' THEN 1 ELSE 0 END AS RedFlag, 
			CASE GoldFlag WHEN 'Y' THEN 1 ELSE 0 END AS GoldFlag,
			@date AS LoadedToConnexions
		FROM CaseUpdate.CRMHeaderFile CH
		WHERE CasePartyCombinationValid = 1

	 
		-- Set the processed date for auditing
		UPDATE CH
		SET DateProcessed = @date
		FROM CaseUpdate.CRMHeaderFile CH
		WHERE CH.CasePartyCombinationValid = 1

		
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


