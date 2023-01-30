CREATE TRIGGER Event.TR_I_vwDA_CaseRejections ON Event.vwDA_CaseRejections
INSTEAD OF INSERT

AS

/*
	Purpose:	Records Case Rejection information and audits it
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created from [Prophet-ODS].dbo.vwDA_CaseRejections.TR_I_vwDA_CaseRejections

*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	-- IF WE'RE ADDING A REJECTION WRITE IT TO Event.CaseRejections
	INSERT INTO Event.CaseRejections
	(
		 CaseID
		,FromDate
	)
	SELECT
		 CaseID
		,FromDate
	FROM INSERTED
	WHERE Rejection = 1
	
	-- IF WE'RE REMOVING A REJECTION DELETE IT FROM Event.CaseRejections
	DELETE CR
	FROM Event.CaseRejections CR
	INNER JOIN INSERTED I ON I.CaseID = CR.CaseID
	WHERE I.Rejection = 0
	
	-- UPDATE THE CASE STATUS
	UPDATE C
	SET C.CaseStatusTypeID = (SELECT CaseStatusTypeID FROM Event.CaseStatusTypes WHERE CaseStatusType = 'Refused by Exec')
	FROM Event.Cases C
	INNER JOIN INSERTED I ON I.CaseID = C.CaseID
	WHERE I.Rejection = 1
	
	UPDATE C
	SET C.CaseStatusTypeID = (SELECT CaseStatusTypeID FROM Event.CaseStatusTypes WHERE CaseStatusType = 'Active')
	FROM Event.Cases C
	INNER JOIN INSERTED I ON I.CaseID = C.CaseID
	WHERE I.Rejection = 0
	AND C.ClosureDate IS NULL
	
	UPDATE C
	SET C.CaseStatusTypeID = (SELECT CaseStatusTypeID FROM Event.CaseStatusTypes WHERE CaseStatusType = 'Successfull')
	FROM Event.Cases C
	INNER JOIN INSERTED I ON I.CaseID = C.CaseID
	WHERE I.Rejection = 0
	AND C.ClosureDate IS NOT NULL
	
	-- NOW WRITE THE VALUS TO AUDIT
	INSERT INTO [$(AuditDB)].Audit.CaseRejections
	(
		 AuditItemID
		,CaseID
		,FromDate
		,Rejection
	)
	SELECT
		 AuditItemID
		,CaseID
		,FromDate
		,Rejection
	FROM INSERTED

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


