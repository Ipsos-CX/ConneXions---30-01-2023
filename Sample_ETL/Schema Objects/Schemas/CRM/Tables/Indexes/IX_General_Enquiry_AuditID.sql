CREATE INDEX [IX_General_Enquiry_AuditID]
	ON [CRM].[General_Enquiry] ([AuditID])
	INCLUDE ([ID],[AuditItemID],[item_Id])
