ALTER TABLE [Event].[EventSalesCodeTypeAndContractRelationship]
	ADD CONSTRAINT [FK_EventSalesCodeTypeAndContractRelationship_SalesCodeType] 
	FOREIGN KEY ([SalesCodeTypeId])
	REFERENCES [Event].[SalesCodeTypes] ([SalesCodeTypeId])	
	ON DELETE NO ACTION ON UPDATE NO ACTION;
