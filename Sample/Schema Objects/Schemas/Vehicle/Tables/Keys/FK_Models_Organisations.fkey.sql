ALTER TABLE [Vehicle].[Models]
	ADD CONSTRAINT [FK_Models_Organisations] 
	FOREIGN KEY (ManufacturerPartyID)
	REFERENCES Party.Organisations (PartyID)	

