ALTER TABLE [InternalUpdate].[NonSolicitations] 
	ADD  CONSTRAINT [DF_InternalUpdate_NonSolicitations_ExistsAlready]  
	DEFAULT 0 
	FOR [ExistsAlready]