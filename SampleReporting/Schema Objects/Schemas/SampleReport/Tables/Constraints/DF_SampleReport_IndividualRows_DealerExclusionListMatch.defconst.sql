









ALTER TABLE [SampleReport].[IndividualRows] 
	ADD  CONSTRAINT [df_SampleReport_IndividualRows_DealerExclusionListMatch]  
	DEFAULT ((0)) 
	FOR [DealerExclusionListMatch]
