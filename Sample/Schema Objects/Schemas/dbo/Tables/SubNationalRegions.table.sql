CREATE TABLE dbo.SubNationalRegions
	(
		SubNationalRegionID				[int] IDENTITY(1,1) NOT NULL,
		SubNationalRegion				[nvarchar](255) NOT NULL,
		MarketID						INT NOT NULL,
		SubNationalTerritoryID			INT NOT NULL
	)