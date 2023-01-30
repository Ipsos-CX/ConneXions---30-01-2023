CREATE INDEX [IX_PostalAddress_FilenamePhysicalRowPlus]
    ON [ParallelRun].[PostalAddress]
	([FileName], PhysicalFileRow)
	INCLUDE(AuditItemID)





