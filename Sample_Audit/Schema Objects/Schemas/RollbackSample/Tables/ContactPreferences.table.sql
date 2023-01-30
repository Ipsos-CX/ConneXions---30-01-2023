CREATE TABLE RollbackSample.ContactPreferences
(
	AuditID					dbo.AuditID	NOT NULL,
 
 	PartyID					dbo.PartyID NOT NULL,
	
	PartySuppression		BIT NULL,
	PostalSuppression		BIT NULL,
	EmailSuppression		BIT NULL,
	PhoneSuppression		BIT NULL,
	
	PartyUnsubscribe		BIT NULL,
	
	UpdateDate				DATETIME2 NOT NULL
  );

