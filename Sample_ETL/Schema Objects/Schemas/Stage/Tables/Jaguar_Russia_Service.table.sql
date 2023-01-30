

CREATE TABLE [Stage].[Jaguar_Russia_Service] (
    [ID]						INT          IDENTITY (1, 1) NOT NULL,
    [AuditID]					dbo.AuditID  NULL,
    [PhysicalRowID]				INT          NULL,
	[DealerCode]				dbo.LoadText NULL,
	[VIN]						dbo.LoadText NULL,
	[ModelName]					dbo.LoadText NULL,
	[RegistrationNumber]		dbo.LoadText NULL,
	[EmptyField]				dbo.LoadText NULL,
	[EventDate]					dbo.LoadText NULL,
	[Surname]					dbo.LoadText NULL,
	[FirstName]					dbo.LoadText NULL,
	[FathersNameMiddleName]		dbo.LoadText NULL,
	[CompanyName]				dbo.LoadText NULL,
	[Address1]					dbo.LoadText NULL,
	[Address2]					dbo.LoadText NULL,
	[Address3]					dbo.LoadText NULL,
	[Address4]					dbo.LoadText NULL,
	[PostCode]					dbo.LoadText NULL,
	[BuyerType]					dbo.LoadText NULL,
	[HomeTelephone]				dbo.LoadText NULL,
	[WorkTelephone]				dbo.LoadText NULL,
	[MobileTelephone]			dbo.LoadText NULL,
    [EmailAddress]				dbo.LoadText NULL,
    [ConvertedEventDate]		DATETIME2    NULL
);