

CREATE TABLE [Stage].[LandRover_Japan_Sales] (
    [ID]						INT          IDENTITY (1, 1) NOT NULL,
    [AuditID]					dbo.AuditID  NULL,
    [PhysicalRowID]				INT          NULL,
	[DealerCode]				dbo.LoadText NULL,
	[OutletCode]				dbo.LoadText NULL,
	[StockNumber]				dbo.LoadText NULL,
	[RegistrationDate]			dbo.LoadText NULL,
	[RegistrationNumber]		dbo.LoadText NULL,
	[VIN]						dbo.LoadText NULL,
	[CompanyName]				dbo.LoadText NULL,
	[Surname]					dbo.LoadText NULL,
	[Firstname]					dbo.LoadText NULL,
	[Title]						dbo.LoadText NULL,
	[CustomerNameReading]		dbo.LoadText NULL,
	[TelephoneUnknown]			dbo.LoadText NULL,
	[PostCode]					dbo.LoadText NULL,
	[BuildingName]				dbo.LoadText NULL,
	[Address]					dbo.LoadText NULL,
	[AddressReading]			dbo.LoadText NULL,
    [EmailAddress]				dbo.LoadText NULL,
    [ConvertedregistrationDate]	DATETIME2    NULL,
    [Mobile_Number] dbo.LoadText NULL -- BUG 15373 
);


