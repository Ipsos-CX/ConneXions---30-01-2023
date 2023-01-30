ALTER TABLE [SampleReport].[IndividualRowsEvents] 
	ADD  CONSTRAINT [df_SampleReport_IndividualRowsEvents_DealerExclusionListMatch]  
	DEFAULT ((0)) 
	FOR [DealerExclusionListMatch]


