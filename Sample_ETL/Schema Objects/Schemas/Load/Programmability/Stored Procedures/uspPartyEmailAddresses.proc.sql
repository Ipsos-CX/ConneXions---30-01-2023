CREATE PROCEDURE Load.uspPartyEmailAddresses

AS

/*
	Purpose:	Write the link between the parties and email addresses to Sample database
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)	Simon Peacock		Created from [Prophet-ETL].dbo.uspODSLOAD_ElectronicPartyContactMechanisms
	1.1				01/06/2015		Eddie Thomas		BUG 11545 - Ensuring primary EmailAddress field has highest priority.
														Changing order that the contactmechanisms are created allows for this.
	 

*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	INSERT INTO [$(SampleDB)].ContactMechanism.vwDA_PartyContactMechanisms
	(
		AuditItemID, 
		ContactMechanismID, 
		PartyID, 
		FromDate, 
		ContactMechanismPurposeTypeID,
		RoleTypeID
	)
	SELECT 
		AuditItemID, 
		ContactMechanismID, 
		PartyID, 
		FromDate, 
		VWPE.ContactMechanismPurposeTypeID,
		RoleTypeID
	
	FROM Load.vwPartyEmailAddresses VWPE
	INNER JOIN [$(SampleDB)].ContactMechanism.ContactMechanismPurposeTypes CMPT ON VWPE.ContactMechanismPurposeTypeID = CMPT.ContactMechanismPurposeTypeID
	
	ORDER BY	CASE [ContactMechanismPurposeType]
						WHEN 'e-mail address (unknown purpose)' THEN 1
						WHEN 'Private e-mail address' THEN 2
						WHEN 'Work e-mail address' THEN 3
						WHEN 'Main business e-mail address' THEN 4
				END,
				AuditItemID
	
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
