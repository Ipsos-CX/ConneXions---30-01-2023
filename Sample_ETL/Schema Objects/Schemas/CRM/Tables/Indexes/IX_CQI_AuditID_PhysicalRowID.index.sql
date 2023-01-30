CREATE NONCLUSTERED INDEX [IX_CQI_AuditID_PhysicalRowID] 
	ON [CRM].[CQI] ([AuditID], [PhysicalRowID]) 
	INCLUDE ([AuditItemID])
