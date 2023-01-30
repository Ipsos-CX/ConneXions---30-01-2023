ALTER TABLE [RollbackSample].[PartyContactMechanismPurposes]
	ADD CONSTRAINT [PK_RollbackSample_PartyContactMechanismPurposes]
	PRIMARY KEY (AuditID, [ContactMechanismID]           ,
							[PartyID]                      ,
							[ContactMechanismPurposeTypeID],
							[FromDate] )     