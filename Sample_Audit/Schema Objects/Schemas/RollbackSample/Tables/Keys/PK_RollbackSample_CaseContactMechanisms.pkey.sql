ALTER TABLE [RollbackSample].[CaseContactMechanisms]
	ADD CONSTRAINT [PK_RollbackSample_CaseContactMechanisms]
	PRIMARY KEY ([CaseID] ASC, [ContactMechanismTypeID] ASC, [ContactMechanismID] ASC)