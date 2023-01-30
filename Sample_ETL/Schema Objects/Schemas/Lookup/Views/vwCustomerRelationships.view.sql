CREATE VIEW Lookup.vwCustomerRelationships

AS

/*
	Purpose:	Get PartyIDs and CustomerIdentifiers from Sample database
	
	Version			Date			Developer			Comment
	1.0				09-06-2016		Chris Ross			BUG 11771 : Modified from Audit.vwCustomerRelationships

*/

	SELECT DISTINCT
		P.PartyID AS MatchedODSPersonID, 
		O.PartyID AS MatchedODSOrganisationID, 
		CR.PartyIDTo AS CustomerIdentifierOriginatorPartyID, 
		CR.CustomerIdentifier 
	FROM [$(SampleDB)].Party.CustomerRelationships CR
	LEFT JOIN [$(SampleDB)].Party.People P ON P.PartyID = CR.PartyIDFrom
	LEFT JOIN [$(SampleDB)].Party.Organisations O ON O.PartyID = CR.PartyIDFrom
	WHERE CR.CustomerIdentifierUsable = 1
