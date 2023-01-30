ALTER TABLE [SampleReport].[IndividualRows] 
	ADD  CONSTRAINT [df_SampleReport_IndividualRows_InvalidAFRLCode]  
	DEFAULT ((0)) 
	FOR [InvalidAFRLCode]



