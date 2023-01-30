/* -- CGR 14-06-2016 - Removed as part of BUG 11771 - This can be fully removed in the fullness of time	
					-- but for now I will leave in place but deactivated

CREATE VIEW [Audit].[vwOrganisations]
AS

WITH O (OrganisationNameChecksum, LegalName, PartyID)
	AS (
		SELECT DISTINCT
			 OrganisationNameChecksum
			,LegalName
			,PartyID
		FROM [$(AuditDB)].Audit.LegalOrganisations
		UNION
		SELECT DISTINCT
			 OrganisationNameChecksum
			,OrganisationName
			,PartyID
		FROM [$(AuditDB)].Audit.Organisations
	),
	PCM (PartyID, ContactMechanismID)
	AS (
		SELECT DISTINCT
			 APCM.PartyID
			,APCM.ContactMechanismID
		FROM [$(AuditDB)].Audit.PartyContactMechanisms APCM
		INNER JOIN [$(AuditDB)].Audit.PostalAddresses APA ON APA.ContactMechanismID = APCM.ContactMechanismID
	)
	SELECT DISTINCT
		O.PartyID, 
		O.LegalName as OrganisationName, 
		PCM.ContactMechanismID, 
		O.OrganisationNameChecksum
	FROM O
	INNER JOIN PCM ON PCM.PartyID = O.PartyID;
		
*/