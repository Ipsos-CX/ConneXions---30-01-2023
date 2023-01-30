CREATE TRIGGER Party.TR_I_vwDA_LegalOrganisations ON Party.vwDA_LegalOrganisations
INSTEAD OF INSERT

AS

/*
	Purpose:	Handles insert into vwDA_LegalOrganisations.
				All rows in VWT containing organisation information should be inserted into view.
				Those that are 'parents' and have not been matched are used to populate Parties and Organisations tables, with the PartyIDs being written back to the VWT.
				All rows are written to the Audit_Organisations table
	
	Version		Date			Developer			Comment
	1.0			$(ReleaseDate)	Simon Peacock		Created from [Prophet-ODS].dbo.vwDA_LegalOrganisations.TR_I_vwDA_LegalOrganisations
	1.1			2021-06-04		Chris Ledger		Task 472: Update Organisations table based on UseLatestName flag

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
		DECLARE @Organisations TABLE
		(
			ID INT IDENTITY(1, 1) NOT NULL, 
			AuditItemID BIGINT NOT NULL, 
			PartyID INT,
			FromDate DATETIME2 NOT NULL, 
			OrganisationName NVARCHAR(510), 
			LegalName NVARCHAR(510)
		)

		-- GET THE NEW (UNMATCHED) UNIQUE ORGANISATION DATA
		INSERT INTO @Organisations
		(
			AuditItemID, 
			FromDate, 
			OrganisationName, 
			LegalName
		)
		SELECT
			AuditItemID, 
			FromDate, 
			OrganisationName, 
			LegalName
		FROM INSERTED
		WHERE ParentAuditItemID = AuditItemID
		AND PartyID = 0


		-- GET THE MAXIMUM PARTYID
		SELECT @Max_PartyID = ISNULL(MAX(PartyID), 0) FROM Party.Parties

		-- GENERATE THE NEW PARTYIDS USING THE IDENTITY VALUE
		UPDATE @Organisations
		SET PartyID = ID + @Max_PartyID

		-- ADD THE NEW ORGANISATIONS TO THE PARTIES TABLE
		INSERT INTO Party.Parties
		(
			PartyID
		)
		SELECT DISTINCT
			PartyID
		FROM @Organisations
		ORDER BY PartyID


		-- ADD THE NEW ORGANISATIONS TO THE ORGANISATIONS TABLE
		INSERT INTO Party.Organisations
		(
			PartyID, 
			OrganisationName
		)
		SELECT DISTINCT
			PartyID, 
			OrganisationName
		FROM @Organisations
		ORDER BY PartyID


		-- ADD THE NEW ORGANISATIONS TO THE LEGAL ORGANISATIONS TABLE
		INSERT INTO Party.LegalOrganisations
		(
			PartyID, 
			LegalName
		)
		SELECT DISTINCT
			PartyID, 
			LegalName
		FROM @Organisations
		ORDER BY PartyID
		
		-- UPDATE VWT WITH PARTYIDS OF INSERTED ORGANISATIONS
		UPDATE V
		SET V.MatchedODSOrganisationID = O.PartyID
		FROM [$(ETLDB)].dbo.VWT V
		INNER JOIN @Organisations O ON O.AuditItemID = V.OrganisationParentAuditItemID

		-- INSERT ALL THE PEOPLE INTO Audit.Organisations WHERE WE'VE NOT ALREADY LOADED THEM
		INSERT INTO [$(AuditDB)].Audit.Organisations
		(
			AuditItemID,
			PartyID, 
			FromDate, 
			OrganisationName,
			UseLatestName			-- V1.1
		)
		SELECT DISTINCT
			I.AuditItemID,
			COALESCE(O.PartyID, NULLIF(I.PartyID, 0)),
			I.FromDate, 
			I.OrganisationName,
			I.UseLatestName			-- V1.1
		FROM INSERTED I
		LEFT JOIN @Organisations O ON O.AuditItemID = I.ParentAuditItemID
		LEFT JOIN [$(AuditDB)].Audit.Organisations AO ON AO.AuditItemID = I.AuditItemID
													AND AO.PartyID = I.PartyID
		WHERE AO.AuditItemID IS NULL
		ORDER BY I.AuditItemID	


		-- INSERT ALL THE PEOPLE INTO Audit.LegalOrganisations WHERE WE'VE NOT ALREADY LOADED THEM
		INSERT INTO [$(AuditDB)].Audit.LegalOrganisations
		(
			AuditItemID,
			PartyID, 
			LegalName
		)
		SELECT DISTINCT
			I.AuditItemID,
			COALESCE(O.PartyID, NULLIF(I.PartyID, 0)),
			I.OrganisationName
		FROM INSERTED I
		LEFT JOIN @Organisations O ON O.AuditItemID = I.ParentAuditItemID
		LEFT JOIN [$(AuditDB)].Audit.LegalOrganisations AO ON AO.AuditItemID = I.AuditItemID
													AND AO.PartyID = I.PartyID
		WHERE AO.AuditItemID IS NULL
		ORDER BY I.AuditItemID	


		-- V1.1 UPDATE ORGANISATIONS TABLE BASED ON USELATESTNAME FLAG
		UPDATE O
		SET O.OrganisationName = I.OrganisationName,
			O.UseLatestName = I.UseLatestName
		FROM INSERTED I
			INNER JOIN Party.Organisations O ON O.PartyID = I.PartyID
			LEFT JOIN @Organisations NO ON NO.AuditItemID = I.ParentAuditItemID
		WHERE I.UseLatestName = 1
			AND NO.ID IS NULL


		-- V1.1 UPDATE LEGALORGANISATIONS TABLE BASED ON USELATESTNAME FLAG
		UPDATE LO
		SET LO.LegalName = I.OrganisationName
		FROM INSERTED I
			INNER JOIN Party.LegalOrganisations LO ON LO.PartyID = I.PartyID
			LEFT JOIN @Organisations NO ON NO.AuditItemID = I.ParentAuditItemID
		WHERE I.UseLatestName = 1
			AND NO.ID IS NULL

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