CREATE TRIGGER Requirement.TR_U_vwDA_SelectionRequirements ON [Requirement].[vwDA_SelectionRequirements] 

INSTEAD OF UPDATE

AS

/*
	Purpose:	Update the status of a given selection and audit it
		
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created

*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	-- DO THE UPDATE PROVIDED THE STATUS IS NOT ALREADY SET TO AUTHORISED OR OUTPUTTED
	UPDATE SR
	SET	SR.SelectionDate = I.SelectionDate,
		SR.SelectionStatusTypeID = I.SelectionStatusTypeID,
		SR.SelectionTypeID = I.SelectionTypeID,
		SR.DateLastRun = I.DateLastRun,
		SR.RecordsSelected = I.RecordsSelected,
		SR.RecordsRejected = I.RecordsRejected,
		SR.LastViewedDate = I.LastViewedDate,
		SR.LastViewedPartyID = I.LastViewedPartyID,
		SR.LastViewedRoleTypeID = I.LastViewedRoleTypeID,
		SR.DateOutputAuthorised = I.DateOutputAuthorised,
		SR.AuthorisingPartyID = I.AuthorisingPartyID,
		SR.AuthorisingRoleTypeID = I.AuthorisingRoleTypeID
	FROM Requirement.SelectionRequirements SR
	INNER JOIN INSERTED I ON SR.RequirementID = I.RequirementID
	WHERE SR.SelectionStatusTypeID <> (SELECT SelectionStatusTypeID FROM Requirement.SelectionStatusTypes WHERE SelectionStatusType = 'Outputted')
	AND SR.SelectionStatusTypeID <> (SELECT SelectionStatusTypeID FROM Requirement.SelectionStatusTypes WHERE SelectionStatusType = 'Authorised')
	
	-- INSERT INTO AUDIT
	INSERT INTO [$(AuditDB)].Audit.SelectionRequirements
	(
		AuditItemID,
		RequirementID,
		SelectionDate,
		SelectionStatusTypeID,
		SelectionTypeID,
		DateLastRun,
		RecordsSelected,
		RecordsRejected,
		LastViewedDate,
		LastViewedPartyID,
		LastViewedRoleTypeID,
		DateOutputAuthorised,
		AuthorisingPartyID,
		AuthorisingRoleTypeID
	)
	SELECT
		AuditItemID,
		RequirementID,
		SelectionDate,
		SelectionStatusTypeID,
		SelectionTypeID,
		DateLastRun,
		RecordsSelected,
		RecordsRejected,
		LastViewedDate,
		LastViewedPartyID,
		LastViewedRoleTypeID,
		DateOutputAuthorised,
		AuthorisingPartyID,
		AuthorisingRoleTypeID
	FROM INSERTED

END TRY
BEGIN CATCH

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