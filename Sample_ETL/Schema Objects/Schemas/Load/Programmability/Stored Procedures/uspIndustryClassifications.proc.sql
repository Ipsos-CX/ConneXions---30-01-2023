CREATE PROCEDURE [Load].[uspIndustryClassifications]

AS

/*
	Purpose:	Write IndustryClassifications data to Sample database
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)	Simon Peacock		Created from [Prophet-ETL].dbo.uspODSLOAD_IndustryClassifications
	1.1				09-12-2019		Chris Ross			BUG 16810 - Pass PartyExclusionCategoryID value into Party.vwDA_IndustryClassifications	
	1.2				10-01-2020		Chris Ledger		BUG 15372 - Fix Hard coded references to databases
*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	INSERT INTO [$(SampleDB)].Party.vwDA_IndustryClassifications
	(
		AuditItemID, 
		PartyTypeID, 
		PartyID, 
		FromDate, 
		ThroughDate,
		PartyExclusionCategoryID		-- v1.1
	)
	SELECT
		AuditItemID, 
		PartyTypeID, 
		PartyID, 
		FromDate, 
		ThroughDate,
		PartyExclusionCategoryID		-- v1.1
	FROM Load.vwIndustryClassifications

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
