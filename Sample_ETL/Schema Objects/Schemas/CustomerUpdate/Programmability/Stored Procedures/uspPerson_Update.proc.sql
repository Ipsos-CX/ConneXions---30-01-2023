CREATE PROCEDURE CustomerUpdate.uspPerson_Update

AS

/*
	Purpose:	Update People with the data from the customer update and load into Audit.

	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock	Created from [Prophet-ETL].dbo.uspIP_CUSTOMERUPDATE_ODSUpdate_Person
	1.1				05/06/2017		Chris Ross			BUG 14039 - Add in a check into CasePartyCombinationValid that the checks LastName is populated too. 
	1.2				10/01/2020		Chris Ledger		BUG 15372 - Fix Hard coded references to databases
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
	
		-- Check the CaseID and PartyID combination is valid
		UPDATE CUP
		SET CUP.CasePartyCombinationValid = 1
		FROM CustomerUpdate.Person CUP
		INNER JOIN [$(SampleDB)].Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = CUP.CaseID
										AND AEBI.PartyID = CUP.PartyID
		WHERE ISNULL(CUP.LastName,'') <> ''	-- v1.1
	
		-- get the unknown title
		DECLARE @UnknownTitleID SMALLINT
		
		SELECT @UnknownTitleID = TitleID FROM [$(SampleDB)].Party.Titles WHERE Title = ''
		
		-- THE VIEW vwDA_People HAS AN INSTEAD OF UPDATE TRIGGER ON IT
		-- THIS MEANS WE CANNOT WRITE A STATEMENT THAT PERFORMS AN UPDATE BY JOINING THE VIEW TO OTHER TABLES
		-- e.g. WE CAN'T WRITE SOMETHING LIKE
		--	UPDATE P
		--	SET P.FirstName = CUP.FirstName
		--	FROM CustomerUpdate.Perons CUP
		--	INNER JOIN [$(SampleDB)].Party.vwDA_Person P ON P.PartyID = CUP.PartyID
		-- THE ONLY WAY IS CAN SEE AROUND THIS IS TO GET THE DATA AND UPDATE THE VIEW ONE ROW AT A TIME
		-- IF ANYONE READING THIS KNOWS A BETTER WAY PLEASE UPDATE THIS CODE!
		
		-- GET THE DATA WE WANT TO LOAD IN A TEMPORARY TABLE
		SELECT
			 IDENTITY(INT, 1, 1) AS ID
			,CUP.AuditItemID
			,CUP.PartyID
			,ISNULL(PNT.TitleID, @UnknownTitleID) AS TitleID
			,ISNULL(CUP.Title, '') AS Title
			,CUP.FirstName
			,CUP.LastName
			,CUP.SecondLastName
		INTO #DATA
		FROM CustomerUpdate.Person CUP
		INNER JOIN [$(SampleDB)].Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = CUP.CaseID AND AEBI.PartyID = CUP.PartyID
		LEFT JOIN [$(SampleDB)].Party.Titles PNT ON PNT.Title = CUP.Title
		WHERE CUP.AuditItemID = CUP.ParentAuditItemID
		AND CUP.CasePartyCombinationValid = 1
		
		-- DECLARE VARIABLES TO HOLD EACH PIECE OF DATA WE COULD UPDATE
		DECLARE @AuditItemID dbo.AuditItemID
		DECLARE @PartyID dbo.PartyID
		DECLARE @TitleID dbo.TitleID
		DECLARE @Title dbo.Title
		DECLARE @FirstName dbo.NameDetail
		DECLARE @LastName dbo.NameDetail
		DECLARE @SecondLastName dbo.NameDetail

		-- USE THE IDENTITY COLUMN TO LOOP THROUGH THE 
		DECLARE @Counter INT
		
		SET @Counter = 1
		
		WHILE @Counter <= (SELECT MAX(ID) FROM #DATA)
		BEGIN
		
			SELECT
				 @AuditItemID = AuditItemID
				,@PartyID = PartyID
				,@TitleID = TitleID
				,@Title = Title
				,@FirstName = FirstName
				,@LastName = LastName
				,@SecondLastName = SecondLastName
			FROM #DATA
			WHERE ID = @Counter
			
			UPDATE [$(SampleDB)].Party.vwDA_People
			SET
				AuditItemID = @AuditItemID,
				TitleID = @TitleID,
				Title = @Title,
				FirstName = @FirstName,
				LastName = @LastName,
				SecondLastName = @SecondLastName
			WHERE PartyID = @PartyID
		
			SET @Counter += 1
		END

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












