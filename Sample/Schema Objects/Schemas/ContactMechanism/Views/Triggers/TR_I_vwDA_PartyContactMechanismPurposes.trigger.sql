CREATE TRIGGER ContactMechanism.TR_I_vwDA_PartyContactMechanismPurposes ON ContactMechanism.vwDA_PartyContactMechanismPurposes
INSTEAD OF INSERT

AS

/*
	Purpose:	Handles insert into vwDA_PartyContactMechanismPurposes
				All rows are written to the Audit.PartyContactMechanismPurposes table
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created from [Prophet-ODS].dbo.vwDA_PartyContactMechanismPurposes.TR_I_vwDA_PartyContactMechanismPurposes

*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	-- INSERT INTO PartyContactMechanismPurposes
	INSERT INTO ContactMechanism.PartyContactMechanismPurposes
	(
		ContactMechanismID, 
		PartyID, 
		ContactMechanismPurposeTypeID, 
		FromDate		
	)
	SELECT DISTINCT
		I.ContactMechanismID, 
		I.PartyID, 
		I.ContactMechanismPurposeTypeID, 
		I.FromDate
	FROM INSERTED I
	LEFT JOIN ContactMechanism.PartyContactMechanismPurposes PCMP ON PCMP.ContactMechanismID = I.ContactMechanismID
																AND PCMP.PartyID = I.PartyID
																AND PCMP.ContactMechanismPurposeTypeID = I.ContactMechanismPurposeTypeID
	WHERE PCMP.ContactMechanismID IS NULL	
	ORDER BY I.ContactMechanismID, I.PartyID

	-- INSERT INTO Audit.PartyContactMechanismPurposes
	INSERT INTO [$(AuditDB)].Audit.PartyContactMechanismPurposes
	(
		AuditItemID,
		ContactMechanismID, 
		PartyID, 
		ContactMechanismPurposeTypeID, 
		FromDate
	)
	SELECT
		I.AuditItemID,
		I.ContactMechanismID, 
		I.PartyID, 
		I.ContactMechanismPurposeTypeID, 
		PCMP.FromDate
	FROM INSERTED I
	INNER JOIN ContactMechanism.PartyContactMechanismPurposes PCMP ON PCMP.ContactMechanismID = I.ContactMechanismID
																AND PCMP.PartyID = I.PartyID
																AND PCMP.ContactMechanismPurposeTypeID = I.ContactMechanismPurposeTypeID
	LEFT JOIN [$(AuditDB)].Audit.PartyContactMechanismPurposes APCMP ON APCMP.AuditItemID = I.AuditItemID
																AND APCMP.ContactMechanismID = I.ContactMechanismID
																AND APCMP.PartyID = I.PartyID
																AND APCMP.ContactMechanismPurposeTypeID = I.ContactMechanismPurposeTypeID
	WHERE APCMP.AuditItemID IS NULL
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




