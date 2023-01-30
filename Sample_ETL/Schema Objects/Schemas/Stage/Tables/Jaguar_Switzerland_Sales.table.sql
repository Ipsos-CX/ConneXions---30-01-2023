

CREATE TABLE [Stage].[Jaguar_Switzerland_Sales] (
    [ID]						INT          IDENTITY (1, 1) NOT NULL,
    [AuditID]					dbo.AuditID  NULL,
    [PhysicalRowID]				INT          NULL,
	[Title]						dbo.LoadText NULL,
	[Surname]					dbo.LoadText NULL,
	[FirstName]					dbo.LoadText NULL,
	[CompanyName]				dbo.LoadText NULL,
	[StreetHouseNo]				dbo.LoadText NULL,
	[PostCode]					dbo.LoadText NULL,
	[Town]						dbo.LoadText NULL,
	[LanguageCode]				dbo.LoadText NULL,
	[ModelDescription]			dbo.LoadText NULL,
	[VIN]						dbo.LoadText NULL,
	[DeliveryDate]				dbo.LoadText NULL,
	[SalesDealerCode]			dbo.LoadText NULL,
    [EmailAddress]				dbo.LoadText NULL,
    [ConvertedDeliveryDate]	DATETIME2    NULL
);

