CREATE TRIGGER Party.TR_I_vwDA_EmployeeRelationships ON Party.vwDA_EmployeeRelationships
INSTEAD OF INSERT

AS

/*
	Purpose:	Handles insert into vwDA_EmployeeRelationships as this view points to a SubType the SuperType is written to first.  
				All rows in VWT containing Employee Relationship information should be inserted from appropriate view 
				All rows are written to the Audit EmployeeRelationships table
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created from [Prophet-ODS].dbo.vwDA_vwDA_EmployeeRelationships.TR_I_vwDA_vwDA_EmployeeRelationships

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
	
		INSERT INTO Party.vwDA_PartyRelationships
		(
			AuditItemID, 
			PartyIDFrom,
			RoleTypeIDFrom, 
			PartyIDTo, 
			RoleTypeIDTo, 	
			FromDate, 
			ThroughDate, 
			PartyRelationshipTypeID
		)
		SELECT
			AuditItemID, 
			PartyIDFrom,
			RoleTypeIDFrom, 
			PartyIDTo, 
			RoleTypeIDTo, 	
			FromDate, 
			ThroughDate, 
			PartyRelationshipTypeID
		FROM INSERTED
		ORDER BY AuditItemID
		

		INSERT INTO Party.EmployeeRelationships
		(
			PartyIDFrom, 
			RoleTypeIDFrom, 
			PartyIDTo, 
			RoleTypeIDTo, 
			EmployeeIdentifier, 
			EmployeeIdentifierUsable
		)
		SELECT DISTINCT
			I.PartyIDFrom, 
			I.RoleTypeIDFrom, 
			I.PartyIDTo, 
			I.RoleTypeIDTo, 
			I.EmployeeIdentifier, 
			I.EmployeeIdentifierUsable
		FROM INSERTED I
		LEFT JOIN Party.EmployeeRelationships CR ON ISNULL(CR.EmployeeIdentifier, '') = I.EmployeeIdentifier
								AND CR.PartyIDFrom = I.PartyIDFrom
								AND CR.PartyIDTo = I.PartyIDTo
								AND CR.RoleTypeIDFrom = I.RoleTypeIDFrom
								AND CR.RoleTypeIDTo = I.RoleTypeIDTo
		WHERE CR.PartyIDFrom IS NULL
		
		INSERT INTO [$(AuditDB)].Audit.EmployeeRelationships
		(
			AuditItemID, 
			PartyIDFrom, 
			RoleTypeIDFrom, 
			PartyIDTo, 
			RoleTypeIDTo, 
			EmployeeIdentifier, 
			EmployeeIdentifierUsable
		)
		SELECT DISTINCT
			AuditItemID, 
			PartyIDFrom, 
			RoleTypeIDFrom, 
			PartyIDTo, 
			RoleTypeIDTo, 
			EmployeeIdentifier, 
			EmployeeIdentifierUsable
		FROM INSERTED
		ORDER BY AuditItemID
		
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


