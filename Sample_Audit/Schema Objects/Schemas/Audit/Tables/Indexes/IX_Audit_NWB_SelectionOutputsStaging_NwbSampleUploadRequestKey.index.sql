CREATE NONCLUSTERED INDEX [IX_Audit_NWB_SelectionOutputsStaging_NwbSampleUploadRequestKey] 
	ON [Audit].[NWB_SelectionOutputsStaging] ([NwbSampleUploadRequestKey]) 
	INCLUDE ([AuditID])
