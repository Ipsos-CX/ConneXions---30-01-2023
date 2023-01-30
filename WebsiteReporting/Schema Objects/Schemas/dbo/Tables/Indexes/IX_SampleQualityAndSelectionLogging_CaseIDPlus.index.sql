CREATE INDEX [IX_SampleQualityAndSelectionLogging_CaseIDPlus]
    ON [dbo].[SampleQualityAndSelectionLogging]
	(CaseID)
	INCLUDE(AuditID, AuditItemID, PhysicalFileRow, MatchedODSEventID)


