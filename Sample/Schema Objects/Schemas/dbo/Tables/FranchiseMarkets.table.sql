CREATE TABLE [dbo].[FranchiseMarkets]
(
	FranchiseMarketID		[INT] IDENTITY(1,1) NOT NULL,
	FranchiseMarket			[NVARCHAR](255) NOT NULL,
	FranchiseMarketNumber	[NVARCHAR](20) NOT NULL,
	FranchiseRegionID		[INT] NOT NULL,
	CountryID				[INT] NOT NULL
)
