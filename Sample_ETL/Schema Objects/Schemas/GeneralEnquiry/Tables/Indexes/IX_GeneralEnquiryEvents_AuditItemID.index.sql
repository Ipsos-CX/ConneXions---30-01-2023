CREATE NONCLUSTERED INDEX [IX_GeneralEnquiryEvents_AuditItemID]
    ON [GeneralEnquiry].[GeneralEnquiryEvents](AuditItemID ASC)
  INCLUDE (ODSEventID)