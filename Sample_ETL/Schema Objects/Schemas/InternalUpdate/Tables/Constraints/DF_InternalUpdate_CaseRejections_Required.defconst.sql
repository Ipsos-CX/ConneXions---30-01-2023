ALTER TABLE [InternalUpdate].[CaseRejections] 
	ADD  CONSTRAINT [DF_InternalUpdate_CaseRejections_Required]  
	DEFAULT ((0)) 
	FOR [Required]


