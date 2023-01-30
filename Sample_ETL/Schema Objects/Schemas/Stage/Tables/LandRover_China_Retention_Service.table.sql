
CREATE TABLE [Stage].[LandRover_China_Retention_Service](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[AuditID] [dbo].[AuditID] NULL,
	[PhysicalRowID] [int] NULL,
	[Title]				[dbo].[LoadText] NULL,
	[Surname]			[dbo].[LoadText] NULL,
	[SecondSurname]		[dbo].[LoadText] NULL,
	[CompanyName]		[dbo].[LoadText] NULL,
	[ContactAddress]	[dbo].[LoadText] NULL,
	[Address1]			[dbo].[LoadText] NULL,
	[Address2]			[dbo].[LoadText] NULL,
	[Address3]			[dbo].[LoadText] NULL,
	[Address4]			[dbo].[LoadText] NULL,
	[Address5]			[dbo].[LoadText] NULL,
	[Address6]			[dbo].[LoadText] NULL,
	[Postcode]			[dbo].[LoadText] NULL,
	[ContactPerson]		[dbo].[LoadText] NULL,
	[ContactPersonMobile]	[dbo].[LoadText] NULL,
	[VIN]					[dbo].[LoadText] NULL,
	[RegistrationNumber]	[dbo].[LoadText] NULL,
	[Dealercode]			[dbo].[LoadText] NULL,
	[WarrantyEventDate]		[dbo].[LoadText] NULL,
	[RetailEventDate]		[dbo].[LoadText] NULL,
	[Gender]				[dbo].[LoadText] NULL,
	[EmailAddress]			[dbo].[LoadText] NULL,
	[TelephonePrivate]		[dbo].[LoadText] NULL,
	[MobilePrivate]			[dbo].[LoadText] NULL,
	[TelephoneBusiness]		[dbo].[LoadText] NULL,
	[Language]				[dbo].[LoadText] NULL,
	[CountryCode]			[dbo].[LoadText] NULL,
	[ModelName]				[dbo].[LoadText] NULL,
	[ModelDetail]			[dbo].[LoadText] NULL,
	[ModelDetail2]			[dbo].[LoadText] NULL,
	[ModelDetail3]			[dbo].[LoadText] NULL,
	[PurchaseDate]			[dbo].[LoadText] NULL,
	[DeliveryDate]			[dbo].[LoadText] NULL,
	[TypeOfServiceWork]		[dbo].[LoadText] NULL,
	[EmployeeCode]			[dbo].[LoadText] NULL,
	[ConvertedServiceDate]			[datetime2](7) NULL
)

GO


