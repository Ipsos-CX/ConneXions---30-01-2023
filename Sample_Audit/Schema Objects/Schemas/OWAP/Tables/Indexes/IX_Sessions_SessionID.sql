CREATE NONCLUSTERED INDEX [IX_Sessions_SessionID]
    ON [OWAP].[Sessions]([SessionID] ASC)
    INCLUDE([AuditID]);
GO