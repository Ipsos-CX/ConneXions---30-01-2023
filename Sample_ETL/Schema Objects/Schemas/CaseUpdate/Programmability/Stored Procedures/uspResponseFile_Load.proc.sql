CREATE PROCEDURE [CaseUpdate].[uspResponseFile_Load]
	
AS

	/*
		Purpose: Write updates (i.e. set closure and write answers to the anonymity question) to the Case table 
	
		Version		Developer			Date			Comment
		1.0			Martin Riverol		04/07/2013		Created			
	*/
	

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY
	
	INSERT INTO [$(SampleDB)].Event.vwDA_Cases
	
		(
			AuditItemID
			, CaseID
			, PartyID
			, CaseStatusTypeID
			, CreationDate
			, ClosureDateOrig
			, ClosureDate
			, OnlineExpiryDate
			, SelectionOutputPassword
			, AnonymityDealer
			, AnonymityManufacturer
		)
	
			SELECT 
				R.AuditItemID
				, R.CaseID
				, R.PartyID
				/* DON'T CLOSE CASE UNLESS IT IS VALID */
				, CASE C.CaseStatusTypeID
					WHEN 1 THEN 3
					ELSE C.CaseStatusTypeID
				END	AS CaseStatusTypeID
				, C.CreationDate
				, R.ClosureDateOrig
				, R.ClosureDate
				, C.OnlineExpiryDate
				, C.SelectionOutputPassword
				, R.AnonymityDealer
				, R.AnonymityManufacturer
			FROM CaseUpdate.ResponseFile R
			INNER JOIN [$(SampleDB)].Event.Cases C ON R.CaseID = C.CaseID

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