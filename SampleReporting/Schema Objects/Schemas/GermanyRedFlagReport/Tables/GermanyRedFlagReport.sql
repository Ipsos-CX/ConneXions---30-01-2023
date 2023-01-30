CREATE TABLE [GermanyRedFlagReport].[GermanyRedFlagReport]
(
	[Report Week] INT NULL,
	[Report Order] INT NULL,
	[Market] NVARCHAR(255) NULL,
	[Region] NVARCHAR(255) NULL,
	[Dealer] NVARCHAR(255) NULL,
	[Retailer] NVARCHAR(255) NULL,
	[Brand] NVARCHAR(255) NULL,
	[BrandID] INT NULL,
	[Report Date] NVARCHAR(255) NULL,
	[Send Date] NVARCHAR(255) NULL,
	[Count of red flags] NVARCHAR(255) NULL,
	[Count of red flags closed within 72 hours] NVARCHAR(255) NULL,
	[% of red flags closed within within 72 hours] NVARCHAR(255) NULL,
	[Count of sent emails] NVARCHAR(255) NULL,
	[Count of successfully delivered emails] NVARCHAR(255) NULL,
	[Count of responses] NVARCHAR(255) NULL,
	[Response rate %] NVARCHAR(255) NULL
)
