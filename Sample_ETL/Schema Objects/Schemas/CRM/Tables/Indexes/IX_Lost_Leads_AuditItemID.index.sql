CREATE NONCLUSTERED INDEX [IX_Lost_Leads_AuditItemID] 
	ON [CRM].[Lost_Leads] ([AuditItemID]) 
INCLUDE ([LEAD_LEAD_ID])
