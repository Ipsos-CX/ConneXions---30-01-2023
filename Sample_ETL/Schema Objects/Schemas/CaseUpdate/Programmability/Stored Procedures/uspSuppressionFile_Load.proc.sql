CREATE PROCEDURE [CaseUpdate].[uspSuppressionFile_Load]
	
AS

	/*
		Purpose: Write updates to the Case table (i.e. set the casestatustypeid to 8)
	
		Version		Developer			Date			Comment
		1.0			Martin Riverol		16/07/2013		Created			
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
				S.AuditItemID
				, S.CaseID
				, S.PartyID
				, 8	AS CaseStatusTypeID
				, C.CreationDate
				, NULL AS ClosureDateOrig
				, C.ClosureDate
				, C.OnlineExpiryDate
				, C.SelectionOutputPassword
				, C.AnonymityDealer
				, C.AnonymityManufacturer
			FROM CaseUpdate.SuppressionFile S
			INNER JOIN [$(SampleDB)].Event.Cases C ON S.CaseID = C.CaseID

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