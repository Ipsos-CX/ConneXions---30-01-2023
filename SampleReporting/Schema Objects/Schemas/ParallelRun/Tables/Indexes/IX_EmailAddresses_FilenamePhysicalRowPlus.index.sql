CREATE INDEX [IX_EmailAddresses_FilenamePhysicalRowPlus]
    ON [ParallelRun].[EmailAddresses]
	([FileName], PhysicalFileRow)
	INCLUDE(AuditItemID)





