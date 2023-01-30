ALTER TABLE [Audit].[CustomerUpdate_CRCAgentsGlobalList] 
	ADD CONSTRAINT [DF_CustomerUpdate_CRCAgentsGlobalList_DateProcessed]
	DEFAULT (Getdate())
	FOR [DateProcessed]
