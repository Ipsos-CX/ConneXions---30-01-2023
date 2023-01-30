CREATE TABLE [Party].[ContactPreferencesBySurvey]
(
	PartyID					dbo.PartyID NOT NULL,
	EventCategoryID			dbo.EventCategoryID  NOT NULL,
	
	PartySuppression		BIT NULL,
	PostalSuppression		BIT NULL,
	EmailSuppression		BIT NULL,
	PhoneSuppression		BIT NULL,
	
	UpdateDate				DATETIME2 NOT NULL
	
);