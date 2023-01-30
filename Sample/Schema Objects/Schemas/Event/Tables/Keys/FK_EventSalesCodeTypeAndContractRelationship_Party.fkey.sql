ALTER TABLE [Event].[EventSalesCodeTypeAndContractRelationship]
	ADD CONSTRAINT [FK_EventSalesCodeTypeAndContractRelationship_Party] 
	FOREIGN KEY ([PartyID])
	REFERENCES [Party].[Parties] ([PartyID])	
	ON DELETE NO ACTION ON UPDATE NO ACTION;
