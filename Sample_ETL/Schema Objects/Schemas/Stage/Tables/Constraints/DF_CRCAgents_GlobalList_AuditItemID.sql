ALTER TABLE [Stage].[CRCAgents_GlobalList]
	ADD CONSTRAINT [DF_CRCAgents_GlobalList_AuditItemID]
	DEFAULT 0
	FOR [AuditItemID]
