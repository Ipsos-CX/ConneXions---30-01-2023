CREATE PROCEDURE [CaseUpdate].[uspLostLeadResponseFile_Insert]


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
	Purpose:	Insert from ResponseLoad.LostLeadResponseFile into Event.CaseLostLeadReponses
	
	Version		Date			Developer			Comment
	1.0			14-02-2018		Chris Ross			Original version (BUG 14413)
	1.1			10-01-2020		Chris Ledger		BUG 15372 - Fix Hard coded references to databases
*/

	BEGIN TRAN


		-- Check the CaseID and PartyID combination is valid
		UPDATE RF
		SET RF.CasePartyCombinationValid = 1
		FROM CaseUpdate.LostLeadResponseFile RF
		INNER JOIN [$(SampleDB)].Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = RF.CaseID
										AND AEBI.PartyID = RF.PartyID


		-- Set single datetime for update
		DECLARE @date   DATETIME2
		SET @date = GETDATE()

		-- Add the new person details to the
		INSERT INTO [$(SampleDB)].Event.CaseLostLeadResponses
		(
			CaseID, 
			LoadedToConnexions,
			ResponseDate, 
			LeadStatus, 
			ReasonsCode, 
			ResurrectedFlag, 
			BoughtElsewhereCompetitorFlag, 
			BoughtElsewhereJLRFlag, 
			VehicleLostBrand, 
			VehicleLostModelRange
		)
		SELECT DISTINCT
			CaseID, 
			@date AS LoadedToConnexions,
			CONVERT(DATETIME, STUFF(STUFF(STUFF(ResponseDate, 9, 0, ' '), 12, 0,  ':'), 15, 0, ':')) AS ResponseDate, 
			LeadStatus, 
			ReasonsCode, 
			ResurrectedFlag, 
			BoughtElsewhereCompetitorFlag, 
			BoughtElsewhereJLRFlag, 
			VehicleLostBrand, 
			VehicleLostModelRange	
		FROM CaseUpdate.LostLeadResponseFile
		WHERE CasePartyCombinationValid = 1

	 
		-- Set the processed date for auditing
		UPDATE RF
		SET DateProcessed = @date
		FROM CaseUpdate.LostLeadResponseFile RF
		WHERE RF.CasePartyCombinationValid = 1
		
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


