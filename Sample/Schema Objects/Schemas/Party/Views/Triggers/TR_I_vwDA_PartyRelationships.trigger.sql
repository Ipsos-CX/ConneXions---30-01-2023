CREATE TRIGGER Party.TR_I_vwDA_PartyRelationships ON Party.vwDA_PartyRelationships
INSTEAD OF INSERT

AS

/*
	Purpose:	Handles insert into vwDA_PartyRelationships
				All rows in VWT containing Party Relationship information should be inserted into this view 
				All rows are written to the Audit.PartyRelationships table
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created from [Prophet-ODS].dbo.vwDA_vwDA_PartyRelationships.TR_I_vwDA_vwDA_PartyRelationships
	1.1				03-10-2016		Chris Ross			13181 - Remove PartyRelationship lookup table as it gets MAX From Date from Audit and then links to this to 
															    provide the From date for the new Audit record.  Simply use the From Date provided in the view as 
															    this is the latest anyway.
*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	-- BEFORE WE CAN CREATE THE PARTY RELATIONSHIPS WE NEED TO CREATE THE PARTY ROLES.  THIS IS HANDLED BY IT'S ONLY VIEW
	INSERT INTO Party.vwDA_PartyRoles
	(
		AuditItemID, 
		PartyID, 
		RoleTypeID, 
		FromDate
	)
	-- FROM ROLES...
	SELECT
		AuditItemID, 
		PartyIDFrom, 
		RoleTypeIDFrom, 
		FromDate
	FROM INSERTED
	UNION
	-- TO ROLES...
	SELECT
		AuditItemID, 
		PartyIDTo, 
		RoleTypeIDTo, 
		FromDate
	FROM INSERTED
	ORDER BY AuditItemID
	
	-- INSERT INTO PartyRelationships 
	INSERT INTO Party.PartyRelationships
	(
		PartyIDFrom,
		RoleTypeIDFrom, 
		PartyIDTo, 
		RoleTypeIDTo, 	
		FromDate, 
		PartyRelationshipTypeID
	)
	SELECT DISTINCT
		I.PartyIDFrom,
		I.RoleTypeIDFrom, 
		I.PartyIDTo, 
		I.RoleTypeIDTo, 	
		I.FromDate, 
		I.PartyRelationshipTypeID
	FROM INSERTED I
	LEFT JOIN Party.PartyRelationships PR ON PR.PartyIDFrom = I.PartyIDFrom
										AND PR.PartyIDTo = I.PartyIDTo
										AND PR.RoleTypeIDFrom = I.RoleTypeIDFrom
										AND PR.RoleTypeIDTo = I.RoleTypeIDTo
	WHERE PR.PartyIDFrom IS NULL
	AND I.ThroughDate IS NULL -- IF ThroughDate IS SET, ONLY WRITE TO AUDIT

	-- INSERT ALL ROWS INTO Audit.PartyRelationships 
	INSERT INTO [$(AuditDB)].Audit.PartyRelationships
	(
		AuditItemID, 
		PartyIDFrom,
		RoleTypeIDFrom, 
		PartyIDTo, 
		RoleTypeIDTo, 	
		PartyRelationshipTypeID, 
		FromDate, 
		ThroughDate
	)
	SELECT DISTINCT
		I.AuditItemID,
		I.PartyIDFrom,
		I.RoleTypeIDFrom, 
		I.PartyIDTo, 
		I.RoleTypeIDTo, 	
		I.PartyRelationshipTypeID, 
		COALESCE(I.FromDate, GETDATE()), 
		I.ThroughDate
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






