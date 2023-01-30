CREATE PROCEDURE CustomerUpdate.uspPerson_Insert

AS

/*
	Purpose:	Insert into People the data from the customer update and load into Audit

	
	Version		Date			Developer			Comment
	1.0			$(ReleaseDate)	Simon Peacock		Created from [Prophet-ETL].dbo.uspIP_CUSTOMERUPDATE_ODSInsert_Person
	1.1			26/04/2012		Attila.Kubanda		BUG 6779 - Inserting into the Party.vwDA_People when we already have a PartyID will not write the party details into people. This step has been taken out and replaced with direct insert script to the relevant audit and sample party tables.
	1.2			18/12/2013		Martin Riverol		BUG 9798 - Add any unknown titles
	1.3			05/06/2017		Chris Ross			BUG 14039 - Add in a check into CasePartyCombinationValid that the checks LastName is populated too. 
	1.4			10/01/2020		Chris Ledger		BUG 15372 - Fix Hard coded references to databases	
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
	
		-- get the unknown title
		DECLARE @UnknownTitleID SMALLINT
		
		SELECT @UnknownTitleID = TitleID FROM [$(SampleDB)].Party.Titles WHERE Title = ''

		-- Check the CaseID and PartyID combination is valid
		UPDATE CUP
		SET CUP.CasePartyCombinationValid = 1
		FROM CustomerUpdate.Person CUP
		INNER JOIN [$(SampleDB)].Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = CUP.CaseID
										AND AEBI.PartyID = CUP.PartyID
		WHERE ISNULL(CUP.LastName,'') <> ''	-- v1.3


/* ADD ANY NEW TITLES THAT ARRIVE */	

		INSERT INTO [$(SampleDB)].Party.vwDA_Titles

			(
				AuditItemID, 
				TitleID, 
				Title
			)
				SELECT 
					AuditItemID, 
					TitleID, 
					Title
				FROM CustomerUpdate.Person
				WHERE ISNULL(TitleID, 0) = 0

		-- Get the TitleID if present
		UPDATE CUP
		SET CUP.TitleID = T.TitleID
		FROM CustomerUpdate.Person CUP
		INNER JOIN [$(SampleDB)].Party.Titles T ON T.Title = CUP.Title
		AND CUP.CasePartyCombinationValid = 1  -- v1.3

		-- We only want to insert new names for parties that are currently organisations
		-- Once we have inserted the name we also need to create a new party for the original
		-- organisation name and give this a new PartyRole
		CREATE TABLE #DATA
		(
			ParentAuditItemID BIGINT,
			AuditItemID BIGINT,
			PartyID INT,
			TitleID SMALLINT,
			Title NVARCHAR(100),
			FirstName NVARCHAR(100),
			LastName NVARCHAR(100),
			SecondLastName NVARCHAR(100),
			OrganisationName NVARCHAR(510),
			LegalName NVARCHAR(510),
			OrganisationPartyID INT
		)

		INSERT INTO #DATA
		(
			ParentAuditItemID,
			AuditItemID,
			PartyID,
			TitleID,
			Title,
			FirstName,
			LastName,
			SecondLastName,
			OrganisationName,
			LegalName
		)
		SELECT DISTINCT
			CUP.ParentAuditItemID,
			CUP.AuditItemID,
			CUP.PartyID,
			CUP.TitleID,
			CUP.Title,
			CUP.FirstName,
			CUP.LastName,
			CUP.SecondLastName,
			O.OrganisationName,
			LO.LegalName AS LegalName
		FROM CustomerUpdate.Person CUP
		INNER JOIN [$(SampleDB)].Party.Organisations O ON O.PartyID = CUP.PartyID
		LEFT JOIN [$(SampleDB)].Party.LegalOrganisations LO ON LO.PartyID = O.PartyID
		LEFT JOIN [$(SampleDB)].Party.People P ON P.PartyID = CUP.PartyID
		WHERE CUP.CasePartyCombinationValid = 1
		AND ISNULL(CUP.LastName, '') <> ''
		AND P.PartyID IS NULL
		AND CUP.AuditItemID = CUP.ParentAuditItemID

		-- Add the new person details to the
		INSERT INTO [$(SampleDB)].Party.People
		(
			PartyID, 
			FromDate, 
			TitleID, 
			Initials, 
			FirstName, 
			LastName, 
			SecondLastName
		)
		SELECT DISTINCT
			D.PartyID,
			GETDATE(), 
			ISNULL(D.TitleID, @UnknownTitleID) AS TitleID,
			D.Title, 
			D.FirstName, 
			D.LastName, 
			D.SecondLastName
		FROM #DATA D
		ORDER BY D.PartyID


		-- INSERT ALL THE PEOPLE INTO Audit.Parties WHERE WE'VE NOT ALREADY LOADED THEM
		INSERT INTO [$(AuditDB)].Audit.Parties
		(
			AuditItemID, 		
			PartyID, 
			FromDate
		)
		SELECT DISTINCT
			CUP.AuditItemID, 
			CUP.PartyID, 
			GETDATE()
		FROM CustomerUpdate.Person CUP
		LEFT JOIN [$(AuditDB)].Audit.Parties AP ON AP.PartyID = CUP.PartyID
											AND AP.AuditItemID = CUP.AuditItemID
		WHERE AP.AuditItemID IS NULL
		AND CUP.CasePartyCombinationValid = 1  -- v1.3
		ORDER BY CUP.AuditItemID


		-- INSERT ALL THE PEOPLE INTO Audit.People WHERE WE'VE NOT ALREADY LOADED THEM
		INSERT INTO [$(AuditDB)].Audit.People
		(
			AuditItemID,
			PartyID, 
			FromDate, 
			TitleID, 
			Title, 
			FirstName, 
			LastName, 
			SecondLastName
		)
		SELECT DISTINCT
			CUP.AuditItemID,
			CUP.PartyID,
			GETDATE(), 
			ISNULL(CUP.TitleID, @UnknownTitleID) AS TitleID,
			CUP.Title, 
			CUP.FirstName, 
			CUP.LastName, 
			CUP.SecondLastName
		FROM CustomerUpdate.Person CUP
		LEFT JOIN [$(AuditDB)].Audit.People AP ON AP.PartyID = CUP.PartyID
											AND AP.AuditItemID = CUP.AuditItemID
		WHERE AP.PartyID IS NULL
		AND CUP.CasePartyCombinationValid = 1  -- v1.3
		ORDER BY CUP.PartyID
		
		
		--INSERT INTO [$(SampleDB)].Party.vwDA_People		v1.1 replaced script
		--(
			--ParentAuditItemID,
			--AuditItemID,
			--PartyID,
			--TitleID,
			--Title,
			--FirstName,
			--LastName,
			--SecondLastName,
			--FromDate
		--)
		--SELECT DISTINCT
			--D.ParentAuditItemID,
			--D.AuditItemID,
			--D.PartyID,
			--ISNULL(D.TitleID, @UnknownTitleID) AS TitleID,
			--D.Title,
			--D.FirstName,
			--D.LastName,
			--D.SecondLastName,
			--GETDATE()
		--FROM #DATA D
		--WHERE ISNULL(D.LastName, '') <> ''

		
		-- get the Employee and Employer role types
		DECLARE @EmployeeRoleTypeID SMALLINT
		DECLARE @EmployerRoleTypeID SMALLINT
		
		SELECT @EmployeeRoleTypeID = RoleTypeID FROM [$(SampleDB)].dbo.RoleTypes WHERE RoleType = 'Employee'
		SELECT @EmployerRoleTypeID = RoleTypeID FROM [$(SampleDB)].dbo.RoleTypes WHERE RoleType = 'Employer'

		-- Add the PartyRoles
		INSERT INTO [$(SampleDB)].Party.vwDA_PartyRoles
		(
			AuditItemID,
			PartyID,
			RoleTypeID,
			FromDate,
			ThroughDate
		)
		SELECT DISTINCT
			D.AuditItemID,
			D.PartyID,
			@EmployeeRoleTypeID AS RoleTypeID,
			GETDATE() AS FromDate,
			NULL AS ThroughDate
		FROM #DATA D
		LEFT JOIN [$(SampleDB)].Party.PartyRoles PR ON PR.PartyID = D.PartyID
												AND PR.RoleTypeID = @EmployeeRoleTypeID
		WHERE PR.PartyID IS NULL

		-- Create new organisation details
		INSERT INTO [$(SampleDB)].Party.vwDA_LegalOrganisations
		(
			PartyID,
			Fromdate,
			OrganisationName,
			LegalName,
			ParentAuditItemID,
			AuditItemID
		)
		SELECT DISTINCT
			0 AS PartyID,
			GETDATE() AS Fromdate,
			OrganisationName,
			LegalName,
			AuditItemID AS ParentAuditItemID,
			AuditItemID
		FROM #DATA

		-- Create new organisation PartyRole details
		-- get the new organisation PartyID
		UPDATE D
		SET D.OrganisationPartyID = O.PartyID
		FROM [$(SampleDB)].Party.Organisations O
		INNER JOIN #DATA D ON D.OrganisationName = O.OrganisationName
				AND D.PartyID <> O.PartyID
				

		INSERT INTO [$(SampleDB)].Party.vwDA_EmployeeRelationships
		(
			AuditItemID,
			PartyIDFrom,
			PartyIDTo,
			RoleTypeIDFrom,
			RoleTypeIDTo,
			FromDate,
			ThroughDate,
			PartyRelationshipTypeID,
			EmployeeIdentifier,
			EmployeeIdentifierUsable
		)
		SELECT DISTINCT
			D.AuditItemID AS AuditItemID,
			D.PartyID AS PartyIDFrom,
			D.OrganisationPartyID AS PartyIDTo,
			@EmployeeRoleTypeID AS RoleTypeIDFrom,
			@EmployerRoleTypeID AS RoleTypeIDTo,
			GETDATE() AS FromDate,
			NULL AS ThroughDate,
			1 AS PartyRelationshipTypeID,
			'' AS EmployeeIdentifier,
			1 AS EmployeeIdentifierUsable
		FROM #DATA D


		-- Finally delete the original Organisation value
		DELETE FROM [$(SampleDB)].Party.LegalOrganisations WHERE PartyID IN (SELECT PartyID FROM #DATA)
		DELETE from [$(SampleDB)].Party.Organisations WHERE PartyID IN (SELECT PartyID FROM #DATA)

		DROP TABLE #DATA

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








