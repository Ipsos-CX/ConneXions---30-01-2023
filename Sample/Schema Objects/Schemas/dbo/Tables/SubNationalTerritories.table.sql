CREATE TABLE dbo.SubNationalTerritories
	(
		SubNationalTerritoryID			[int] IDENTITY(1,1) NOT NULL,
		SubNationalTerritory			[nvarchar](255) NOT NULL,
		MarketID						INT NOT NULL
	)