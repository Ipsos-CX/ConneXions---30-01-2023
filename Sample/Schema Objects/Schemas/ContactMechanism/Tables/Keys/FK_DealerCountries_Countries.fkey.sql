ALTER TABLE [ContactMechanism].[DealerCountries]
	ADD CONSTRAINT [FK_DealerCountries_Countries] 
	FOREIGN KEY (CountryID)
	REFERENCES ContactMechanism.Countries (CountryID)	

