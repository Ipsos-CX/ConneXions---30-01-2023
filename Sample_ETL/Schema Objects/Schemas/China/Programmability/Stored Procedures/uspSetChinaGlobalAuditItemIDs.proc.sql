CREATE PROCEDURE [China].[uspSetChinaGlobalAuditItemIDs]

AS
DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	-- CHECK IF CSR HAVE ANY WORK TO DO
	DECLARE @RowsToUpdate INT

	SELECT		@RowsToUpdate = COUNT(VWTID)
	FROM		dbo.VWT V
	INNER JOIN	China.Sales_WithResponses CS ON	V.AuditID	= CS.AuditID  AND 
															V.PhysicalFileRow	= CS.PhysicalRowID AND 
															v.CountryID			= CS.CountryID
	WHERE	V.AuditID > 0	AND	
			V.PhysicalFileRow > 0 AND
			V.CountryID > 0 AND
			V.AuditItemID > 0 

	-- UPDATE AuditItemID AND SET THE DateStamp
	IF @RowsToUpdate > 0
	BEGIN
		UPDATE CSR
		SET
			CSR.AuditItemID = V.AuditItemID
		FROM China.Sales_WithResponses CSR
		INNER JOIN (
			SELECT	AuditItemID,
					AuditID,
					PhysicalFileRow,
					CountryID
			FROM	dbo.VWT
			WHERE AuditID > 0		
			AND PhysicalFileRow > 0
			AND CountryID > 0
			AND AuditItemID > 0 
		) V ON	CSR.AuditID = V.AuditID AND
				CSR.PhysicalRowID = V.PhysicalFileRow AND
				CSR.CountryID = V.CountryID
		WHERE (
			CSR.AuditItemID IS NULL OR CSR.AuditItemID = 0
		)
	END


	SELECT		@RowsToUpdate = COUNT(VWTID)
	FROM		dbo.VWT V
	INNER JOIN	China.Service_WithResponses CS ON	V.AuditID			= CS.AuditID  AND 
																V.PhysicalFileRow	= CS.PhysicalRowID AND 
																v.CountryID			= CS.CountryID
	WHERE	V.AuditID > 0	AND	
			V.PhysicalFileRow > 0 AND
			V.CountryID > 0 AND
			V.AuditItemID > 0 

	-- UPDATE AuditItemID AND SET THE DateStamp
	IF @RowsToUpdate > 0
	BEGIN
		UPDATE CSR
		SET
			CSR.AuditItemID = V.AuditItemID
		FROM China.Service_WithResponses CSR
		INNER JOIN (
			SELECT	AuditItemID,
					AuditID,
					PhysicalFileRow,
					CountryID
			FROM	dbo.VWT
			WHERE AuditID > 0		
			AND PhysicalFileRow > 0
			AND CountryID > 0
			AND AuditItemID > 0 
		) V ON	CSR.AuditID = V.AuditID AND
				CSR.PhysicalRowID = V.PhysicalFileRow AND
				CSR.CountryID = V.CountryID
		WHERE (
			CSR.AuditItemID IS NULL OR CSR.AuditItemID = 0
		)
	END
	
	
	SELECT		@RowsToUpdate = COUNT(VWTID)
	FROM		dbo.VWT V
	INNER JOIN	China.Roadside_WithResponses CS ON	V.AuditID	=	CS.AuditID  AND 
																	V.PhysicalFileRow	= CS.PhysicalRowID AND 
																	v.CountryID			= CS.CountryID
	WHERE	V.AuditID > 0	AND	
			V.PhysicalFileRow > 0 AND
			V.CountryID > 0 AND
			V.AuditItemID > 0 
	
	--ROADSIDE 
	-- UPDATE AuditItemID AND SET THE DateStamp
	IF @RowsToUpdate > 0
	BEGIN
		UPDATE CSR
		SET
			CSR.AuditItemID = V.AuditItemID
		FROM China.Roadside_WithResponses CSR
		INNER JOIN (
			SELECT	AuditItemID,
					AuditID,
					PhysicalFileRow,
					CountryID
			FROM	dbo.VWT
			WHERE AuditID > 0		
			AND PhysicalFileRow > 0
			AND CountryID > 0
			AND AuditItemID > 0 
		) V ON	CSR.AuditID = V.AuditID AND
				CSR.PhysicalRowID = V.PhysicalFileRow AND
				CSR.CountryID = V.CountryID
		WHERE (
			CSR.AuditItemID IS NULL OR CSR.AuditItemID = 0
		)
	END


	SELECT		@RowsToUpdate = COUNT(VWTID)
	FROM		dbo.VWT V
	INNER JOIN	China.CRC_WithResponses CS ON	V.AuditID	=	CS.AuditID  AND 
																	V.PhysicalFileRow	= CS.PhysicalRowID AND 
																	v.CountryID			= CS.CountryID
	WHERE	V.AuditID > 0	AND	
			V.PhysicalFileRow > 0 AND
			V.CountryID > 0 AND
			V.AuditItemID > 0 

	--CRC 
	-- UPDATE AuditItemID AND SET THE DateStamp
	IF @RowsToUpdate > 0
	BEGIN
		UPDATE CSR
		SET
			CSR.AuditItemID = V.AuditItemID
		FROM China.CRC_WithResponses CSR
		INNER JOIN (
			SELECT	AuditItemID,
					AuditID,
					PhysicalFileRow,
					CountryID
			FROM	dbo.VWT
			WHERE AuditID > 0		
			AND PhysicalFileRow > 0
			AND CountryID > 0
			AND AuditItemID > 0 
		) V ON	CSR.AuditID = V.AuditID AND
				CSR.PhysicalRowID = V.PhysicalFileRow AND
				CSR.CountryID = V.CountryID
		WHERE CSR.AuditItemID IS NULL OR CSR.AuditItemID = 0
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

