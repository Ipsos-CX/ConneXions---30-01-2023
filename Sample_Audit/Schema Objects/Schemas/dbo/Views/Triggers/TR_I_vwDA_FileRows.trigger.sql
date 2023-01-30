CREATE TRIGGER dbo.TR_I_vwDA_FileRows ON dbo.vwDA_FileRows
INSTEAD OF INSERT
AS 

/*
	Purpose:	Handles insert into FileRows table by first inserting into AuditItems and then updating VWT.AuditItemID
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Reformatted from original using UDDTs and added error handling

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

		DECLARE @max_AuditItemID dbo.AuditItemID

		DECLARE @tmp TABLE 
		(
			tmpID INT IDENTITY(1, 1) NOT NULL, 
			AuditID dbo.AuditID NULL, 
			AuditItemID dbo.AuditItemID NULL, 
			PhysicalRow INT NOT NULL, 
			VWTID INT NOT NULL
		)

		INSERT INTO @tmp
		(
			AuditID, 
			PhysicalRow, 
			VWTID
		)
		SELECT
			I.AuditID, 
			I.PhysicalRow, 
			I.VWTID
		FROM INSERTED I

		-- GET THE MAXIMUM AuditItemID
		SELECT @max_AuditItemID = ISNULL(MAX(AuditItemID), 0) FROM dbo.AuditItems

		-- UPDATE AuditItemID IN TABLE VARIABLE
		UPDATE @tmp
		SET AuditItemID = tmpID + @max_AuditItemID

		-- INSERT GENERATED AuditItemIDs into dbo.AuditItems
		INSERT INTO dbo.AuditItems
		(
			AuditItemID, 
			AuditID
		)
		SELECT
			AuditItemID, 
			AuditID
		FROM @tmp
		ORDER BY tmpID 

		-- INSERT GENERATED AuditItemIDs AND PhysicalRow VALUE INTO dbo.FileRows
		INSERT INTO dbo.FileRows
		(
			AuditItemID, 
			PhysicalRow
		)
		SELECT
			AuditItemID, 
			PhysicalRow
		FROM @tmp
		ORDER BY tmpID

		-- WRITE THE AuditItemIDs back TO VWT
		UPDATE V
		SET V.AuditItemID = T.AuditItemID
		FROM [$(ETLDB)].dbo.VWT V
		INNER JOIN @tmp T ON V.VWTID = T.VWTID
		
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

