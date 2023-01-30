CREATE NONCLUSTERED INDEX [IX_GeneralEnquiryEvents_AuditItemID_CaseNumber]
ON [GeneralEnquiry].[GeneralEnquiryEvents] ([AuditItemID])
	INCLUDE ([CaseNumber])
GO
