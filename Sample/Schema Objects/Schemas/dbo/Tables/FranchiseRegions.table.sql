CREATE TABLE [dbo].[FranchiseRegions]
(
	[FranchiseRegionID]		[INT] IDENTITY(1,1) NOT NULL,
	[FranchiseRegion]		[NVARCHAR](255) NOT NULL,
	[FranchiseRegionNumber]	[NVARCHAR](20) NOT NULL, 
    [CountryID]				[INT] NOT NULL,
)
