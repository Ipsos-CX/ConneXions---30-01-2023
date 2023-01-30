ALTER TABLE [InternalUpdate].[NonSolicitations] 
	ADD  CONSTRAINT [DF_InternalUpdate_NonSolicitations_PartyValid]  
	DEFAULT 0 
	FOR [PartyValid]

