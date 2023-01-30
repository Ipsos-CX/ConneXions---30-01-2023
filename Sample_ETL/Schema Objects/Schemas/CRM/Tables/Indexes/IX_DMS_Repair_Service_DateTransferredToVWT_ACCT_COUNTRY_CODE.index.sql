CREATE NONCLUSTERED INDEX [IX_DMS_Repair_Service_DateTransferredToVWT_ACCT_COUNTRY_CODE]
	ON [CRM].[DMS_Repair_Service] ([DateTransferredToVWT],[ACCT_COUNTRY_CODE])
	INCLUDE ([AuditID],[AuditItemID],[item_Id])
