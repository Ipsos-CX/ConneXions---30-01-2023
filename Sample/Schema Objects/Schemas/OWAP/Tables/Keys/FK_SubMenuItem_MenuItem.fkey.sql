ALTER TABLE [OWAP].[SubMenuItems]
	ADD CONSTRAINT [FK_MenuItems_SubMenuItem] 
	FOREIGN KEY (MenuItemID)
	REFERENCES OWAP.MenuItems (MenuItemID)	
