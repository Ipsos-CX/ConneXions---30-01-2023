ALTER TABLE [SampleReport].[Base] 
	ADD  CONSTRAINT [df_SampleReport_BasePreviousEventBounceBack]  
	DEFAULT (0) FOR [PreviousEventBounceBack]
