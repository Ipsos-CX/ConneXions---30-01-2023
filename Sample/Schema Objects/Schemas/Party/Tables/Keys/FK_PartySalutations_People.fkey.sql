ALTER TABLE [Party].[PartySalutations] 
ADD CONSTRAINT [FK_PartySalutation_Parties]
	FOREIGN KEY([PartyID])
	REFERENCES [Party].[Parties] ([PartyID]) 
	ON UPDATE  NO ACTION  ON DELETE  NO ACTION;