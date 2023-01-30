CREATE TABLE RollbackSample.ContactPreferencesBySurvey
(
	AuditID					dbo.AuditID	NOT NULL,
 
	PartyID					dbo.PartyID NOT NULL,
	EventCategoryID			INT  NOT NULL,
	
	PartySuppression		BIT NULL,
	PostalSuppression		BIT NULL,
	EmailSuppression		BIT NULL,
	PhoneSuppression		BIT NULL,
	
	UpdateDate				DATETIME2 NOT NULL
  );

