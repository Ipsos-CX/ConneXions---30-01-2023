CREATE TRIGGER ContactMechanism.TR_I_vwDA_ContactMechanisms ON ContactMechanism.vwDA_ContactMechanisms
INSTEAD OF INSERT

AS

/*
	Purpose:	Handles insert into vwDA_ContactMechanisms
				Those that are 'parents' and have not been matched are used to populate ContactMechanism
				All rows are written to the Audit.ContactMechanisms table
				
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created from [Prophet-ODS].dbo.vwDA_ContactMechanisms.TR_I_vwDA_ContactMechanisms

*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	-- INSERT INTO ContactMechanisms WHERE NOT ALREADY EXISTS
	INSERT INTO ContactMechanism.ContactMechanisms
	(
		ContactMechanismID, 
		ContactMechanismTypeID, 
		Valid
	)
	SELECT DISTINCT
		I.ContactMechanismID, 
		I.ContactMechanismTypeID, 
		I.Valid
	FROM INSERTED I
	LEFT JOIN ContactMechanism.ContactMechanisms CM ON CM.ContactMechanismID = I.ContactMechanismID
	WHERE CM.ContactMechanismID IS NULL

	-- INSERT INTO Audit.ContactMechanisms WHERE NOT ALREADY EXISTS
	INSERT INTO [$(AuditDB)].Audit.ContactMechanisms
	(
		AuditItemID, 
		ContactMechanismID, 
		ContactMechanismTypeID, 
		Valid
	)
	SELECT DISTINCT
		I.AuditItemID,
		I.ContactMechanismID, 
		I.ContactMechanismTypeID, 
		I.Valid
	FROM INSERTED I
	LEFT JOIN [$(AuditDB)].Audit.ContactMechanisms ACM ON I.AuditItemID = ACM.AuditItemID
													AND I.ContactMechanismID = ACM.ContactMechanismID
	WHERE ACM.AuditItemID IS NULL

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


