ALTER TABLE [OWAP].[MenuItemRoles]
	ADD CONSTRAINT [FK_MenuItemRoles_RoleTypes] 
	FOREIGN KEY (RoleTypeID)
	REFERENCES OWAP.RoleTypes (RoleTypeID)	

