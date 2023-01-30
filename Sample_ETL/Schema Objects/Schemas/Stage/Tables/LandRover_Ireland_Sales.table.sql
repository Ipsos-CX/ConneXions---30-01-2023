

CREATE TABLE [Stage].[LandRover_Ireland_Sales] (
    [ID]						INT          IDENTITY (1, 1) NOT NULL,
    [AuditID]					dbo.AuditID  NULL,
    [PhysicalRowID]				INT          NULL,
	[CompanyName]				dbo.LoadText NULL,
	[Title]						dbo.LoadText NULL,
	[FirstName]					dbo.LoadText NULL,
	[Surname]					dbo.LoadText NULL,
	[Address1]					dbo.LoadText NULL,
	[Address2]					dbo.LoadText NULL,
	[Address3]					dbo.LoadText NULL,
	[Address4]					dbo.LoadText NULL,
	[Address5]					dbo.LoadText NULL,
	[TelephoneUnknown]			dbo.LoadText NULL,
	[VIN]						dbo.LoadText NULL,
	[RegistrationNumber]		dbo.LoadText NULL,	
	[SalesDealerCode]			dbo.LoadText NULL,
	[RegistrationDate]			dbo.LoadText NULL,
	[GenderCode]				dbo.LoadText NULL,
    [EmailAddress]              dbo.LoadText NULL,
    [ConvertedRegistrationDate] DATETIME2    NULL
);
