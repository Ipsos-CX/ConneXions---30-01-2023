CREATE INDEX [IX_SampleQualityAndSelectionLogging_EventIDPlus]
    ON [dbo].[SampleQualityAndSelectionLogging]
	(MatchedODSEventID)
	INCLUDE(AuditID, AuditItemID, CaseID, LoadedDate)


