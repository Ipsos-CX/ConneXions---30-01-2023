WITH O (OrganisationNameChecksum, LegalName, PartyID)
	AS (
		SELECT DISTINCT
			 CHECKSUM(ISNULL(LegalName, '')) AS OrganisationNameChecksum
			,LegalName
			,PartyID
		FROM [Sample_Audit].Audit.LegalOrganisations
		UNION
		SELECT DISTINCT
			 CHECKSUM(ISNULL(OrganisationName, '')) AS NameChecksum
			,OrganisationName
			,PartyID
		FROM [Sample_Audit].Audit.Organisations
	),
	PCM (PartyID, ContactMechanismID)
	AS (
		SELECT DISTINCT
			 APCM.PartyID
			,APCM.ContactMechanismID
		FROM [Sample_Audit].Audit.PartyContactMechanisms APCM
		INNER JOIN [Sample_Audit].Audit.PostalAddresses APA ON APA.ContactMechanismID = APCM.ContactMechanismID
	)
	SELECT DISTINCT
		O.PartyID, 
		O.LegalName as OrganisationName, 
		PCM.ContactMechanismID, 
		O.OrganisationNameChecksum
	FROM O
	INNER JOIN PCM ON PCM.PartyID = O.PartyID;