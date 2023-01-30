CREATE NONCLUSTERED INDEX [IX_Franchise_Country_Type] ON [DealerManagement].[Franchises_Load]
(
	[FranchiseCountry] ASC,
	[FranchiseType] ASC
)
INCLUDE ( 	[JLRNumber],
	[10CharacterCode]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
