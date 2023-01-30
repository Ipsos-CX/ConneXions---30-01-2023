ALTER TABLE [RollbackSample].[CustomerRelationships]
	ADD CONSTRAINT [PK_RollbackSample_CustomerRelationships]
	PRIMARY KEY (AuditID		,
				[PartyIDFrom]    ,  
				[PartyIDTo]       , 
				[RoleTypeIDFrom]   ,
				[RoleTypeIDTo]     )