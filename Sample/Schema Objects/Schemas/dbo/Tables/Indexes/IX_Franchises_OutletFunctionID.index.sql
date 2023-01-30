CREATE NONCLUSTERED INDEX [IX_Franchises_OutletFunctionID]
	ON [dbo].[Franchises] ([OutletFunctionID])
	INCLUDE ([OutletPartyID],[CountryID],[10CharacterCode])