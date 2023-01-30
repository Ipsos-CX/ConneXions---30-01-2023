

CREATE TABLE [Stage].[Jaguar_Korea_Sales] (
    [ID]						INT          IDENTITY (1, 1) NOT NULL,
    [AuditID]					dbo.AuditID  NULL,
    [PhysicalRowID]				INT          NULL,
    [ManufacturerCode]			dbo.LoadText NULL,
	[VIN]						dbo.LoadText NULL,
	[RegistrationNumber]		dbo.LoadText NULL,
	[Model]						dbo.LoadText NULL,
	[EV]						dbo.LoadText NULL,
	[Dealer]					dbo.LoadText NULL,
	[SalesEventDate]			dbo.LoadText NULL,
	[Customer]					dbo.LoadText NULL,
	[CompanyName]				dbo.LoadText NULL,
	[Phone]						dbo.LoadText NULL,
	[MobileOnly]				dbo.LoadText NULL,
	[Postal]					dbo.LoadText NULL,
	[Address1]					dbo.LoadText NULL,
	[Address2]					dbo.LoadText NULL,
    [EmailAddress]				dbo.LoadText NULL,
    [ConvertedSalesEventDate]	DATETIME2    NULL
);

