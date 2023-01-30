/* -- CGR 14-06-2016 - Removed as part of BUG 11771 - This can be fully removed in the fullness of time	
					-- but for now I will leave in place but deactivated

CREATE VIEW Audit.vwPeople

AS

SELECT DISTINCT
	PartyID, 
	NameChecksum		
FROM [$(AuditDB)].Audit.People



*/