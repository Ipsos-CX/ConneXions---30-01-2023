ALTER TABLE [OWAP].[RoleTypes]
	ADD CONSTRAINT [FK_RoleTypes_RoleTypes] 
	FOREIGN KEY (RoleTypeID)
	REFERENCES dbo.RoleTypes (RoleTypeID)	

