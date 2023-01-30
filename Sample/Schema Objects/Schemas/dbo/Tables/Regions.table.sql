CREATE TABLE dbo.Regions
	(
		RegionID				[int] IDENTITY(1,1) NOT NULL,
		Region					[nvarchar](255) NOT NULL,
		RegionDescription		[varchar] (500) NULL,
		SuperNationalRegionID	INT NULL,
		RegionShortName			[NVARCHAR](10) NULL
	)