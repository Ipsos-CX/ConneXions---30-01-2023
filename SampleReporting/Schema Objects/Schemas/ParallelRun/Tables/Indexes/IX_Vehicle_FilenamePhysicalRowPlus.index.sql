CREATE INDEX [IX_Vehicle_FilenamePhysicalRowPlus]
    ON [ParallelRun].[Vehicle]
	([FileName], PhysicalFileRow)
	INCLUDE(AuditItemID)





