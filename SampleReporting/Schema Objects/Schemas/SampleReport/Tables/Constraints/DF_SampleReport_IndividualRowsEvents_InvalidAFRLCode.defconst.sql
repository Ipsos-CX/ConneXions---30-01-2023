ALTER TABLE [SampleReport].[IndividualRowsEvents] 
	ADD  CONSTRAINT [df_SampleReport_IndividualRowsEvents_InvalidAFRLCode]  
	DEFAULT ((0)) 
	FOR [InvalidAFRLCode]

