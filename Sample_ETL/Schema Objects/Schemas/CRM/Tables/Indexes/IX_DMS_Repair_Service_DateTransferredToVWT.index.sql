CREATE NONCLUSTERED INDEX [IX_DMS_Repair_Service_DateTransferredToVWT] 
	ON [CRM].[DMS_Repair_Service] ([DateTransferredToVWT]) 
	INCLUDE ([ID], [ACCT_ACCT_TYPE], [DMS_VIN], [CNT_LAST_NAME])
