CREATE NONCLUSTERED INDEX [IX_DMS_Repair_Service_AuditID]
	ON [CRM].[DMS_Repair_Service] ([AuditID])
	INCLUDE ([ID],[AuditItemID],[item_Id])