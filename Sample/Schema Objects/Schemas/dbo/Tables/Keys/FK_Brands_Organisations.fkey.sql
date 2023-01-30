ALTER TABLE [dbo].[Brands]
	ADD CONSTRAINT [FK_Brands_Organisations] 
	FOREIGN KEY (ManufacturerPartyID)
	REFERENCES [Party].Organisations (PartyID)	

