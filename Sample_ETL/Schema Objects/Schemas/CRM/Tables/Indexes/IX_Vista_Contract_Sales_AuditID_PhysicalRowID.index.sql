CREATE NONCLUSTERED INDEX [IX_Vista_Contract_Sales_AuditID_PhysicalRowID] 
	ON [CRM].[Vista_Contract_Sales] ([AuditID], [PhysicalRowID]) 
	INCLUDE ([AuditItemID])
