CREATE TRIGGER Event.TR_I_vwDA_Cases ON Event.vwDA_Cases
INSTEAD OF INSERT
AS

	
/*
	Purpose: Load updates to case details table and related audit table.

	Version		Developer			Date			Comment
	1.0			Martin Riverol		01/07/2013		Created

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

		/* UPDATE CASES TABLE */
		
			UPDATE C
				SET CaseStatusTypeID = I.CaseStatusTypeID
				, ClosureDate = I.ClosureDate
				, AnonymityDealer = I.AnonymityDealer
				, AnonymityManufacturer = I.AnonymityManufacturer
			FROM Event.Cases C
			INNER JOIN Event.AutomotiveEventBasedInterviews AEBI ON C.CaseID = AEBI.CaseID
			INNER JOIN INSERTED I ON AEBI.CaseID = I.CaseID 
								AND AEBI.PartyID = I.PartyID
				

		/* WRITE ROW INTO AUDIT TABLE */

		INSERT INTO [$(AuditDB)].Audit.Cases
			(
				AuditItemID
				, PartyCaseIDComboValid
				, CaseID
				, PartyID
				, CaseStatusTypeID
				, CreationDate
				, ClosureDate
				, ClosureDateOrig
				, OnlineExpiryDate
				, SelectionOutputPassword
				, AnonymityDealer
				, AnonymityManufacturer
			)
			
			SELECT DISTINCT 
				I.AuditItemID
				, CASE 
					WHEN AEBI.CaseID IS NULL THEN 0
					ELSE 1
				END		
				, I.CaseID
				, I.PartyID
				, I.CaseStatusTypeID
				, I.CreationDate
				, I.ClosureDate
				, I.ClosureDateOrig
				, I.OnlineExpiryDate
				, I.SelectionOutputPassword
				, I.AnonymityDealer
				, I.AnonymityManufacturer
			FROM INSERTED I
			LEFT JOIN [$(AuditDB)].Audit.Cases AC ON AC.AuditItemID = I.AuditItemID
			LEFT JOIN Event.AutomotiveEventBasedInterviews AEBI ON I.CaseID = AEBI.CaseID
																AND I.PartyID = AEBI.PartyID
			WHERE AC.AuditItemID IS NULL
			
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