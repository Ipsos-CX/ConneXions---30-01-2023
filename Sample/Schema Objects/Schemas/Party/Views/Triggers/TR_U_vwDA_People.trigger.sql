CREATE TRIGGER [Party].[TR_U_vwDA_People]
    ON [Party].[vwDA_People]
    INSTEAD OF UPDATE
    AS SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	BEGIN TRAN

		-- UPDATE THE PERSON DETAILS		
		UPDATE P
		SET
			P.TitleID = ISNULL(I.TitleID, P.TitleID),
			P.FirstName = ISNULL(I.FirstName, P.FirstName),
			P.Initials = ISNULL(I.Initials, P.Initials),
			P.MiddleName = ISNULL(I.MiddleName, P.MiddleName),
			P.LastName = ISNULL(I.LastName, P.LastName),
			P.SecondLastName = ISNULL(I.SecondLastName, P.SecondLastName),
			P.BirthDate = ISNULL(I.BirthDate, P.BirthDate),
			P.GenderID = ISNULL(I.GenderID, P.GenderID),
			P.MonthAndYearOfBirth = ISNULL(I.MonthAndYearOfBirth,P.MonthAndYearOfBirth),
			P.PreferredMethodOfContact = ISNULL(I.PreferredMethodOfContact,P.PreferredMethodOfContact)
		FROM Party.People P
		INNER JOIN INSERTED I ON I.PartyID = P.PartyID
		
		-- ADD THE AUDIT INFO
		INSERT INTO [Sample_Audit].Audit.People
		(
			AuditItemID,
			PartyID,
			TitleID,
			FirstName,
			Initials,
			MiddleName,
			LastName,
			SecondLastName,
			BirthDate,
			GenderID,
			MonthAndYearOfBirth,
			PreferredMethodOfContact,
			FromDate
		)
		SELECT
			AuditItemID,
			PartyID,
			TitleID,
			FirstName,
			Initials,
			MiddleName,
			LastName,
			SecondLastName,
			BirthDate,
			GenderID,
			MonthAndYearOfBirth,
			PreferredMethodOfContact,
			GETDATE()
		FROM INSERTED


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

	EXEC [Sample_Errors].dbo.uspLogDatabaseError
		 @ErrorNumber
		,@ErrorSeverity
		,@ErrorState
		,@ErrorLocation
		,@ErrorLine
		,@ErrorMessage
		
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH