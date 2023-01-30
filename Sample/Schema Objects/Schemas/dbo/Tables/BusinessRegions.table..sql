CREATE TABLE [dbo].[BusinessRegions]
(
	BusinessRegionID	[INT] IDENTITY(1,1) NOT NULL,
	BusinessRegion		[NVARCHAR](150) NOT NULL, 
    BusinessRegionIpsos [NVARCHAR](150) NULL,
	CountryID           [int] NULL --TASK 647
)
