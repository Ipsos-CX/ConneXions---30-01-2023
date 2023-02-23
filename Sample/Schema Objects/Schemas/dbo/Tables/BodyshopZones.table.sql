CREATE TABLE [dbo].[BodyshopZones]
(
	BodyshopZoneID		[INT] IDENTITY(1,1) NOT NULL,
	BodyshopZone		[NVARCHAR](255) NOT NULL,
	BodyshopZoneCode	[NVARCHAR](20) NOT NULL,
	CountryID			[INT] NOT NULL, 
    SubNationalRegion	[NVARCHAR](25) NULL
)