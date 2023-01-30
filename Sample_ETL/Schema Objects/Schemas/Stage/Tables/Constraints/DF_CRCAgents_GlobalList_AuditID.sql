ALTER TABLE [Stage].[CRCAgents_GlobalList]
	ADD CONSTRAINT [DF_CRCAgents_GlobalList_AuditID]
	DEFAULT 0
	FOR [AuditID]
