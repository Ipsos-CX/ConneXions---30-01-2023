CREATE PROCEDURE [Load].[uspLegalOrganisations]

AS

/*
	Purpose:	Write Organisation parties to Sample database
	
	Version		Date			Developer			Comment
	1.0			$(ReleaseDate)	Simon Peacock		Created from [Prophet-ETL].dbo.uspODSLOAD_LegalOrganisations
	1.1			2021-06-04		Chris Ledger		Task 472: Add UseLatestName
*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	INSERT INTO [$(SampleDB)].Party.vwDA_LegalOrganisations
	(
		AuditItemID, 
		ParentAuditItemID, 
		PartyID, 
		FromDate, 
		OrganisationName, 
		LegalName,
		UseLatestName
	)
	SELECT
		AuditItemID, 
		ParentAuditItemID, 
		MatchedODSOrganisationID AS PartyID, 
		FromDate, 
		OrganisationName, 
		LegalName,
		UseLatestName
	FROM Load.vwLegalOrganisations

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