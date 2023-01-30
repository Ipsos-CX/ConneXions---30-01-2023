/* -- CGR 14-06-2016 - Removed as part of BUG 11771 - This can be fully removed in the fullness of time	
					-- but for now I will leave in place but deactivated

CREATE VIEW Audit.vwCustomerRelationships

AS


	--Purpose:	Get PartyIDs and CustomerIdentifiers from Audit database
	
	--Version			Date			Developer			Comment
	--1.0				$(ReleaseDate)		Simon Peacock		Created from [Prophet-ETL].dbo.vwAUDIT_CustomerRelationships


	SELECT DISTINCT
		P.PartyID AS MatchedODSPersonID, 
		O.PartyID AS MatchedODSOrganisationID, 
		CR.PartyIDTo AS CustomerIdentifierOriginatorPartyID, 
		CR.CustomerIdentifier 
	FROM [$(AuditDB)].Audit.CustomerRelationships CR
	LEFT JOIN [$(AuditDB)].Audit.People P ON P.PartyID = CR.PartyIDFrom
	LEFT JOIN [$(AuditDB)].Audit.Organisations O ON O.PartyID = CR.PartyIDFrom
	WHERE CR.CustomerIdentifierUsable = 1


*/