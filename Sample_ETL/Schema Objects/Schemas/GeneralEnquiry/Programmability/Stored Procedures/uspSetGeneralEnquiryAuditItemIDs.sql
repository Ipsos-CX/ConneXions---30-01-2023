CREATE PROCEDURE [GeneralEnquiry].[uspSetGeneralEnquiryAuditItemIDs]

AS 
/*
	Purpose:	Writes VWT generated AuditItemIDs back to GeneralEnquiryEvents table
	
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

	-- CHECK IF GE HAVE ANY WORK TO DO
	DECLARE @RowsToUpdate INT

	SELECT @RowsToUpdate = COUNT(VWTID)
	FROM dbo.VWT
	WHERE GeneralEnquiryID > 0

	-- UPDATE AuditItemID AND SET THE DateStamp
	IF @RowsToUpdate > 0
	BEGIN
		UPDATE GE
		SET
			GE.AuditItemID = V.AuditItemID, 
			GE.DateTransferredToVWT = CURRENT_TIMESTAMP
		FROM GeneralEnquiry.GeneralEnquiryEvents GE
		INNER JOIN (
			SELECT
				AuditItemID, 
				GeneralEnquiryID
			FROM dbo.VWT
			WHERE GeneralEnquiryID > 0
			AND AuditItemID > 0
		) V ON GE.GeneralEnquiryID = V.GeneralEnquiryID
		WHERE (
			GE.AuditItemID IS NULL OR GE.AuditItemID = 0
		)
		AND GE.DateTransferredToVWT IS NULL
	END

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
