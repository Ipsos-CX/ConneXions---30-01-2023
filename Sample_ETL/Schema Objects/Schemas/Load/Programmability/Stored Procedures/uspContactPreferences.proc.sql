CREATE PROCEDURE [Load].[uspContactPreferences]
AS
SET NOCOUNT ON


/*
	Purpose:	Write the Contact Preferences to the Sample database
	
	Version			Date			Developer			Comment
	1.0				01-12-2016		Chris Ross			Created as part of BUG 13364
	1.1				10-01-2020		Chris Ledger		BUG 15372 - Fix Hard coded references to databases
*/


DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	INSERT INTO [$(SampleDB)].Party.vwDA_ContactPreferences
	(
	AuditItemID, 
	PartyID, 
	EventCategoryID, 
	PartySuppression, 
	PostalSuppression, 
	EmailSuppression, 
	PhoneSuppression, 
	UpdateSource,
	MarketCountryID
	)
	SELECT
		AuditItemID, 
		PartyID, 
		EventCategoryID, 
		PartySuppression, 
		PostalSuppression, 
		EmailSuppression, 
		PhoneSuppression, 
		UpdateSource,
		CountryID AS MarketCountryID	
	FROM Load.vwContactPreferences

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

