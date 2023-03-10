CREATE TRIGGER [OWAP].[TR_I_vwUsers]
    ON [OWAP].[vwUsers]
    INSTEAD OF INSERT
    AS SET NOCOUNT ON
--
-- Insert OWAP user details
--
DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	BEGIN TRAN

		INSERT INTO [Party].[PartyRoles] 
		(
			PartyID,
			RoleTypeID,
			FromDate
		)
		SELECT
			i.PartyID,
			i.RoleTypeID,
			GETDATE()
		FROM inserted i

		INSERT INTO [OWAP].[Users]
		(
			[PartyID],
			[Password],
			[RoleTypeID],
			[UserName]
		)
		SELECT
			i.PartyID,
			i.Password,
			i.RoleTypeID,
			i.UserName
		FROM inserted i
		
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

