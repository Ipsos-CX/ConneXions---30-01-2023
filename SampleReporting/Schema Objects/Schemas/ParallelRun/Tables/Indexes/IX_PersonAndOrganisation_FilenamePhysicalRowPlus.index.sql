CREATE INDEX [IX_PersonAndOrganisation_FilenamePhysicalRowPlus]
    ON [ParallelRun].[PersonAndOrganisation]
	([FileName], PhysicalFileRow)
	INCLUDE(AuditItemID)





