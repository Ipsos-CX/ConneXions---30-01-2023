CREATE TABLE [GermanyRedFlagReport].[GermanyRedFlagReportSourceData]
(
	[Report Order] INT NULL,
	[Market] NVARCHAR(255) NULL,
	[Region] NVARCHAR(255) NULL,
	[Dealer] NVARCHAR(255) NULL,
	[Brand] NVARCHAR(255) NULL,
	[BrandID] INT NULL,
	[Report Week] INT NULL,
	[Report Date] DATE NULL,
	[Send Date] DATE NULL,
	[Count of sent emails] INT NULL,
	[Count of successfully delivered emails] INT NULL,
	[Count of responses] INT NULL,
	[Count of red flags] INT NULL,
	[Count of red flags closed within 72 hours] INT NULL,
)
