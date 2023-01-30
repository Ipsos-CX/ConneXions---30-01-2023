CREATE VIEW [Load].[vwContactPreferences]
AS
SELECT
	AuditItemID, 
	COALESCE(NULLIF(MatchedODSPersonID, 0), NULLIF(MatchedODSOrganisationID, 0), MatchedODSPartyID) AS PartyID, 
	EventCategoryID, 
	ISNULL(PartySuppression, 0) AS PartySuppression, 
	ISNULL(PostalSuppression, 0) AS PostalSuppression, 
	ISNULL(EmailSuppression, 0) AS EmailSuppression, 
	ISNULL(PhoneSuppression, 0) AS PhoneSuppression, 
	'Sample' AS UpdateSource,
	CountryID
FROM dbo.VWT v
INNER JOIN [$(SampleDB)].Event.EventTypeCategories ec ON ec.EventTypeID = v.ODSEventTypeID


