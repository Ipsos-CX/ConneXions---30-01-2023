ALTER TABLE [OWAP].[SubMenuItems]
	ADD CONSTRAINT [FK_SubMenuItem_MenuItem] 
	FOREIGN KEY (MenuItemID)
	REFERENCES OWAP.MenuItems (MenuItemID)	
