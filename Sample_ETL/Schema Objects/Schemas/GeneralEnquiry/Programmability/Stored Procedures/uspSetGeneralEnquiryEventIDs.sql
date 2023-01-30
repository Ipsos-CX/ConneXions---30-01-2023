CREATE PROCEDURE [GeneralEnquiry].[uspSetGeneralEnquiryEventIDs]


AS 
/*
	Purpose:	Writes MatchedODSEventID column from VWT into GeneralEnquiryEvents table
	
	Version			Date			Developer			Comment
	1.0				2021-03-16		Chris Ledger		Created

*/

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

		UPDATE GE
		SET GE.ODSEventID = V.MatchedODSEventID
		FROM dbo.VWT V
			INNER JOIN GeneralEnquiry.GeneralEnquiryEvents GE ON GE.AuditItemID = V.AuditItemID
	
END TRY
BEGIN CATCH

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
