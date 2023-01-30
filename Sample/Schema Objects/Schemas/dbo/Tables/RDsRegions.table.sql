CREATE TABLE [dbo].[RDsRegions]
(
	RDsRegionID			[INT] IDENTITY(1,1) NOT NULL,
	RDsRegion			[NVARCHAR](150) NOT NULL,
	SuperNationalRegion	[NVARCHAR](150) NULL,
	CountryID           [int] NULL --TASK 647
)
