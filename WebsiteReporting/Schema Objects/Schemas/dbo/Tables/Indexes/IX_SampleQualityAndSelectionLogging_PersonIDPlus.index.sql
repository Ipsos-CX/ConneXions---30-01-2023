CREATE INDEX [IX_SampleQualityAndSelectionLogging_PersonIDPlus]
    ON [dbo].[SampleQualityAndSelectionLogging]
	(MatchedODSPersonID)
	INCLUDE(AuditItemID, CaseID)


