ALTER TABLE [SampleReceipt].[EmailReportOutputs]
    ADD CONSTRAINT [FK_EmailReportOutputs_EmailList] FOREIGN KEY (EmailListID) 
    REFERENCES SampleReceipt.EmailList (EmailListID);
