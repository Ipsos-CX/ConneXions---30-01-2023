CREATE NONCLUSTERED INDEX [IX_Vista_Contract_Sales_DateTransferredToVWT] 
	ON [CRM].[Vista_Contract_Sales] ([DateTransferredToVWT]) 
	INCLUDE ([ID], [ACCT_ACCT_TYPE], [VEH_VIN], [CNT_LAST_NAME])
