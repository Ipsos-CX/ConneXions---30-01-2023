CREATE NONCLUSTERED INDEX [IX_YearlyEchoHistory_RecordChanged]
    ON [SampleReport].[YearlyEchoHistory]([RecordChanged] ASC, [ReportDate] ASC)
    INCLUDE([AuditItemID]);
GO