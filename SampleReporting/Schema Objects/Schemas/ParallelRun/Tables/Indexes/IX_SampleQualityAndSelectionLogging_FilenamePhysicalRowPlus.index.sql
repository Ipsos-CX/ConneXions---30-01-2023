CREATE INDEX [IX_SampleQualityAndSelectionLogging_FilenamePhysicalRowPlus]
    ON [ParallelRun].[SampleQualityAndSelectionLogging]
	([FileName], PhysicalFileRow)
	INCLUDE(AuditID, AuditItemID, CaseID, LoadedDate)





