ALTER TABLE [Party].[DealershipClassifications]
   ADD CONSTRAINT [FK_DealershipClassifications_PartyClassifications] FOREIGN KEY ([PartyTypeID], [PartyID]) 
   REFERENCES [Party].[PartyClassifications] ([PartyTypeID], [PartyID]) 
   ON DELETE NO ACTION ON UPDATE NO ACTION;

