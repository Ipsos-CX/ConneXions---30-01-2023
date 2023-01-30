ALTER TABLE [RollbackSample].[PartyContactMechanisms]
	ADD CONSTRAINT [PK_RollbackSample_PartyContactMechanisms]
	PRIMARY KEY (AuditID, [ContactMechanismID]           ,
							[PartyID]    )     