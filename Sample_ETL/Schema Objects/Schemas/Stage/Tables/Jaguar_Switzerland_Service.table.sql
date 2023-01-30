

CREATE TABLE [Stage].[Jaguar_Switzerland_Service] (
    [ID]						INT          IDENTITY (1, 1) NOT NULL,
    [AuditID]					dbo.AuditID  NULL,
    [PhysicalRowID]				INT          NULL,
	[Title]						dbo.LoadText NULL,
	[Surname]					dbo.LoadText NULL,
	[Firstname]					dbo.LoadText NULL,
	[OrganisationName]			dbo.LoadText NULL,
	[Address1]					dbo.LoadText NULL,
	[Postcode]					dbo.LoadText NULL,
	[Town]						dbo.LoadText NULL,
	[Language]					dbo.LoadText NULL,
	[Model]						dbo.LoadText NULL,
	[Vin]						dbo.LoadText NULL,
	[SalesDate]					dbo.LoadText NULL,
	[Dealercode]				dbo.LoadText NULL,
	[ServiceEventDate]			dbo.LoadText NULL,
    [EmailAddress]				dbo.LoadText NULL,
    [ConvertedSalesDate]		DATETIME2    NULL,
    [ConvertedServiceEventDate]	DATETIME2    NULL
);
