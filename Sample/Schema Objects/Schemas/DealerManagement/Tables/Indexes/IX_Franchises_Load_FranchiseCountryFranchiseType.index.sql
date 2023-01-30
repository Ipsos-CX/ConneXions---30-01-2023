CREATE INDEX [IX_Franchises_Load_FranchiseCountryFranchiseType]
	ON [DealerManagement].[Franchises_Load]
(
	[FranchiseCountry] ASC,
	[FranchiseType] ASC
)
INCLUDE ([JLRNumber], [10CharacterCode])