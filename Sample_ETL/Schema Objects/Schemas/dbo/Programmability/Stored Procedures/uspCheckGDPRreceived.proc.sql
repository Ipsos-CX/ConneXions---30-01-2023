CREATE PROCEDURE [dbo].[uspCheckGDPRreceived]

AS
SET NOCOUNT ON

/*
	Purpose:	Alter contact preferences by PID
			
	Version			Date			Developer			Comment
	1.0				24/07/2018		Ben King			Creation BUG 14840
	checked out
*/

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	;WITH GDPR_restriction (PartyID, FromDate) AS
	(
		SELECT NS.PartyID, NS.FromDate
		FROM [$(SampleDB)].dbo.NonSolicitations NS 
		INNER JOIN [$(SampleDB)].Party.NonSolicitations PNS ON PNS.NonSolicitationID = NS.NonSolicitationID
		INNER JOIN [$(SampleDB)].dbo.NonSolicitationTexts NT on NT.NonSolicitationTextID = NS.NonSolicitationTextID
		WHERE NS.NonSolicitationTextID IN (22)
	)
	INSERT INTO [Party].[GDPR_RestrictionsLoaded]  (GR.PartyID, GR.FromDate, F.FileName, F.ActionDate, SQ.PhysicalFileRow)
	SELECT GR.PartyID, GR.FromDate, F.FileName, F.ActionDate, SQ.PhysicalFileRow
	FROM GDPR_restriction GR
	INNER JOIN [$(WebsiteReporting)].DBO.SampleQualityAndSelectionLogging SQ ON COALESCE(NULLIF(SQ.MatchedODSPersonID,0), NULLIF(SQ.MatchedODSOrganisationID,0), SQ.MatchedODSPartyID)= GR.PartyID															
	INNER JOIN [$(AuditDB)].DBO.Files F ON F.AuditID = SQ.AuditID
	WHERE GR.FromDate < f.ActionDate
	AND NOT EXISTS (SELECT R.PartyID FROM [Party].[GDPR_RestrictionsLoaded] R
				WHERE R.PartyID = GR.PartyID)	

	IF Exists( 
				SELECT	 *
				FROM	 [Party].[GDPR_RestrictionsLoaded]
				WHERE	 [EmailSent] IS NULL
			)			 
	BEGIN
		DECLARE @html nvarchar(MAX);
		EXEC dbo.spQueryToHtmlTable @html = @html OUTPUT,  @query = N'SELECT PartyID AS [Party ID], convert(varchar(10), FromDate, 120) AS [GDPR date], FileName AS [File name], convert(varchar(10), ActionDate, 120) AS [Party ID loaded date], PhysicalFileRow AS [Sample file row] FROM [Party].[GDPR_RestrictionsLoaded] WHERE [EmailSent] IS NULL', @orderBy = N'ORDER BY [Party ID]';

		EXEC msdb.dbo.sp_send_dbmail
		   @profile_name = 'DBAProfile',
		   @recipients = 'Gene.Denney@gfk.com;Dipak.Gohil@gfk.com;Stephanie.Aritone@gfk.com;Tim.Wardle@gfk.com;ben.king@gfk.com',
		   @subject = 'GDPR restricted Party ID''s loaded after their initial rectriction date',
		   @body = @html,
		   @body_format = 'HTML'

		UPDATE [Party].[GDPR_RestrictionsLoaded]
		SET [EmailSent] = GETDATE()
		WHERE	 [EmailSent] IS NULL
	END

END TRY
BEGIN CATCH

	SELECT
		 @ErrorNumber = Error_Number()
		,@ErrorSeverity = Error_Severity()
		,@ErrorState = Error_State()
		,@ErrorLocation = Error_Procedure()
		,@ErrorLine = Error_Line()
		,@ErrorMessage = Error_Message()

	EXEC [Sample_Errors].dbo.uspLogDatabaseError
		 @ErrorNumber
		,@ErrorSeverity
		,@ErrorState
		,@ErrorLocation
		,@ErrorLine
		,@ErrorMessage
		
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH

GO