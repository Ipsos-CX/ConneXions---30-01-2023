ALTER TABLE [RollbackSample].[CaseContactMechanismOutcomes]
	ADD CONSTRAINT [PK_RollbackSample_CaseContactMechanismOutcomes]
	PRIMARY KEY ([CaseID] ASC, [OutcomeCode] ASC, [OutcomeCodeTypeID] ASC, [ContactMechanismID] ASC, [ActionDate] ASC)