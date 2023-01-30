CREATE PROCEDURE Load.uspPartyPostalAddresses

AS

/*
	Purpose:	Write a link between the party and the postal address to the Sample database
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created from Prophet-ETL.dbo.uspODSLOAD_PartyPostalAddresses

*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	INSERT INTO [$(SampleDB)].ContactMechanism.vwDA_PartyPostalAddresses
	(
		AuditItemID, 
		ContactMechanismID, 
		PartyID, 
		FromDate, 
		ContactMechanismPurposeTypeID, 
		RoleTypeID
	)
	SELECT 
		AuditItemID, 
		ContactMechanismID, 
		PartyID, 
		FromDate, 
		ContactMechanismPurposeTypeID,
		RoleTypeID
	FROM Load.vwPartyPostalAddresses
	ORDER BY AuditItemID
		
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