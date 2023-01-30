CREATE TABLE RollbackSample.Audit_ContactPreferences
(
	AuditID					dbo.AuditID	NOT NULL,
 
    AuditItemID             dbo.AuditItemID        NOT NULL,
	PartyID					dbo.PartyID NOT NULL,

	OriginalPartySuppression	BIT NULL,
	OriginalPostalSuppression	BIT NULL,
	OriginalEmailSuppression	BIT NULL,
	OriginalPhoneSuppression	BIT NULL,
	OriginalPartyUnsubscribe	BIT NULL,

	SuppliedPartySuppression	BIT NULL,
	SuppliedPostalSuppression	BIT NULL,
	SuppliedEmailSuppression	BIT NULL,
	SuppliedPhoneSuppression	BIT NULL,
	SuppliedPartyUnsubscribe	BIT NULL,

	PartySuppression			BIT NULL,
	PostalSuppression			BIT NULL,
	EmailSuppression			BIT NULL,
	PhoneSuppression			BIT NULL,
	PartyUnsubscribe			BIT NULL,

	UpdateDate					DATETIME2 NOT NULL,
	UpdateSource				VARCHAR(50) NOT NULL,
	
	ContactPreferencesPersist	BIT NOT NULL,
	EventCategoryPersistOveride BIT NULL,
	
	OverridePreferences			BIT NULL,
	RemoveUnsubscribe			BIT NULL,
	RollbackIndicator			BIT NULL,
	Comments					VARCHAR(255) NULL
  );

	
	
	