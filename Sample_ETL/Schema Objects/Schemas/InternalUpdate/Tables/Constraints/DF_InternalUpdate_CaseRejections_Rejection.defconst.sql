ALTER TABLE [InternalUpdate].[CaseRejections] 
	ADD  CONSTRAINT [DF_InternalUpdate_CaseRejections_Rejection]  
	DEFAULT ((1)) 
	FOR [Rejection]



