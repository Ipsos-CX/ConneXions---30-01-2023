CREATE NONCLUSTERED INDEX [IX_DMS_Repair_Service_AuditID_PhysicalRowID] 
	ON [CRM].[DMS_Repair_Service] ([AuditID], [PhysicalRowID]) 
	INCLUDE ([AuditItemID])
