ALTER TABLE [dbo].[Markets]
	ADD CONSTRAINT [FK_Markets_Countries] 
	FOREIGN KEY (CountryID)
	REFERENCES ContactMechanism.Countries (CountryID)	

