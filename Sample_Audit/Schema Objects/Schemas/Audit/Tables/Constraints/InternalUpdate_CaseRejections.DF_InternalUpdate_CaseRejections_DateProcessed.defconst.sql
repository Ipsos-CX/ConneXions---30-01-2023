ALTER TABLE [Audit].[InternalUpdate_CaseRejections] 
	ADD  CONSTRAINT [DF_InternalUpdate_CaseRejections_DateProcessed]  
	DEFAULT (getdate()) 
	FOR [DateProcessed]
