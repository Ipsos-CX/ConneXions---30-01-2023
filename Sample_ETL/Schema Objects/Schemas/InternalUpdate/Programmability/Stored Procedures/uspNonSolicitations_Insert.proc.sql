CREATE PROCEDURE [InternalUpdate].[uspNonSolicitations_Insert]

AS

/*
	Purpose:	Add Party Non Solicitation
	Version		Date			Developer			Comment
	1.1			2017-03-03		Chris Ledger		BUG 13661 - Include Party.Nonsolicitation in check for existing Non Solicitation
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

		DECLARE @ProcessDate DATETIME
		SET @ProcessDate = GETDATE()


		-- CHECK THE PartyID
		UPDATE NS
		SET NS.PartyValid = 1
		FROM InternalUpdate.NonSolicitations NS
		INNER JOIN [$(SampleDB)].Party.Parties P ON NS.PartyID = P.PartyID
		LEFT JOIN [$(SampleDB)].Party.People PE ON P.PartyID = PE.PartyID
		LEFT JOIN [$(SampleDB)].Party.Organisations O ON P.PartyID = O.PartyID
		WHERE NS.DateProcessed IS NULL
		AND NS.AuditItemID = NS.ParentAuditItemID

		--SELECT * FROM InternalUpdate.NonSolicitations

		-- CHECK WHETHER NON SOLICITATION EXISTS
		UPDATE NS
		SET NS.ExistsAlready = 1
		--SELECT *
		FROM InternalUpdate.NonSolicitations NS
		INNER JOIN [$(SampleDB)].dbo.NonSolicitations N ON NS.PartyID = N.PartyID
		INNER JOIN [$(SampleDB)].Party.NonSolicitations PNS ON N.NonSolicitationID = PNS.NonSolicitationID	-- V1.1
		WHERE NS.DateProcessed IS NULL
		AND NS.AuditItemID = NS.ParentAuditItemID		-- NON DUPLICATE
		AND NS.PartyValid = 1							-- VALID PARTYID	


		-- PROCESS NON SOLICITATIONS
		INSERT	[$(SampleDB)].Party.vwDA_NonSolicitations 
		(
			NonSolicitationID,
			NonSolicitationTextID, 
			PartyID,
			FromDate,
			AuditItemID
		)
		SELECT 0, 6, NS.PartyID, GETDATE(), NS.AuditItemID
		FROM InternalUpdate.NonSolicitations NS
		WHERE NS.DateProcessed IS NULL
		AND NS.AuditItemID = NS.ParentAuditItemID		-- NON DUPLICATE
		AND NS.PartyValid = 1							-- VALID PARTYID
		AND NS.ExistsAlready = 0;						-- REQUIRED


		-- SET THE DateProcessed IN InternalUpdate.NonSolicitations
		UPDATE InternalUpdate.NonSolicitations
		SET DateProcessed = @ProcessDate
		WHERE DateProcessed IS NULL

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
