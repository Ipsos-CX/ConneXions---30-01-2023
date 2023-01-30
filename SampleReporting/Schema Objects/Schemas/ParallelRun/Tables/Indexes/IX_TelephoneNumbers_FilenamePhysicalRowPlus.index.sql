CREATE INDEX [IX_TelephoneNumbers_FilenamePhysicalRowPlus]
    ON [ParallelRun].[TelephoneNumbers]
	([FileName], PhysicalFileRow)
	INCLUDE(AuditItemID)





