ALTER TABLE [OWAP].[Users]
	ADD CONSTRAINT [FK_Users_People] 
	FOREIGN KEY (PartyID)
	REFERENCES Party.People (PartyID)	

