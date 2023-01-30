CREATE NONCLUSTERED INDEX [IX_Audit_CaseContactMechanismOutcomes_OutcomeCode_CasePartyCombinationValid] 
	ON [Audit].[CaseContactMechanismOutcomes] ([OutcomeCode], [CasePartyCombinationValid]) 
	INCLUDE ([PartyID], [ActionDate])
