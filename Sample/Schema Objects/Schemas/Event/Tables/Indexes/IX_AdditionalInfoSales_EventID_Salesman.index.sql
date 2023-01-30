CREATE NONCLUSTERED INDEX [IX_AdditionalInfoSales_EventID_Salesman] 
	ON [Event].[AdditionalInfoSales] ([EventID]) 
	INCLUDE ([Salesman])
