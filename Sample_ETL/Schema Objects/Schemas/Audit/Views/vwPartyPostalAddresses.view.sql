/* -- CGR 14-06-2016 - Removed as part of BUG 11771 - This can be fully removed in the fullness of time	
					-- but for now I will leave in place but deactivated

CREATE VIEW Audit.vwPartyPostalAddresses
AS

	SELECT DISTINCT
		PCM.PartyID,
		PA.ContactMechanismID
	FROM [$(AuditDB)].Audit.PostalAddresses PA
	INNER JOIN [$(AuditDB)].Audit.PartyContactMechanisms PCM ON PCM.ContactMechanismID = PA.ContactMechanismID


*/