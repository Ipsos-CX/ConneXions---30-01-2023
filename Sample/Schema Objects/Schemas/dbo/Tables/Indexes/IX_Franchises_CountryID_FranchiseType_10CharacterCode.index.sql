CREATE INDEX [IX_Franchises_CountryID_FranchiseType_10CharacterCode]
	ON [dbo].[Franchises]
	([CountryID],[FranchiseType],[10CharacterCode])
