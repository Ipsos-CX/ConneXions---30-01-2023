ALTER TABLE [DealerManagement].[RoleTypes]
	ADD CONSTRAINT [FK_RoleTypes] 
	FOREIGN KEY (RoleTypeID)
	REFERENCES dbo.RoleTypes (RoleTypeID)	

