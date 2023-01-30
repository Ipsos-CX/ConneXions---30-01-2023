ALTER TABLE [SampleReceipt].[EmailReportOutputs]
    ADD CONSTRAINT [FK_EmailReportOutputs_ReportOutputs] FOREIGN KEY (ReportOutputID) 
    REFERENCES SampleReceipt.ReportOutputs (ReportOutputID);
