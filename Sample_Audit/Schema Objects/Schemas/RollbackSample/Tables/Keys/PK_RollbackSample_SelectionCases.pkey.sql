ALTER TABLE [RollbackSample].[SelectionCases]
	ADD CONSTRAINT [PK_RollbackSample_SelectionCases]
	PRIMARY KEY (AuditID, CaseID, RequirementIDPartOf)