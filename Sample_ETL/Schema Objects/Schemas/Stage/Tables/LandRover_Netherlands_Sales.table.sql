

CREATE TABLE [Stage].[LandRover_Netherlands_Sales]
(
	[ID]						[int] IDENTITY(1,1) NOT NULL,
	[AuditID]					[dbo].[AuditID] NULL,
	[PhysicalRowID]				[int] NULL,
	[DeliveryDate]				[dbo].[LoadText] NULL,
	[SalesDealerCode]			[dbo].[LoadText] NULL,
	[ModelDescription]			[dbo].[LoadText] NULL,
	[VIN]						[dbo].[LoadText] NULL,
	[RegistrationNumber]		[dbo].[LoadText] NULL,
	[Gender]					[dbo].[LoadText] NULL,
	[Initials]					[dbo].[LoadText] NULL,
	[Surname]					[dbo].[LoadText] NULL,
	[DOB]						[dbo].[LoadText] NULL,
	[CompanyName]				[dbo].[LoadText] NULL,
	[StreetHouseNo]				[dbo].[LoadText] NULL,
	[Address1]					[dbo].[LoadText] NULL,
	[Town]						[dbo].[LoadText] NULL,
	[Postcode]					[dbo].[LoadText] NULL,
	[BuyerType]					[dbo].[LoadText] NULL,
	[EmailAddress]				[dbo].[LoadText] NULL,
	[ConvertedDeliveryDate]		[datetime2](7) NULL,
	[ConvertedDOB]				[datetime2](7) NULL
)
