CREATE INDEX [IX_Comparisons_SampleQualityAndSelectionLogging_FilenamePhysicalRowPlus]
    ON [ParallelRun].[Comparisons_SampleQualityAndSelectionLogging]
	([FileName], PhysicalFileRow)
	INCLUDE(RemoteAuditID, RemoteAuditItemID, LocalAuditID, LocalAuditItemID)
