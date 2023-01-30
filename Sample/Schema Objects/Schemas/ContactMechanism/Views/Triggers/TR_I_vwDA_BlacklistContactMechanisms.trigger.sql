CREATE TRIGGER ContactMechanism.TR_I_vwDA_BlacklistContactMechanisms ON ContactMechanism.vwDA_BlacklistContactMechanisms
INSTEAD OF INSERT

AS

/*
	Purpose:	Write new blacklisted ContactMechanisms and insert all matched blacklist rows into audit table.
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created from [Prophet-ODS].dbo.vwDA_vwDA_BlacklistContactMechanisms.TR_I_vwDA_vwDA_BlacklistContactMechanisms

*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	BEGIN TRAN

		-- DECLARE LOCAL VARIABLES
		DECLARE @CurrentTimestamp DATETIME2

		-- INITIALISE LOCAL VARIABLES
		SET @CurrentTimestamp = CURRENT_TIMESTAMP

		-- INSERT INTO BlacklistContactMechanisms
		INSERT INTO ContactMechanism.BlacklistContactMechanisms
		(	
			ContactMechanismID,
			ContactMechanismTypeID,
			BlacklistStringID,
			FromDate
		)
		SELECT DISTINCT
			I.ContactMechanismID,
			I.ContactMechanismTypeID,
			I.BlacklistStringID,
			@CurrentTimestamp
		FROM INSERTED I
		LEFT JOIN ContactMechanism.BlacklistContactMechanisms BCM ON I.ContactMechanismID = BCM.ContactMechanismID
																AND I.ContactMechanismTypeID = BCM.ContactMechanismTypeID
																AND I.BlacklistStringID = BCM.BlacklistStringID
		WHERE BCM.ContactMechanismID IS NULL

		-- INSERT INTO Audit.BlacklistContactMechanisms
		INSERT INTO [$(AuditDB)].Audit.BlacklistContactMechanisms
		(	
			AuditItemID,
			ContactMechanismID,
			ContactMechanismTypeID,
			BlacklistStringID,
			FromDate
		)
		SELECT DISTINCT
			AuditItemID,
			ContactMechanismID,
			ContactMechanismTypeID,
			BlacklistStringID,
			@CurrentTimestamp
		FROM INSERTED 
		
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