CREATE NONCLUSTERED INDEX [IX_DW_JLRCSPDealers_OutletPartyIDOutletFunctionID]
    ON [dbo].[DW_JLRCSPDealers]([OutletPartyID] ASC, [OutletFunctionID] ASC)
    INCLUDE([Outlet], [OutletCode], [OutletFunction], [Market], [ManufacturerPartyID]) WITH (ALLOW_PAGE_LOCKS = ON, ALLOW_ROW_LOCKS = ON, PAD_INDEX = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ONLINE = OFF, MAXDOP = 0);

