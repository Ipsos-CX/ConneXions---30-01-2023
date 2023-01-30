CREATE NONCLUSTERED INDEX [IX_Lost_Leads_AuditID_item_Id]
	ON [CRM].[Lost_Leads] ([AuditID],[item_Id])
