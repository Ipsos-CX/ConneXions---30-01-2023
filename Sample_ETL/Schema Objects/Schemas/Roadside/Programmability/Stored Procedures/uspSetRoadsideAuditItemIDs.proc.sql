
CREATE PROCEDURE [Roadside].[uspSetRoadsideAuditItemIDs]

AS 
/*
	Purpose:	Writes generated AuditItemIDs back to Warranty.WarrantyEvents
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Chris Ross		Created from [Sample_ETL].Warranty.uspSetRoadsideAuditItemIDs

*/

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	-- CHECK IF WE HAVE ANY WORK TO DO
	DECLARE @RowsToUpdate INT

	SELECT @RowsToUpdate = COUNT(VWTID)
	FROM dbo.VWT
	WHERE RoadsideID > 0

	-- UPDATE AuditItemID AND SET THE DateStamp
	IF @RowsToUpdate > 0
	BEGIN
		UPDATE WE
		SET
			WE.AuditItemID = V.AuditItemID, 
			WE.DateTransferredToVWT = CURRENT_TIMESTAMP
		FROM Roadside.RoadsideEvents WE
		INNER JOIN (
			SELECT
				AuditItemID, 
				RoadsideID
			FROM dbo.VWT
			WHERE RoadsideID > 0
			AND AuditItemID > 0
		) V ON WE.RoadsideID = V.RoadsideID
		WHERE (
			WE.AuditItemID IS NULL OR WE.AuditItemID = 0
		)
		AND WE.DateTransferredToVWT IS NULL
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