ALTER TABLE [SampleReport].[IndividualRowsEvents] 
	ADD  CONSTRAINT [df_SampleReport_IndividualRowsEvents_InvalidSalesType]  
	DEFAULT ((0)) 
	FOR [InvalidSalesType]

