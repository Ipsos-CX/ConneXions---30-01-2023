CREATE NONCLUSTERED INDEX [IX_OnlineOutput_blank]
    ON [SelectionOutput].[OnlineOutput] ([blank])
	INCLUDE ([CTRY], [ccode])


