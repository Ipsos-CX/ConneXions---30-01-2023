ALTER TABLE [OWAP].[Users]
	ADD CONSTRAINT [FK_Users_PartyRoles] 
	FOREIGN KEY (PartyID, RoleTypeID)
	REFERENCES Party.PartyRoles (PartyID, RoleTypeID)	

