ALTER TABLE [Lookup].[StreetNameVariances]
	ADD CONSTRAINT [FK_StreetNameVariances_StreetNames] 
	FOREIGN KEY (StreetNameID)
	REFERENCES Lookup.StreetNames (StreetNameID)	

