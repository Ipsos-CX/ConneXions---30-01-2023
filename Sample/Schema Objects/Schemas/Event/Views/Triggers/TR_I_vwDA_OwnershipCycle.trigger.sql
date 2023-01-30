CREATE TRIGGER Event.TR_I_vwDA_OwnershipCycle ON Event.vwDA_OwnershipCycle
INSTEAD OF INSERT

AS

/*
	Purpose:	Loads Ownership Cycle data from the VWT into the system.
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)	Simon Peacock		Created from [Prophet-ODS].dbo.vwDA_OwnershipCycle.TR_I_vwDA_OwnershipCycle
	1.1				16/06/15		Eddie THomas		BUG 11545 (Euro Importer - Global Loader Setup): Instructed to store ownership Cycle 
																	for Service Events
	1.2				08/07/15		P.Doyle				
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

		INSERT INTO Event.OwnershipCycle
		(
			EventID,
			OwnershipCycle		
		)
		SELECT
			I.EventID,
			MAX(I.OwnershipCycle) AS OwnershipCycle
		FROM INSERTED I
		LEFT JOIN Event.OwnershipCycle OC ON OC.EventID = I.EventID
		
		--V1.2 old code with unbracketed OR bug changed by 8-Jul-2015 
		--WHERE I.EventTypeID = 1 OR I.EventTypeID = 2 -- Sales/Service events only
		
		WHERE I.EventTypeID IN (1,2) -- Sales/Service events only 
		
		AND OC.EventID IS NULL
		GROUP BY I.EventID

		INSERT INTO [$(AuditDB)].Audit.OwnershipCycle
		(
			AuditItemID,
			EventID,
			OwnershipCycle		
		)
		SELECT 
			I.AuditItemID,
			I.EventID,
			I.OwnershipCycle
		FROM INSERTED I
		LEFT JOIN [$(AuditDB)].Audit.OwnershipCycle OC ON OC.AuditItemID = I.AuditItemID
		WHERE OC.AuditItemID IS NULL
		
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











