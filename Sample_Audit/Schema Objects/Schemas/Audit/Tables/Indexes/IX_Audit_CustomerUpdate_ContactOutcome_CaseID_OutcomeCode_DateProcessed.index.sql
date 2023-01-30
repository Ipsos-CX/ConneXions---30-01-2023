CREATE NONCLUSTERED INDEX [IX_Audit_CustomerUpdate_ContactOutcome_CaseID_OutcomeCode_DateProcessed] 
	ON [Audit].[CustomerUpdate_ContactOutcome] ([CaseID], [OutcomeCode],[DateProcessed])
