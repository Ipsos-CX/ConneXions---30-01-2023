CREATE TRIGGER Party.TR_I_vwDA_TitleVariations ON [Party].[vwDA_TitleVariations] 
INSTEAD OF INSERT
AS

/*
	Purpose:	Inserts into TitleVariations
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created from [Prophet-ODS].dbo.vwDA_PreNominalTitleVariations.TR_I_vwDA_PreNominalTitleVariations

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

		INSERT INTO Party.TitleVariations
		(
			TitleID, 
			TitleVariation
		)
		SELECT DISTINCT
			I.TitleID, 
			I.TitleVariation
		FROM INSERTED I
		LEFT JOIN Party.TitleVariations TV ON I.TitleID = TV.TitleID
										AND ISNULL(I.TitleVariation, N'') = ISNULL(TV.TitleVariation, N'')
		WHERE TV.TitleVariationID IS NULL
	
		INSERT INTO [$(AuditDB)].Audit.TitleVariations
		(
			AuditItemID, 
			TitleVariationID, 
			TitleID, 
			TitleVariation
		)
		SELECT DISTINCT
			I.AuditItemID, 
			TV.TitleVariationID, 
			I.TitleID, 
			I.TitleVariation
		FROM INSERTED I
		INNER JOIN Party.TitleVariations TV ON I.TitleID = TV.TitleID
									AND ISNULL(I.TitleVariation, N'') = ISNULL(TV.TitleVariation, N'')	
									
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
