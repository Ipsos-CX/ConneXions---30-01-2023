ALTER TABLE [Event].[AutomotiveEventBasedInterviews]
	ADD CONSTRAINT [FK_AutomotiveEventBasedInterviews_Parties] 
	FOREIGN KEY (PartyID)
	REFERENCES Party.Parties (PartyID)	

