﻿ALTER TABLE [OWAP].[Users]
	ADD CONSTRAINT [FK_Users_RoleTypes] 
	FOREIGN KEY (RoleTypeID)
	REFERENCES OWAP.RoleTypes (RoleTypeID)	

