CREATE NONCLUSTERED INDEX [IX_GeneralEnquiryEvents_ODSEventID] 
	ON [GeneralEnquiry].[GeneralEnquiryEvents] ([ODSEventID]) 
	INCLUDE ([AuditItemID])