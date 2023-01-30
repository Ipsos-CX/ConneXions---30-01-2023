CREATE TRIGGER Party.TR_I_vwDA_People ON Party.vwDA_People
INSTEAD OF INSERT

AS

/*
	Purpose:	Handles insert into vwDA_People.
				All rows in VWT containing person information should be inserted into view.
				Those that are 'parents' and have not been matched are used to populate Party and People tables, with the PartyIDs being written back to the VWT.
				All rows are written to the Audit_People table
	
	Version		Date			Developer			Comment
	1.0			$(ReleaseDate)	Simon Peacock		Created from [Prophet-ODS].dbo.vwDA_People.TR_I_vwDA_People
	1.1			2021-06-04		Chris Ledger		Task 472: Update People table based on UseLatestName flag

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

		-- CREATE VARIABLE TO HOLD THE MAXIMUM PARTYID
		DECLARE @Max_PartyID INT

		-- CREATE A TABLE TO STORE THE NEW PEOPLE DATA
		DECLARE @People TABLE
		(
			ID INT IDENTITY(1, 1) NOT NULL, 
			AuditItemID BIGINT NOT NULL, 
			PartyID INT,
			UNIQUE(PartyID, ID)
		)

		-- GET THE NEW (UNMATCHED) UNIQUE PEOPLE DATA
		INSERT INTO @People
		(
			AuditItemID
		)
		SELECT
			AuditItemID
		FROM INSERTED
		WHERE ParentAuditItemID = AuditItemID
			AND PartyID = 0

		-- GET THE MAXIMUM PARTYID
		SELECT @Max_PartyID = ISNULL(MAX(PartyID), 0) FROM Party.Parties

		-- GENERATE THE NEW PARTYIDS USING THE IDENTITY VALUE
		UPDATE @People
		SET PartyID = ID + @Max_PartyID

		-- ADD THE NEW PARTIES TO THE PARTIES TABLE
		INSERT INTO Party.Parties
		(
			PartyID
		)
		SELECT
			PartyID
		FROM @People
		ORDER BY PartyID


		-- ADD THE NEW PARTIES TO THE PEOPLE TABLE
		INSERT INTO Party.People
		(
			PartyID, 
			FromDate, 
			TitleID, 
			Initials, 
			FirstName, 
			MiddleName, 
			LastName, 
			SecondLastName, 
			GenderID, 
			BirthDate,
			MonthAndYearOfBirth,
			PreferredMethodOfContact,
			UseLatestName				-- V1.1
		)
		SELECT DISTINCT
			P.PartyID, 
			I.FromDate, 
			I.TitleID, 
			I.Initials, 
			I.FirstName, 
			I.MiddleName, 
			I.LastName, 
			I.SecondLastName, 
			I.GenderID, 
			I.BirthDate,
			I.MonthAndYearOfBirth,
			I.PreferredMethodOfContact,
			I.UseLatestName				-- V1.1			
		FROM INSERTED I
			INNER JOIN @People P ON P.AuditItemID = I.AuditItemID
		ORDER BY P.PartyID
		

		-- UPDATE VWT WITH PARTYIDS OF INSERTED PEOPLE
		UPDATE V
		SET V.MatchedODSPersonID = P.PartyID
		FROM [$(ETLDB)].dbo.VWT V
			INNER JOIN @People P ON P.AuditItemID = V.PersonParentAuditItemID


		-- INSERT ALL THE PEOPLE INTO Audit.Parties WHERE WE'VE NOT ALREADY LOADED THEM
		INSERT INTO [$(AuditDB)].Audit.Parties
		(
			AuditItemID, 		
			PartyID, 
			FromDate
		)
		SELECT DISTINCT
			I.AuditItemID, 
			COALESCE(P.PartyID, I.PartyID), 
			I.FromDate
		FROM INSERTED I
			LEFT JOIN @People P ON P.AuditItemID = I.ParentAuditItemID		
			LEFT JOIN [$(AuditDB)].Audit.Parties AP ON AP.PartyID = COALESCE(P.PartyID, NULLIF(I.PartyID, 0))
													AND AP.AuditItemID = I.AuditItemID
		WHERE AP.AuditItemID IS NULL
		ORDER BY I.AuditItemID


		-- INSERT ALL THE PEOPLE INTO Audit.People WHERE WE'VE NOT ALREADY LOADED THEM
		INSERT INTO [$(AuditDB)].Audit.People
		(
			AuditItemID,
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
			UseLatestName				-- V1.1
		)
		SELECT DISTINCT
			I.AuditItemID,
			COALESCE(P.PartyID, I.PartyID),
			I.FromDate, 
			I.TitleID, 
			I.Title, 
			I.Initials, 
			I.FirstName, 
			I.MiddleName, 
			I.LastName, 
			I.SecondLastName, 
			I.FirstNameOrig, 
			I.LastNameOrig, 
			I.SecondLastNameOrig, 
			I.GenderID, 
			I.BirthDate,
			I.MonthAndYearOfBirth,
			I.PreferredMethodOfContact,
			I.UseLatestName					-- V1.1		
		FROM INSERTED I
			LEFT JOIN @People P ON P.AuditItemID = I.ParentAuditItemID
			LEFT JOIN [$(AuditDB)].Audit.People AP ON AP.PartyID = COALESCE(P.PartyID, NULLIF(I.PartyID, 0))
												AND AP.AuditItemID = I.AuditItemID
		WHERE AP.PartyID IS NULL
		ORDER BY COALESCE(P.PartyID, I.PartyID)		


		-- V1.1 UPDATE PEOPLE TABLE BASED ON USELATESTNAME FLAG
		UPDATE P
		SET P.PartyID = I.PartyID, 
			P.FromDate = I.FromDate, 
			P.TitleID = I.TitleID, 
			P.Initials = I.Initials, 
			P.FirstName = I.FirstName, 
			P.MiddleName = I.MiddleName, 
			P.LastName = I.LastName, 
			P.SecondLastName = I.SecondLastName, 
			P.GenderID = I.GenderID, 
			P.BirthDate = I.BirthDate,
			P.MonthAndYearOfBirth = I.MonthAndYearOfBirth,
			P.PreferredMethodOfContact = I.PreferredMethodOfContact,
			P.UseLatestName = I.UseLatestName
		FROM INSERTED I
			INNER JOIN Party.People P ON P.PartyID = I.PartyID
			LEFT JOIN @People NP ON NP.AuditItemID = I.ParentAuditItemID
		WHERE I.UseLatestName = 1
			AND NP.ID IS NULL

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