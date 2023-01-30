CREATE INDEX [IX_General_Enquiry_AuditItemID]
	ON [CRM].[General_Enquiry] ([AuditItemID]) 
	INCLUDE ([ACCT_ACCT_ID], [ACCT_ACCT_TYPE], [CAMPAIGN_CAMPAIGN_ID], [RESPONSE_ID])
