CREATE TRIGGER Party.TR_I_vwDA_PartyClassifications ON Party.vwDA_PartyClassifications
INSTEAD OF INSERT

AS

/*
	Purpose:	Loads Party Classification data from the VWT into the system.
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)	Simon Peacock		Created from [Prophet-ODS].dbo.vwDA_PartyClassifications.TR_I_vwDA_PartyClassifications
	1.1				2016-06-10		Chris Ledger		Change to avoid duplicates being added when multiple From Dates added for individual PartyID (Dealer Appointments with different FromDates for same OutletCode (different OutletFunctions).

*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	INSERT INTO Party.PartyClassifications
	(
		PartyTypeID, 
		PartyID, 
		FromDate
	)
	SELECT
		I.PartyTypeID, 
		I.PartyID, 
		MIN(COALESCE(I.FromDate, CURRENT_TIMESTAMP)) AS FromDate
	FROM INSERTED I
	LEFT JOIN Party.PartyClassifications PC ON PC.PartyTypeID = I.PartyTypeID
											AND PC.PartyID = I.PartyID
	WHERE PC.PartyID IS NULL

	GROUP BY 	
	I.PartyTypeID, 
	I.PartyID 



	INSERT INTO [$(AuditDB)].Audit.PartyClassifications
	(
		AuditItemID, 
		PartyTypeID, 
		PartyID, 
		FromDate, 
		ThroughDate
	)
	SELECT DISTINCT
		I.AuditItemID, 
		I.PartyTypeID, 
		I.PartyID, 
		PC.FromDate, 
		I.ThroughDate
	FROM INSERTED I
	INNER JOIN Party.PartyClassifications PC ON I.PartyTypeID = PC.PartyTypeID
											AND I.PartyID = PC.PartyID
	LEFT JOIN [$(AuditDB)].Audit.PartyClassifications APC ON APC.AuditItemID = I.AuditItemID
															AND APC.PartyTypeID = I.PartyTypeID
															AND APC.PartyID = I.PartyID
															AND APC.FromDate = pc.FromDate
	WHERE APC.AuditItemID IS NULL
	
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







