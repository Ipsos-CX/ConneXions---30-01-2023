CREATE INDEX [IX_Lost_Leads_AuditID]
	ON [CRM].[Lost_Leads] ([AuditID])
	INCLUDE ([ID],[AuditItemID],[item_Id])
