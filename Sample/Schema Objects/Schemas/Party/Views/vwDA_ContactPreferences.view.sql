		CREATE VIEW Party.vwDA_ContactPreferences
AS
SELECT	
	CONVERT(BIGINT, 0) AS AuditItemID, 
	CP.PartyID, 
	
	CPS.EventCategoryID, 
	
	CPS.PartySuppression, 
	CPS.PostalSuppression, 
	CPS.EmailSuppression, 
	CPS.PhoneSuppression, 

	CP.PartyUnsubscribe,
	
	CONVERT(VARCHAR(50), NULL) AS UpdateSource,
	CONVERT(INT, 0) AS MarketCountryID,
	
	CONVERT(BIT, 0) AS OverridePreferences,
	CONVERT(BIT, 0) AS RemoveUnsubscribe,
	
	CONVERT(VARCHAR(255), '') AS Comments
		
FROM Party.ContactPreferences CP
INNER JOIN Party.ContactPreferencesBySurvey CPS ON CPS.PartyID = CP.PartyID



