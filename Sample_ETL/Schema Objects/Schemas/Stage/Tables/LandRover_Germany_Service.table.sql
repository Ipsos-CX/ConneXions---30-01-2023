CREATE TABLE [Stage].[LandRover_Germany_Service] (
    [ID]						INT            IDENTITY (1, 1) NOT NULL,
    [AuditID]					dbo.AuditID         NULL,
    [PhysicalRowID]				INT            NULL,
	[SesamID]					dbo.LoadText NULL,
	[SourceID]					dbo.LoadText NULL,
	[DealerCode]				dbo.LoadText NULL,
	[InvoiceNO]					dbo.LoadText NULL,
	[CompanyName]				dbo.LoadText NULL,
	[AcademicTitle]				dbo.LoadText NULL,
	[Title]						dbo.LoadText NULL,
	[Salutation]				dbo.LoadText NULL,
	[FirstName]					dbo.LoadText NULL,
	[Surname]					dbo.LoadText NULL,
	[StreetHouseNO]				dbo.LoadText NULL,
	[PostCode]					dbo.LoadText NULL,
	[Town]						dbo.LoadText NULL,
	[Country]					dbo.LoadText NULL,
	[HomeTel]					dbo.LoadText NULL,
	[WorkTel]					dbo.LoadText NULL,
	[VIN]						dbo.LoadText NULL,
	[RegistrationNO]			dbo.LoadText NULL,
	[RegistrationDate]			dbo.LoadText NULL,
	[RetailDate]				dbo.LoadText NULL,
	[SalesDate]					dbo.LoadText NULL,
	[DeliveryDate]				dbo.LoadText NULL,
	[ServiceEventDate]			dbo.LoadText NULL,
	[EmailAddress]				dbo.LoadText NULL,
    [ConvertedRegistrationDate] DATETIME2	NULL,
    [ConvertedSalesDate]		DATETIME2	NULL,
    [ConvertedRetailDate]		DATETIME2	NULL,
    [ConvertedDeliveryDate]		DATETIME2	NULL,
    [ConvertedServiceEventDate]	DATETIME2	NULL,
	[EmployeeName]				dbo.LoadText NULL
);
