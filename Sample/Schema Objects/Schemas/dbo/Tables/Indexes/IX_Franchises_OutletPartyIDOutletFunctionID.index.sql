CREATE INDEX [IX_Franchises_OutletPartyIDOutletFunctionID]
	ON [dbo].[Franchises]
	([OutletPartyID] ASC, [OutletFunctionID] ASC)
    INCLUDE([FranchiseTradingTitle], [FranchiseCICode], [OutletFunction], [FranchiseCountry], [ManufacturerPartyID])
