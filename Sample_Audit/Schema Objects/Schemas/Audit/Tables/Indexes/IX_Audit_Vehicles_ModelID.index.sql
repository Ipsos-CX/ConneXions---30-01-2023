CREATE NONCLUSTERED INDEX [IX_Audit_Vehicles_ModelID] 
	ON [Audit].[Vehicles] ([ModelID]) 
	INCLUDE ([AuditItemID], [VIN], [ModelDescription])
