CREATE NONCLUSTERED INDEX [IX_StaticReports_ReportDate_AuditItemID]
    ON [SampleReport].[StaticReports]([MarketOrRegion] ASC)
    INCLUDE([ReportDate], [AuditItemID])


