CREATE TRIGGER ContactMechanism.TR_I_vwDA_PartyPostalAddresses ON ContactMechanism.vwDA_PartyPostalAddresses
INSTEAD OF INSERT

AS

/*
	Purpose:	Handles insert into vwDA_PartyPostalAddresses
				All rows in VWT containing postal address information should be inserted into ContactMechanism.PartyContactMechanisms.
				All rows are written to the PartyContactMechanisms table
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created from [Prophet-ODS].dbo.vwDA_PartyPostalAddresses.TR_I_vwDA_PartyPostalAddresses

*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	INSERT INTO ContactMechanism.vwDA_PartyContactMechanisms
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
	FROM INSERTED
	ORDER BY ContactMechanismID, PartyID

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