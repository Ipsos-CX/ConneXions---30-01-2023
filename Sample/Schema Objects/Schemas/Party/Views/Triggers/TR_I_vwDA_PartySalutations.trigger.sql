CREATE TRIGGER Party.TR_I_vwDA_PartySalutations ON Party.vwDA_PartySalutations
INSTEAD OF INSERT

AS

/*
	Purpose:	Handles insert into vwDA_Salutations
				All rows in VWT containing Language information should be inserted into this view 
				All rows are written to the Audit.Salutations table
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)	Ali Yuksel			Created 

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
	
	
		-- if there are duplicate PartyIDs, get the latest one 		
		;WITH DistinctPartyIDs AS (
		
			SELECT DISTINCT ROW_NUMBER()OVER (PARTITION BY  PartyID ORDER BY  AuditItemID DESC) AS 'RN', PartyID,Salutation
			FROM INSERTED I				
		)	
		
		SELECT * INTO #DistinctPartyIDs FROM DistinctPartyIDs where RN=1
	

		--UPDATE with new salutation if PartyID already exists  
		
		UPDATE S
		SET S.Salutation=I.Salutation
		FROM Party.PartySalutations S
		INNER JOIN #DistinctPartyIDs I ON S.PartyID = I.PartyID 
		WHERE ISNULL(I.Salutation,N'')<>''
		and S.Salutation <> I.Salutation


		-- INSERT Party.Salutations that PartyID does not exist 
	
		
		INSERT INTO Party.PartySalutations
		(
			PartyID, 
			Salutation
		)
		SELECT DISTINCT
			I.PartyID, 
			I.Salutation
		FROM #DistinctPartyIDs I
		INNER JOIN Party.Parties P ON P.PartyID = I.PartyID
		LEFT JOIN Party.PartySalutations S ON S.PartyID = I.PartyID
		WHERE S.PartyID IS NULL 
		ORDER BY I.PartyID, I.Salutation
		
		
		

		-- INSERT ALL ROWS INTO AUDIT
		INSERT INTO [$(AuditDB)].Audit.PartySalutations
		(
			AuditItemID,
			PartyID, 
			Salutation
		)
		SELECT DISTINCT
			I.AuditItemID,
			I.PartyID, 
			I.Salutation
		FROM INSERTED I
		LEFT JOIN [$(AuditDB)].Audit.PartySalutations AUS ON AUS.AuditItemID = I.AuditItemID
														AND AUS.PartyID = I.PartyID
		WHERE AUS.AuditItemID IS NULL
		ORDER BY I.AuditItemID

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
	











