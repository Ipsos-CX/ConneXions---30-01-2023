ALTER TABLE [SampleReport].[IndividualRowsEvents] 
	ADD  CONSTRAINT [df_SampleReport_IndividualRowsEvents_PhoneSuppression]  
	DEFAULT ((0)) 
	FOR [PhoneSuppression]

