﻿CREATE TABLE [Stage].[Combined_GeneralEnquiry]
(
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[AuditID] [dbo].[AuditID] NULL,
	[PhysicalRowID] [int] NULL,
	[CRCCode] [dbo].[LoadText] NULL,
	[MarketCode] [dbo].[LoadText] NULL,
	[BrandCode] [dbo].[LoadText] NULL,
	[RunDateofExtract] [dbo].[LoadText] NULL,
	[ExtractFromDate] [dbo].[LoadText] NULL,
	[ExtractToDate] [dbo].[LoadText] NULL,
	[ContactId] [dbo].[LoadText] NULL,
	[AssetId] [dbo].[LoadText] NULL,
	[CustomerLanguageCode] [dbo].[LoadText] NULL,
	[UniqueCustomerId] [dbo].[LoadText] NULL,
	[VehicleRegNumber] [dbo].[LoadText] NULL,
	[VIN] [dbo].[LoadText] NULL,
	[VehicleModel] [dbo].[LoadText] NULL,
	[VehicleDerivative] [dbo].[LoadText] NULL,
	[VehicleMileage] [dbo].[LoadText] NULL,
	[VehicleMonthsinService] [dbo].[LoadText] NULL,
	[CustomerTitle] [dbo].[LoadText] NULL,
	[CustomerInitial] [dbo].[LoadText] NULL,
	[CustomerFirstName] [dbo].[LoadText] NULL,
	[CustomerLastName] [dbo].[LoadText] NULL,
	[AddressLine1] [dbo].[LoadText] NULL,
	[AddressLine2] [dbo].[LoadText] NULL,
	[AddressLine3] [dbo].[LoadText] NULL,
	[AddressLine4] [dbo].[LoadText] NULL,
	[City] [dbo].[LoadText] NULL,
	[County] [dbo].[LoadText] NULL,
	[Country] [dbo].[LoadText] NULL,
	[PostalCode] [dbo].[LoadText] NULL,
	[PhoneMobile] [dbo].[LoadText] NULL,
	[PhoneHome] [dbo].[LoadText] NULL,
	[EmailAddress] [dbo].[LoadText] NULL,
	[CompanyName] [dbo].[LoadText] NULL,
	[RowId] [dbo].[LoadText] NULL,
	[CaseNumber] [dbo].[LoadText] NULL,
	[SRCreatedDate] [dbo].[LoadText] NULL,
	[SRClosedDate] [dbo].[LoadText] NULL,
	[Owner] [dbo].[LoadText] NULL,
	[ClosedBy] [dbo].[LoadText] NULL,
	[Type] [dbo].[LoadText] NULL,
	[PrimaryReasonCode] [dbo].[LoadText] NULL,
	[SecondaryReasonCode] [dbo].[LoadText] NULL,
	[ConcernAreaCode] [dbo].[LoadText] NULL,
	[SymptomCode] [dbo].[LoadText] NULL,
	[NoOfSelectedContacts] [dbo].[LoadText] NULL,
	[Rule1] [dbo].[LoadText] NULL,
	[Rule2] [dbo].[LoadText] NULL,
	[C05] [dbo].[LoadText] NULL,
	[C07] [dbo].[LoadText] NULL,
	[C15] [dbo].[LoadText] NULL,
	[T06] [dbo].[LoadText] NULL,
	[T08] [dbo].[LoadText] NULL,
	[T13] [dbo].[LoadText] NULL,
	[Rule5] [dbo].[LoadText] NULL,
	[Rule6] [dbo].[LoadText] NULL,
	[Rule7a] [dbo].[LoadText] NULL,
	[Rule7b] [dbo].[LoadText] NULL,
	[Rule8] [dbo].[LoadText] NULL,
	[ConvertedSRCreatedDate] [datetime2](7) NULL,
	[ConvertedSRClosedDate] [datetime2](7) NULL,
	[PreferredLanguageID] [int] NULL,
	[ManufacturerPartyID] [int] NULL,
	[SampleSupplierPartyID] [int] NULL,
	[CountryID] [smallint] NULL,
	[EventTypeID] [smallint] NULL,
	[LanguageID] [smallint] NULL,
	[DealerCodeOriginatorPartyID] [int] NULL,
	[SetNameCapitalisation] [bit] NULL,
	[CustomerIdentifierUsable] [bit] NULL,
	[SampleTriggeredSelectionReqID] [int] NULL
)
