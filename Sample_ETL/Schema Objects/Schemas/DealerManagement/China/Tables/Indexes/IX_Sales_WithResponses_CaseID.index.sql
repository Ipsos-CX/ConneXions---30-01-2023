CREATE NONCLUSTERED INDEX [IX_Sales_WithResponses_CaseID]
    ON [China].[Sales_WithResponses]([CaseID] ASC)
    INCLUDE([AuditItemID]) WITH (ALLOW_PAGE_LOCKS = ON, ALLOW_ROW_LOCKS = ON, PAD_INDEX = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ONLINE = OFF, MAXDOP = 0);

