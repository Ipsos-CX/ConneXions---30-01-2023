﻿CREATE TABLE [Stage].[LandRover_Korea_Service]
(
	[ID]							INT				IDENTITY (1, 1) NOT NULL,
    [AuditID]						dbo.AuditID		NULL,
    [PhysicalRowID]					INT				NULL,
    [ManufacturerCode]				dbo.LoadText	NULL,
    [CountryCode]					dbo.LoadText	NULL,
    [EventType]						dbo.LoadText	NULL,
    [RegistrationDate]				dbo.LoadText	NULL,
    [ServiceEventDate]				dbo.LoadText	NULL,
    [DealerCode]					dbo.LoadText	NULL,
    [DealerName]					dbo.LoadText	NULL,
    [CustomerUniqueID]				dbo.LoadText	NULL,
    [FirstName]						dbo.LoadText	NULL,
    [CompanyName]					dbo.LoadText	NULL,
    [PostalCode]					dbo.LoadText	NULL,
    [Address1] 						dbo.LoadText	NULL,
	[Address2] 						dbo.LoadText	NULL,
    [HomePhone]						dbo.LoadText	NULL,
    [BusinessPhone] 				dbo.LoadText	NULL,
    [MobilePhone] 					dbo.LoadText	NULL,
    [ModelName]						dbo.LoadText	NULL,
    [ModelYear]						dbo.LoadText	NULL,
    [Vin]							dbo.LoadText	NULL,
    [RegistrationNumber]			dbo.LoadText	NULL,
    [EmailAddress]					dbo.LoadText	NULL,
    [EmployeeName]					dbo.LoadText	NULL,
    [OwnershipCycle]				dbo.LoadText	NULL,
    [Gender]						dbo.LoadText	NULL,
    [PrivateOwner]					dbo.LoadText	NULL,
    [OwningCompany]					dbo.LoadText	NULL,
    [UserChooserDriver]				dbo.LoadText	NULL,
    [EmployerCompany]				dbo.LoadText	NULL,
    [PermissionforContact]			dbo.LoadText	NULL,
    [ConvertedServiceEventDate]		DATETIME2		NULL,
    [ConvertedRegistrationDate]		DATETIME2		NULL
)
