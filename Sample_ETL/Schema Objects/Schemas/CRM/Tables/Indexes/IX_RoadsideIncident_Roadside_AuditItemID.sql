CREATE INDEX [IX_RoadsideIncident_Roadside_AuditItemID]
	ON [CRM].[RoadsideIncident_Roadside] ([AuditItemID]) 
	INCLUDE ([ACCT_ACCT_ID], [ACCT_ACCT_TYPE], [CAMPAIGN_CAMPAIGN_ID], [RESPONSE_ID])
