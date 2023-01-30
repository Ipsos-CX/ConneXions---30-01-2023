ALTER TABLE [dbo].[Markets]
	ADD CONSTRAINT [FK_Markets_PartyMatchingMethodologies] 
	FOREIGN KEY (PartyMatchingMethodologyID)
	REFERENCES dbo.PartyMatchingMethodologies (ID)	

