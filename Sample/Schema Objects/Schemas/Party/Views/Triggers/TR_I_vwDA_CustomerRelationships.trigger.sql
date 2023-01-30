CREATE TRIGGER Party.TR_I_vwDA_CustomerRelationships ON Party.vwDA_CustomerRelationships
INSTEAD OF INSERT

AS

/*
	Purpose:	Handles insert into vwDA_CustomerRelationships
				All rows in VWT containing customer relationship information should be inserted into this view
				All rows are written to the Audit.CustomerRelationships table
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created from [Prophet-ODS].dbo.vwDA_vwDA_CustomerRelationships.TR_I_vwDA_vwDA_CustomerRelationships

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

		-- SET UP THE PARTY RELATIONSHIP IS IT DOES NOT ALREADY EXIST (HANDLED BY IT'S OWN TRIGGER)
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

		-- INSERT THE CUSTOMER RELATIONSHIP
		INSERT INTO Party.CustomerRelationships
		(
			PartyIDFrom, 
			RoleTypeIDFrom, 
			PartyIDTo, 
			RoleTypeIDTo, 
			CustomerIdentifier, 
			CustomerIdentifierUsable
		)
		SELECT DISTINCT
			I.PartyIDFrom, 
			I.RoleTypeIDFrom, 
			I.PartyIDTo, 
			I.RoleTypeIDTo, 
			I.CustomerIdentifier, 
			I.CustomerIdentifierUsable
		FROM INSERTED I
		LEFT JOIN Party.CustomerRelationships CR ON ISNULL(CR.CustomerIdentifier, '') = I.CustomerIdentifier
												AND CR.PartyIDFrom = I.PartyIDFrom
												AND CR.PartyIDTo = I.PartyIDTo
												AND CR.RoleTypeIDFrom = I.RoleTypeIDFrom
												AND CR.RoleTypeIDTo = I.RoleTypeIDTo
		WHERE CR.PartyIDFrom IS NULL

		-- INSERT ALL ROWS INTO Audit.CustomerRelationships
		INSERT INTO [$(AuditDB)].Audit.CustomerRelationships
		(
			AuditItemID, 
			PartyIDFrom, 
			RoleTypeIDFrom, 
			PartyIDTo, 
			RoleTypeIDTo, 
			CustomerIdentifier, 
			CustomerIdentifierUsable
		)
		SELECT DISTINCT
			I.AuditItemID, 
			I.PartyIDFrom, 
			I.RoleTypeIDFrom, 
			I.PartyIDTo, 
			I.RoleTypeIDTo, 
			I.CustomerIdentifier, 
			I.CustomerIdentifierUsable
		FROM INSERTED I
		LEFT JOIN [$(AuditDB)].Audit.CustomerRelationships ACR ON ACR.AuditItemID = I.AuditItemID
															AND ACR.PartyIDFrom = I.PartyIDFrom
															AND ACR.PartyIDTo = I.PartyIDTo
															AND ACR.RoleTypeIDFrom = I.RoleTypeIDFrom
															AND ACR.RoleTypeIDTo = I.RoleTypeIDTo
		WHERE ACR.PartyIDFrom IS NULL
		ORDER BY I.AuditItemID

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
	








