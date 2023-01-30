
CREATE TABLE [Stage].[Jaguar_Ireland_Sales] (
    [ID]                      INT            IDENTITY (1, 1) NOT NULL,
    [AuditID]                 dbo.AuditID         NULL,
    [PhysicalRowID]           INT            NULL,
	[SalesDate]					dbo.LoadText NULL,
	[DealerCode]				dbo.LoadText NULL,
	[Model]						dbo.LoadText NULL,
	[VIN]						dbo.LoadText NULL,
	[Registration]				dbo.LoadText NULL,
	[Title]						dbo.LoadText NULL,
	[FirstName]					dbo.LoadText NULL,
	[LastName]					dbo.LoadText NULL,
	[Address1]					dbo.LoadText NULL,
	[Address2]					dbo.LoadText NULL,
	[Address3]					dbo.LoadText NULL,
	[Address4]					dbo.LoadText NULL,
	[Address5]					dbo.LoadText NULL,
	[Address6]					dbo.LoadText NULL,
	[Type]						dbo.LoadText NULL,
    [EmailAddress]              dbo.LoadText NULL,
    [ConvertedSalesDate]   DATETIME2       NULL
);
