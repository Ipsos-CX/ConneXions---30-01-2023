CREATE NONCLUSTERED INDEX [IX_OnlineOutput_etype]
	ON [SelectionOutput].[OnlineOutput] ([etype])
	INCLUDE ([ID],[VIN],[blank],[ITYPE],[Market],[DealerCode])
