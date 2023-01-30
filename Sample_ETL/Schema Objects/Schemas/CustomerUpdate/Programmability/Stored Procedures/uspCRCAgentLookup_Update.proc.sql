CREATE PROCEDURE [CustomerUpdate].[uspCRCAgentLookup_Update]

AS

SET NOCOUNT ON 

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY


		-- UPDATE THE LOOKUP		
		UPDATE		LK
		SET			FirstName				= CRC.FirstName,
					Surname					= CRC.Surname,
					DisplayOnQuestionnaire	= CRC.DisplayOnQuestionnaire,
					DisplayOnWebsite		= CRC.DisplayOnWebsite,
					FullName				= CRC.FullName
				
		FROM		Lookup.CRCAgents_GlobalList LK
		INNER JOIN	Stage.CRCAgents_GlobalList	CRC ON	LK.CDSID		= CRC.CDSID  AND 
														LK.MarketCode	= CRC.MarketCode
		
		WHERE		CRC.ParentAuditItemID = CRC.AuditItemID


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