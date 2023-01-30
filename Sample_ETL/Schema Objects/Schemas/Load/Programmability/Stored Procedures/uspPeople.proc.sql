CREATE PROCEDURE [Load].[uspPeople]

AS

/*
	Purpose: Write People parties to Sample database
	
	Version		Date			Developer			Comment
	1.0			$(ReleaseDate)	Simon Peacock		Created from [Prophet-ETL].dbo.uspODSLOAD_People
	1.1			2021-06-04		Chris Ledger		Task 472: Add UseLatestName
*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	INSERT INTO [$(SampleDB)].Party.vwDA_People 
	(
		AuditItemID, 
		ParentAuditItemID, 
		PartyID, 
		FromDate, 
		TitleID, 
		Title, 
		Initials, 
		FirstName, 
		MiddleName, 
		LastName, 
		SecondLastName, 
		FirstNameOrig, 
		LastNameOrig, 
		SecondLastNameOrig, 
		GenderID, 
		BirthDate,
		MonthAndYearOfBirth,
		PreferredMethodOfContact,
		UseLatestName
	)
	SELECT
		AuditItemID, 
		ParentAuditItemID, 
		MatchedODSPersonID AS PartyID, 
		FromDate, 
		TitleID, 
		Title, 
		Initials, 
		FirstName, 
		MiddleName, 
		LastName, 
		SecondLastName, 
		FirstNameOrig, 
		LastNameOrig, 
		SecondLastNameOrig, 
		GenderID, 
		BirthDate,
		MonthAndYearOfBirth,
		PreferredMethodOfContact,
		UseLatestName
	FROM Load.vwPeople
	WHERE TitleID IN (SELECT TitleID FROM [$(SampleDB)].Party.Titles)


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

