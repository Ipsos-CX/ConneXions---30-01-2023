ALTER TABLE [OWAP].[MenuItemRoles]
	ADD CONSTRAINT [FK_MenuItemRoles_MenuItems] 
	FOREIGN KEY (MenuItemID)
	REFERENCES OWAP.MenuItems (MenuItemID)	

