CREATE NONCLUSTERED INDEX [IX_Franchises_Load_IP_Country]
	ON [DealerManagement].[Franchises_Load] ([IP_CountryID])
	INCLUDE ([IP_ID],[Brand],[FranchiseType])
