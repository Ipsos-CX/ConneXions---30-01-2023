CREATE NONCLUSTERED INDEX [IX_AdditionalInfoSales_EventID_SalesmanPlus] 
	ON [Event].[AdditionalInfoSales] ([EventID]) 
	INCLUDE ([Salesman], [SalesmanCode], [ServiceAdvisorID], [ServiceAdvisorName], [TechnicianID], [TechnicianName], [SalesAdvisorID], [SalesAdvisorName])
