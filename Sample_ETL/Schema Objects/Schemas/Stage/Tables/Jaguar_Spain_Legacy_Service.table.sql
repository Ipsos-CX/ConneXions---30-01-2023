﻿CREATE TABLE [Stage].[Jaguar_Spain_Legacy_Service] (
    [ID] [int] IDENTITY(1,1) NOT NULL,
		[AuditID] [dbo].[AuditID] NULL,
		[PhysicalRowID] [int] NULL,
		[Title] [dbo].[LoadText] NULL,
		[FirstName] [dbo].[LoadText] NULL,
		[Surname] [dbo].[LoadText] NULL,
		[CompanyName] [dbo].[LoadText] NULL,
		[StreetHouseNo] [dbo].[LoadText] NULL,
		[Address2] [dbo].[LoadText] NULL,
		[Town] [dbo].[LoadText] NULL,
		[Province] [dbo].[LoadText] NULL,
		[Address5] [dbo].[LoadText] NULL,
		[Address6] [dbo].[LoadText] NULL,
		[Address7] [dbo].[LoadText] NULL,
		[Address8] [dbo].[LoadText] NULL,
		[Address9] [dbo].[LoadText] NULL,
		[PostCode] [dbo].[LoadText] NULL,
		[CustomerType] [dbo].[LoadText] NULL,
		[TelephoneHome] [dbo].[LoadText] NULL,
		[TelephoneHomeMobile] [dbo].[LoadText] NULL,
		[TelephoneWork] [dbo].[LoadText] NULL,
		[Telephone] [dbo].[LoadText] NULL,
		[VIN] [dbo].[LoadText] NULL,
		[ModelDescription] [dbo].[LoadText] NULL,
		[RegistrationNumber] [dbo].[LoadText] NULL,
		[Blank] [dbo].[LoadText] NULL,
		[DealerCode] [dbo].[LoadText] NULL,
		[PurchaseDate] [dbo].[LoadText] NULL,
		[RegDate] [dbo].[LoadText] NULL,
		[DeliveryDate] [dbo].[LoadText] NULL,
		[ServiceEventDate] [dbo].[LoadText] NULL,
		[TypeOfWork] [dbo].[LoadText] NULL,
		[LanguageCode] [dbo].[LoadText] NULL,
		[CountryCode] [dbo].[LoadText] NULL,
		[ManufacturerID] [dbo].[LoadText] NULL,
		[EmailAddress] [dbo].[LoadText] NULL,
		[SuppressionCode] [dbo].[LoadText] NULL,
		[ConvertedPurchaseDate] [datetime2](7) NULL,
		[ConvertedRegDate] [datetime2](7) NULL,
		[ConvertedDeliveryDate] [datetime2](7) NULL,
		[ConvertedServiceEventDate] [datetime2](7) NULL
);

