  
ALTER TABLE [SampleReport].[Base] 
   ADD  CONSTRAINT [df_SampleReport_Base_DealerExclusionListMatch]  
   DEFAULT ((0)) 
   FOR [DealerExclusionListMatch]



