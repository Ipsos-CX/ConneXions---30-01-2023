ALTER TABLE [RollbackSample].[ContactPreferencesBySurvey]
	ADD CONSTRAINT [PK_RollbackSample_ContactPreferencesBySurvey]
	PRIMARY KEY (AuditID, PartyID, EventCategoryID)