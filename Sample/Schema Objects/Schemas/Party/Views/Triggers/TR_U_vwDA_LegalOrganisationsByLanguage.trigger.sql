CREATE TRIGGER [Party].[TR_U_vwDA_LegalOrganisationsByLanguage] ON [Party].[vwDA_LegalOrganisationsByLanguage]

INSTEAD OF UPDATE
AS 

/*
-- Purpose: Handles update to vwDA_LegalOrganisationsByLanguage (LegalOrganisationByLanguage tables and associated audit tables)
--
-- Version		Date			Developer			Comment
--
-- 1.0			2017-05-19		Chris Ledger		Created
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

		-- UPDATE LegalOrganisationsByLanguage		
		UPDATE LOL
			SET LOL.LegalName = I.LegalName
		FROM Party.LegalOrganisationsByLanguage LOL
		INNER JOIN INSERTED AS I ON LOL.PartyID = I.PartyID
								AND LOL.LanguageID = I.LanguageID

					
		-- ADD THE AUDIT INFO
		INSERT INTO [$(AuditDB)].Audit.LegalOrganisationsByLanguage
			(
				AuditItemID, 
				PartyID, 
				LegalName,
				LanguageID
			)
		SELECT
			I.AuditItemID, 
			I.PartyID, 
			I.LegalName,
			I.LanguageID
		FROM INSERTED AS I

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
	