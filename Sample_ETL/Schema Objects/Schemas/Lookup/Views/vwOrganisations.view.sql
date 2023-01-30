CREATE VIEW [Lookup].[vwOrganisations]
AS
WITH O (OrganisationNameChecksum, LegalName, PartyID)
	AS (
		SELECT DISTINCT
			 OrganisationNameChecksum
			,LegalName
			,PartyID
		FROM [$(SampleDB)].Party.LegalOrganisations
		UNION
		SELECT DISTINCT
			 OrganisationNameChecksum
			,OrganisationName
			,PartyID
		FROM [$(SampleDB)].Party.Organisations
	),
	PCM (PartyID, ContactMechanismID)
	AS (
		SELECT DISTINCT
			 APCM.PartyID
			,APCM.ContactMechanismID
		FROM [$(SampleDB)].ContactMechanism.PartyContactMechanisms APCM
		INNER JOIN [$(SampleDB)].ContactMechanism.PostalAddresses APA ON APA.ContactMechanismID = APCM.ContactMechanismID
	)
	SELECT DISTINCT
		O.PartyID, 
		O.LegalName as OrganisationName, 
		PCM.ContactMechanismID, 
		O.OrganisationNameChecksum
	FROM O
	INNER JOIN PCM ON PCM.PartyID = O.PartyID;
		
		