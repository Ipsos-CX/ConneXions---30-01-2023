ALTER TABLE [InternalUpdate].[CaseRejections] 
	ADD  CONSTRAINT [DF_InternalUpdate_CaseRejections_CasePartyCombinationValid]  
	DEFAULT ((0)) 
	FOR [CasePartyCombinationValid]

