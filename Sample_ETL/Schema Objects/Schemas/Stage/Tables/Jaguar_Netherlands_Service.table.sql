
CREATE TABLE [Stage].[Jaguar_Netherlands_Service]
(
	[ID]						[int] IDENTITY(1,1) NOT NULL,
	[AuditID]					[dbo].[AuditID] NULL,
	[PhysicalRowID]				[int] NULL,
	[Title]						[dbo].[LoadText] NULL,
	[Initial]					[dbo].[LoadText] NULL,
	[Surname]					[dbo].[LoadText] NULL,
	[Company]					[dbo].[LoadText] NULL,
	[Address]					[dbo].[LoadText] NULL,
	[Postcode]					[dbo].[LoadText] NULL,
	[Town]						[dbo].[LoadText] NULL,
	[Model]						[dbo].[LoadText] NULL,
	[VIN]						[dbo].[LoadText] NULL,
	[Registration]				[dbo].[LoadText] NULL,
	[SalesDate]					[dbo].[LoadText] NULL,
	[DealerDode]				[dbo].[LoadText] NULL,
	[ServiceDate]				[dbo].[LoadText] NULL,
	[EmailAddress]				[dbo].[LoadText] NULL,
	[ConvertedServiceDate]		[datetime2](7) NULL,
	[ConvertedSalesDate]		[datetime2](7) NULL,
)