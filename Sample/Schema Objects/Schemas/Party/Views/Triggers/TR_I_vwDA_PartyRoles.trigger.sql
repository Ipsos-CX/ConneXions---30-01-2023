CREATE TRIGGER Party.TR_I_vwDA_PartyRoles ON Party.vwDA_PartyRoles
INSTEAD OF INSERT

AS

/*
	Purpose:	Handles insert into vwDA_PartyRoles
				All rows in VWT containing Party Role information should be inserted into this view 
				All rows are written to the Audit.PartyRoles table
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created from [Prophet-ODS].dbo.vwDA_vwDA_PartyRoles.TR_I_vwDA_vwDA_PartyRoles

*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	-- INSERT DISTINCT NOW ROWS INTO PartyRoles
	INSERT INTO Party.PartyRoles
	(
		PartyID,
		RoleTypeID, 
		FromDate
	)
	SELECT 
		I.PartyID,
		I.RoleTypeID, 
		MIN(I.FromDate)
	FROM INSERTED I
	LEFT JOIN Party.PartyRoles PR ON PR.PartyID = I.PartyID
								AND PR.RoleTypeID = I.RoleTypeID		
	WHERE PR.PartyID IS NULL
	GROUP BY
		I.PartyID, 
		I.RoleTypeID
	ORDER BY
		I.PartyID, 
		I.RoleTypeID


	-- INSERT ALL ROWS INTO Audit.PartyRoles
	INSERT INTO [$(AuditDB)].Audit.PartyRoles
	(
		AuditItemID, 
		PartyID,
		RoleTypeID, 
		PartyRoleID, 
		FromDate, 
		ThroughDate
	)
	SELECT DISTINCT
		I.AuditItemID,
		PR.PartyID,
		PR.RoleTypeID, 
		PR.PartyRoleID, 
		PR.FromDate, 
		I.ThroughDate
	FROM Party.PartyRoles PR
	INNER JOIN INSERTED I ON PR.PartyID = I.PartyID
							AND PR.RoleTypeID = I.RoleTypeID
	LEFT JOIN [$(AuditDB)].Audit.PartyRoles APR ON APR.AuditItemID = I.AuditItemID
											AND APR.PartyRoleID = PR.PartyRoleID
	WHERE APR.AuditItemID IS NULL
	ORDER BY I.AuditItemID

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













