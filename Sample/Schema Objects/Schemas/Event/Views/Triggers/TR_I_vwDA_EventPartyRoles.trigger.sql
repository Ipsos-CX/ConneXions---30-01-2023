CREATE TRIGGER Event.TR_I_vwDA_EventPartyRoles ON Event.vwDA_EventPartyRoles
INSTEAD OF INSERT

AS

/*
	Purpose:	Loads EventPartyRoles data from the VWT into the system.
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created from [Prophet-ODS].dbo.vwDA_EventPartyRoles.TR_I_vwDA_EventPartyRoles

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

		INSERT INTO Event.EventPartyRoles
		(
			PartyID, 
			RoleTypeID, 
			EventID
		)
		SELECT DISTINCT
			I.PartyID, 
			I.RoleTypeID, 
			I.EventID
		FROM INSERTED I
		LEFT JOIN Event.EventPartyRoles EPR ON I.PartyID = EPR.PartyID 
						AND I.RoleTypeID = EPR.RoleTypeID 
						AND I.EventID = EPR.EventID
		WHERE EPR.PartyID IS NULL
		AND I.PartyID > 0
			

		INSERT INTO [$(AuditDB)].Audit.EventPartyRoles
		(
			AuditItemID, 
			PartyID, 
			RoleTypeID, 
			EventID,
			DealerCode,
			DealerCodeOriginatorPartyID
		)
		SELECT DISTINCT 
			I.AuditItemID,
			I.PartyID, 
			I.RoleTypeID, 
			I.EventID,
			I.DealerCode,
			I.DealerCodeOriginatorPartyID
		FROM INSERTED I
		LEFT JOIN [$(AuditDB)].Audit.EventPartyRoles AEPR ON AEPR.AuditItemID = I.AuditItemID
		WHERE AEPR.AuditItemID IS NULL
		
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










