CREATE INDEX [IX_SelectionOutputsStaging_AuditID] 
	ON [NWB].[SelectionOutputsStaging] ([AuditID]) 
	INCLUDE ([AuditItemID], [PhysicalRowID])