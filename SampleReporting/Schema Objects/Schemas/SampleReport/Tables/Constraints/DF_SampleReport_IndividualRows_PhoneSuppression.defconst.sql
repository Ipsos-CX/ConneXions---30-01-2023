ALTER TABLE [SampleReport].[IndividualRows] 
	ADD  CONSTRAINT [df_SampleReport_IndividualRows_PhoneSuppression]  
	DEFAULT ((0)) 
	FOR [PhoneSuppression]


