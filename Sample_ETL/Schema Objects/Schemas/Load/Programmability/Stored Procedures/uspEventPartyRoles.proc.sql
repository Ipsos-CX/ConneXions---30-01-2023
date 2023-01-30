CREATE PROCEDURE [Load].[uspEventPartyRoles]

AS

/*
	Purpose:	Write the link between the party and the dealer to Sample database
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created from [Prophet-ETL].dbo.uspODSLOAD_EventPartyRoles

*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	INSERT INTO [$(SampleDB)].Event.vwDA_EventPartyRoles
	(
		AuditItemID, 
		PartyID, 
		RoleTypeID, 
		EventID,
		DealerCode,
		DealerCodeOriginatorPartyID
	)
	SELECT
		AuditItemID, 
		PartyID, 
		RoleTypeID, 
		EventID,
		DealerCode,  --Also includes RoadsideNetwork IDs
		DealerCodeOriginatorPartyID
	FROM Load.vwEventPartyRoles 

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