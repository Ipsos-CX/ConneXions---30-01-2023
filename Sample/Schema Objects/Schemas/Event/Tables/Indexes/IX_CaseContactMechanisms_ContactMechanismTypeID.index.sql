CREATE NONCLUSTERED INDEX [IX_CaseContactMechanisms_ContactMechanismTypeID] 
	ON [Event].[CaseContactMechanisms] ([ContactMechanismTypeID]) 
	INCLUDE ([CaseID], [ContactMechanismID])
