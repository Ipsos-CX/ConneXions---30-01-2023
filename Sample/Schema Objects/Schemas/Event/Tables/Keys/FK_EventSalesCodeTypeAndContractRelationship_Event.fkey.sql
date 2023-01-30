ALTER TABLE [Event].[EventSalesCodeTypeAndContractRelationship]
	ADD CONSTRAINT [FK_EventSalesCodeTypeAndContractRelationship_Event] 
	FOREIGN KEY ([EventId])
	REFERENCES [Event].[Events] ([EventId])	
	ON DELETE NO ACTION ON UPDATE NO ACTION;
