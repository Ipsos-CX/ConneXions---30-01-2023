﻿CREATE TABLE [Stage].[Global_PreOwned_Sales]
(
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[AuditID] [dbo].[AuditID] NULL,
	[PhysicalRowID] [int] NULL,
	[Manufacturer] [dbo].[LoadText] NULL,
	[CountryCode] [dbo].[LoadText] NULL,
	[EventType] [dbo].[LoadText] NULL,
	[VehiclePurchaseDate] [dbo].[LoadText] NULL,
	[VehicleRegistrationDate] [dbo].[LoadText] NULL,
	[VehicleDeliveryDate] [dbo].[LoadText] NULL,
	[UsedCarSalesEventDate] [dbo].[LoadText] NULL,
	[DealerCode] [dbo].[LoadText] NULL,
	[CustomerUniqueID] [dbo].[LoadText] NULL,
	[CompanyName] [dbo].[LoadText] NULL,
	[Title] [dbo].[LoadText] NULL,
	[FirstName] [dbo].[LoadText] NULL,
	[SurnameField1] [dbo].[LoadText] NULL,
	[SurnameField2] [dbo].[LoadText] NULL,
	[Salutation] [dbo].[LoadText] NULL,
	[Address1] [dbo].[LoadText] NULL,
	[Address2] [dbo].[LoadText] NULL,
	[Address3] [dbo].[LoadText] NULL,
	[Address4] [dbo].[LoadText] NULL,
	[Address5] [dbo].[LoadText] NULL,
	[Address6] [dbo].[LoadText] NULL,
	[Address7] [dbo].[LoadText] NULL,
	[Address8] [dbo].[LoadText] NULL,
	[HomeTelephoneNumber] [dbo].[LoadText] NULL,
	[BusinessTelephoneNumber] [dbo].[LoadText] NULL,
	[MobileTelephoneNumber] [dbo].[LoadText] NULL,
	[ModelName] [dbo].[LoadText] NULL,
	[ModelYear] [dbo].[LoadText] NULL,
	[VIN] [dbo].[LoadText] NULL,
	[RegistrationNumber] [dbo].[LoadText] NULL,
	[EmailAddress1] [dbo].[LoadText] NULL,
	[EmailAddress2] [dbo].[LoadText] NULL,
	[PreferredLanguage] [dbo].[LoadText] NULL,
	[CompleteSuppression] [dbo].[LoadText] NULL,
	[SuppressionEmail] [dbo].[LoadText] NULL,
	[SuppressionPhone] [dbo].[LoadText] NULL,
	[SuppressionMail] [dbo].[LoadText] NULL,
	[InvoiceNumber] [dbo].[LoadText] NULL,
	[InvoiceValue] [dbo].[LoadText] NULL,
	[SalesEmployeeCode] [dbo].[LoadText] NULL,
	[EmployeeName] [dbo].[LoadText] NULL,
	[OwnershipCycle] [dbo].[LoadText] NULL,
	[Gender] [dbo].[LoadText] NULL,
	[PrivateOwner] [dbo].[LoadText] NULL,
	[OwningCompany] [dbo].[LoadText] NULL,
	[UserChooserDriver] [dbo].[LoadText] NULL,
	[EmployerCompany] [dbo].[LoadText] NULL,
	[MonthAndYearOfBirth] [dbo].[LoadText] NULL,
	[PreferrredMethodOfContact] [dbo].[LoadText] NULL,
	[PermissionsForContact] [dbo].[LoadText] NULL,
	[ApprovedNOTApproved] [dbo].[LoadText] NULL,
	[ConvertedVehicleDeliveryDate] [datetime2](7) NULL,
	[ConvertedUsedCarSalesEventDate] [datetime2](7) NULL,
	[ConvertedVehiclePurchaseDate] [datetime2](7) NULL,
	[ConvertedVehicleRegistrationDate] [datetime2](7) NULL,
	[ManufacturerPartyID] [int] NULL,
	[SampleSupplierPartyID] [int] NULL,
	[CountryID] [smallint] NULL,
	[EventTypeID] [smallint] NULL,
	[LanguageID] [smallint] NULL,
	[DealerCodeOriginatorPartyID] [int] NULL,
	[SetNameCapitalisation] [bit] NULL,
	[SampleTriggeredSelectionReqID]   INT NULL,
	[CustomerIdentifier] [dbo].[CustomerIdentifier] NULL,
	[CustomerIdentifierUsable] BIT NULL
)
