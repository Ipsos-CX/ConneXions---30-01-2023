CREATE NONCLUSTERED INDEX [IX_VWT_MatchedODSAddressID_MatchedODSPersonID_VWTID_AuditItemID]
    ON [dbo].[VWT]([MatchedODSAddressID] ASC, [MatchedODSPersonID] ASC, [VWTID] ASC, [AuditItemID] ASC)
    INCLUDE([PersonParentAuditItemID], [TitleID], [FirstName], [LastName], [SecondLastName]) WITH (ALLOW_PAGE_LOCKS = ON, ALLOW_ROW_LOCKS = ON, PAD_INDEX = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ONLINE = OFF, MAXDOP = 0);

