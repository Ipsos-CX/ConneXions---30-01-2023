CREATE NONCLUSTERED INDEX [IX_Vista_Contract_Sales_AuditID] 
	ON [CRM].[Vista_Contract_Sales] ([AuditID])
	INCLUDE ([ID],[AuditItemID],[item_Id])
