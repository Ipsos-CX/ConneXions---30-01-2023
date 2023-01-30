
CREATE TABLE [Stage].[LandRover_Japan_Service]
(
	[ID]						[int] IDENTITY(1,1) NOT NULL,
	[AuditID]					[dbo].[AuditID] NULL,
	[PhysicalRowID]				[int] NULL,
	[ServiceDealerCode]			[dbo].[LoadText] NULL,
	[ServiceEventDate]			[dbo].[LoadText] NULL,
	[RegistrationNumber]		[dbo].[LoadText] NULL,
	[VIN]						[dbo].[LoadText] NULL,
	[CompanyName]				[dbo].[LoadText] NULL,
	[CustomerSurname]			[dbo].[LoadText] NULL,
	[CustomerFirstname]			[dbo].[LoadText] NULL,
	[Title]						[dbo].[LoadText] NULL,
	[TelephoneUnknown]			[dbo].[LoadText] NULL,
	[PostCode]					[dbo].[LoadText] NULL,
	[Address1]					[dbo].[LoadText] NULL,
	[Address2]					[dbo].[LoadText] NULL,
	[EmailAddress]				[dbo].[LoadText] NULL,
	[ConvertedServiceEventDate] [datetime2](7) NULL,
	[Mobile_Number] dbo.LoadText NULL -- BUG 15373 
)
