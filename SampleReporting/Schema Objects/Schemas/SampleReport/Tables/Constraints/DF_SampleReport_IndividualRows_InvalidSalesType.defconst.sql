ALTER TABLE [SampleReport].[IndividualRows] 
	ADD  CONSTRAINT [df_SampleReport_IndividualRows_InvalidSalesType]  
	DEFAULT ((0)) 
	FOR [InvalidSalesType]


