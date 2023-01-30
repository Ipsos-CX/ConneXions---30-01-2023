CREATE TRIGGER Vehicle.TR_I_vwDA_VehiclePartyRoles ON Vehicle.vwDA_VehiclePartyRoles
INSTEAD OF INSERT

AS

/*
	Purpose:	Handles insert into vwDA_VehiclePartyRoles.
				All rows in VWT containing vehicle party role information should be inserted into this view.
				All rows are written to the Audit.VehiclePartyRoles table where it is a new row

	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created from [Prophet-ODS].dbo.vwDA_vwDA_VehiclePartyRoles.TR_I_vwDA_vwDA_VehiclePartyRoles

*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	INSERT INTO Vehicle.VehiclePartyRoles
	(
		PartyID, 
		VehicleRoleTypeID, 
		VehicleID,
		FromDate
	)
	SELECT DISTINCT
		I.PartyID, 
		I.VehicleRoleTypeID, 
		I.VehicleID,
		I.FromDate
	FROM INSERTED I
	LEFT JOIN Vehicle.VehiclePartyRoles VPR ON I.PartyID = VPR.PartyID
											AND I.VehicleRoleTypeID = VPR.VehicleRoleTypeID
											AND I.VehicleID = VPR.VehicleID
	WHERE VPR.VehicleID IS NULL

	INSERT INTO [$(AuditDB)].Audit.VehiclePartyRoles
	(
		AuditItemID, 
		PartyID, 
		VehicleRoleTypeID, 
		VehicleID, 
		FromDate, 
		ThroughDate
	)
	SELECT DISTINCT 
		I.AuditItemID,
		I.PartyID, 
		I.VehicleRoleTypeID, 
		I.VehicleID,  
		I.FromDate, 
		I.ThroughDate
	FROM INSERTED I
	LEFT JOIN [$(AuditDB)].Audit.VehiclePartyRoles AVPR ON AVPR.AuditItemID = I.AuditItemID
	WHERE AVPR.AuditItemID IS NULL
	

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
