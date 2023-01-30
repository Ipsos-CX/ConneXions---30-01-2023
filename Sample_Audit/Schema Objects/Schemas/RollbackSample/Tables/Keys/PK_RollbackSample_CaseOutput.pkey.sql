ALTER TABLE [RollbackSample].[CaseOutput]
	ADD CONSTRAINT [PK_RollbackSample_CaseOutput]
	PRIMARY KEY (AuditID, CaseID, CaseOutput_AuditItemID)