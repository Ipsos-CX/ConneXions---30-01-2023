CREATE TRIGGER ContactMechanism.TR_I_vwDA_PartyContactMechanisms ON ContactMechanism.vwDA_PartyContactMechanisms
INSTEAD OF INSERT

AS

/*
	Purpose:	Handles insert into vwDA_PartyContactMechanisms
				All rows in VWT containing contact mechanism information should be inserted from the appropriate view.  
				All rows are written to the Audit.PartyContactMechanisms table
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created from [Prophet-ODS].dbo.vwDA_PartyPostalAddresses.TR_I_vwDA_PartyContactMechanisms

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

		-- INSERT THE NEW RECORDS INTO PartyContactMechanisms
		INSERT INTO ContactMechanism.PartyContactMechanisms
		(
			ContactMechanismID, 
			PartyID, 
			RoleTypeID, 
			FromDate
		)
		SELECT DISTINCT
			I.ContactMechanismID, 
			I.PartyID, 
			I.RoleTypeID, 
			I.FromDate
		FROM INSERTED I
		LEFT JOIN ContactMechanism.PartyContactMechanisms PCM ON PCM.ContactMechanismID = I.ContactMechanismID
															AND PCM.PartyID = I.PartyID
		WHERE PCM.ContactMechanismID IS NULL
		ORDER BY I.ContactMechanismID, I.PartyID

		-- INSERT ALL THE RECORDS INTO Audit.PartyContactMechanisms IF WE'VE NOT ALREADY LOADED THEM
		INSERT INTO [$(AuditDB)].Audit.PartyContactMechanisms
		(
			AuditItemID,
			ContactMechanismID, 
			PartyID, 
			RoleTypeID, 
			FromDate
		)
		SELECT DISTINCT
			I.AuditItemID,
			I.ContactMechanismID, 
			I.PartyID, 
			I.RoleTypeID, 
			COALESCE(PCM.FromDate, I.FromDate)
		FROM INSERTED I
		LEFT JOIN (  
			SELECT
				ContactMechanismID, 
				PartyID, 
				ISNULL(RoleTypeID, 0) AS RoleTypeID, 
				MAX(FromDate) AS FromDate
			FROM [$(AuditDB)].Audit.PartyContactMechanisms
			GROUP BY
				ContactMechanismID, 
				PartyID, 
				ISNULL(RoleTypeID, 0)
		) PCM ON I.ContactMechanismID = PCM.ContactMechanismID
				AND I.PartyID = PCM.PartyID
		LEFT JOIN [$(AuditDB)].Audit.PartyContactMechanisms APCM ON APCM.ContactMechanismID = I.ContactMechanismID
																AND APCM.PartyID = I.PartyID
																AND APCM.AuditItemID = I.AuditItemID
		WHERE APCM.ContactMechanismID IS NULL
		ORDER BY I.AuditItemID
		
		-- INSERT THE PartyContactMechanismPurposes
		INSERT INTO ContactMechanism.vwDA_PartyContactMechanismPurposes
		(
			AuditItemID, 
			ContactMechanismID, 
			PartyID, 
			ContactMechanismPurposeTypeID, 
			FromDate
		)
		SELECT DISTINCT
			AuditItemID, 
			ContactMechanismID, 
			PartyID, 
			ContactMechanismPurposeTypeID, 
			FromDate
		FROM INSERTED
		ORDER BY ContactMechanismID,  PartyID
		
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