CREATE TRIGGER [Party].[TR_U_vwDA_LegalOrganisations] ON [Party].[vwDA_LegalOrganisations]

INSTEAD OF UPDATE

AS

	-- Purpose: Handles update to vwDA_LegalOrganisations (Organisation and LegalOrganisation tables and associated audit tables)
	--
	-- Version		Date			Developer			Comment
	--
	-- 1.0			10/05/2012		Martin Riverol		Created


	-- DISABLE COUNTS

		SET NOCOUNT ON
		SET XACT_ABORT ON
		
	-- UNDERLYING TABLE HAS A COMPUTED COLUMN ON IT
	
		SET ANSI_NULLS ON
		
	
	-- INSERT INTO AUDIT

		INSERT INTO Sample_Audit.Audit.Organisations

			(
				AuditItemID, 
				PartyID, 
				FromDate, 
				OrganisationName
			)

				SELECT
					i.AuditItemID, 
					i.PartyID, 
					i.FromDate, 
					i.OrganisationName	
				FROM inserted AS i


		INSERT INTO Sample_Audit.Audit.LegalOrganisations

			(
				AuditItemID, 
				PartyID, 
				LegalName
			)

				SELECT
					i.AuditItemID, 
					i.PartyID, 
					i.LegalName
				FROM inserted AS i

	-- FOR ROWS WHERE UPDATE HAS BEEN MADE MAKE UPDATE TO ORGANISATION TABLE

		UPDATE O
			SET O.OrganisationName = i.OrganisationName
		FROM sample.Party.Organisations O
		INNER JOIN inserted AS i ON O.PartyID = i.PartyID
		INNER JOIN deleted AS d ON i.PartyID = d.PartyID
		WHERE NOT 
			(
				i.OrganisationName = O.OrganisationName 
				AND BINARY_CHECKSUM(i.OrganisationName) = BINARY_CHECKSUM(O.OrganisationName)
			)

	
	-- FOR ROWS WHERE UPDATE HAS BEEN MADE MAKE UPDATE TO LEGALORGANISATION TABLE
	
		UPDATE LO
			SET LO.LegalName = i.LegalName
		FROM sample.Party.LegalOrganisations LO
		INNER JOIN inserted AS i ON LO.PartyID = i.PartyID
		INNER JOIN deleted AS d ON i.PartyID = d.PartyID
		WHERE NOT 
			(
				i.LegalName = LO.LegalName
				AND BINARY_CHECKSUM(i.LegalName) = BINARY_CHECKSUM(LO.LegalName)
			)