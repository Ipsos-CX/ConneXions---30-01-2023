
CREATE TABLE [Stage].LandRover_Brazil_Sales
(
	[ID]				[int] IDENTITY(1,1) NOT NULL,
	[AuditID]			[bigint] NULL,
    [PhysicalRowID]     INT NULL,
	[CustomerID]		[dbo].[LoadText] NULL,
	[Title]				[dbo].[LoadText] NULL,
	[Forename]			[dbo].[LoadText] NULL,
	[Surname]			[dbo].[LoadText] NULL,
	[CompanyName]		[dbo].[LoadText] NULL,
	[Address1]			[dbo].[LoadText] NULL,
	[Address2]			[dbo].[LoadText] NULL,
	[Town]				[dbo].[LoadText] NULL,
	[State]				[dbo].[LoadText] NULL,
	[PostCode]			[dbo].[LoadText] NULL,
	[Country]			[dbo].[LoadText] NULL,
	[Email]				[dbo].[LoadText] NULL,
	[MobileTelephone]	[dbo].[LoadText] NULL,
	[HomeTelephone]		[dbo].[LoadText] NULL,
	[WorkTelephone]		[dbo].[LoadText] NULL,
	[VIN]				[dbo].[LoadText] NULL,
	[DealerCode]		[dbo].[LoadText] NULL,
	[EmailOptIn]		[dbo].[LoadText] NULL,
	[TelephoneOptIn]	[dbo].[LoadText] NULL,
	[MobileOptIn]		[dbo].[LoadText] NULL,
	[DateOfBirth]		[dbo].[LoadText] NULL,
	[SaleDate]			[dbo].[LoadText] NULL,
	[ConvertedDateOfBirth]		[datetime2] NULL,
	[ConvertedSaleDate]			[datetime2] NULL
) ON [PRIMARY]

GO


