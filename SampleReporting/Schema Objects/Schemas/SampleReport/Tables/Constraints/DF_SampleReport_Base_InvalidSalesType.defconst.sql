ALTER TABLE [SampleReport].[Base] 
	ADD  CONSTRAINT [df_SampleReport_Base_InvalidSalesType]  
	DEFAULT ((0)) 
	FOR [InvalidSalesType]


