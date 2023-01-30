CREATE NONCLUSTERED INDEX [IX_Lost_Leads_DateTransferredToVWT]
	ON [CRM].[Lost_Leads] ([DateTransferredToVWT])
	INCLUDE ([ID],[ACCT_ACCT_TYPE])
GO
