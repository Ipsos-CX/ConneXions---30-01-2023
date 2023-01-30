ALTER TABLE [Audit].[InternalUpdate_NonSolicitations] 
	ADD  CONSTRAINT [DF_InternalUpdate_NonSolicitations_DateProcessed]  
	DEFAULT (getdate()) 
	FOR [DateProcessed]


