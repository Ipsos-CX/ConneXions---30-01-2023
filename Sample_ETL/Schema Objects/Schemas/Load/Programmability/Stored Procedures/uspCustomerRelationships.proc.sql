CREATE PROCEDURE Load.uspCustomerRelationships

AS

/*
	Purpose:	Write customer relationships to Sample database
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created from [Prophet-ETL].dbo.uspODSLOAD_CustomerRelationships

*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	INSERT INTO [$(SampleDB)].Party.vwDA_CustomerRelationships
	(
		AuditItemID, 
		PartyIDFrom,
		RoleTypeIDFrom, 
		PartyIDTo, 
		RoleTypeIDTo, 	
		FromDate, 
		ThroughDate, 
		PartyRelationshipTypeID, 
		CustomerIdentifier, 
		CustomerIdentifierUsable
	)
	SELECT
		AuditItemID, 
		PartyIDFrom, 
		RoleTypeIDFrom, 
		PartyIDTo, 
		RoleTypeIDTo, 
		FromDate, 
		ThroughDate, 
		PartyRelationshipTypeID, 
		CustomerIdentifier, 
		CustomerIdentifierUsable
	FROM Load.vwCustomerRelationships

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