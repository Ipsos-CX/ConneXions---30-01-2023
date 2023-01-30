ALTER TABLE [Event].[EventSalesCodeTypeAndContractRelationship]
	ADD  CONSTRAINT [PK_Event.EventSalesCodeTypeAndContractRelationship] PRIMARY KEY CLUSTERED 
	(
		[EventId] ASC,
		[PartyID] ASC,
		[SalesCodeTypeId] ASC,
		[ContractRelationshipTypeID] ASC
	)	WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)