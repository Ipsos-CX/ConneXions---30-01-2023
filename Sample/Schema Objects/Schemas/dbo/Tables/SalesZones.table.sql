CREATE TABLE [dbo].[SalesZones]
(
	SalesZoneID				[INT] IDENTITY(1,1) NOT NULL,
	SalesZone				[NVARCHAR](255) NOT NULL,
	SalesZoneCode			[NVARCHAR](20) NOT NULL,
	CountryID				[INT] NOT NULL, 
    SubNationalRegion		[NVARCHAR](255) NULL
)
