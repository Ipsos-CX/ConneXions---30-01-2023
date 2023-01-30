CREATE TABLE [dbo].[AuthorisedRepairerZones]
(
	AuthorisedRepairerZoneID		[INT] IDENTITY(1,1) NOT NULL,
	AuthorisedRepairerZone			[NVARCHAR](255) NOT NULL,
	AuthorisedRepairerZoneCode		[NVARCHAR](20) NOT NULL,
	CountryID						[INT] NOT NULL, 
    SubNationalRegion				[NVARCHAR](255) NULL
)
