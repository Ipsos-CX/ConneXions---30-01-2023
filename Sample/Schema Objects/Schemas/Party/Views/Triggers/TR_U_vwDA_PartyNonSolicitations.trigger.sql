CREATE TRIGGER Party.TR_U_vwDA_NonSolicitations ON Party.vwDA_NonSolicitations
INSTEAD OF UPDATE

AS

/*
	Purpose:	Loads party non solications data from the VWT into the system.
	
	Version			Date			Developer			Comment
	1.0				20/05/2014		Ali Yuksel		

*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	DECLARE @Max_NonSolicitationID INT


	UPDATE NS
	SET	ThroughDate	= i.ThroughDate
	from [$(SampleDB)].dbo.NonSolicitations NS
	join INSERTED i on i.NonSolicitationID=NS.NonSolicitationID and  i.PartyID=NS.PartyID 
	


	INSERT INTO [$(AuditDB)].Audit.NonSolicitations
	(
		AuditItemID, 
		NonSolicitationID, 
		NonSolicitationTextID,
		PartyID,
		RoleTypeID,
		FromDate,
		ThroughDate,
		Notes
	)
	SELECT
		I.AuditItemID, 
		I.NonSolicitationID, 
		I.NonSolicitationTextID,
		I.PartyID,
		I.RoleTypeID,
		I.FromDate,
		I.ThroughDate,
		'Customer Update - Non Solicitation Removal'
	FROM INSERTED I 



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