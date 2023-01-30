﻿CREATE TABLE [dbo].[DeletedSampledAndSelectionLogging](
	[DeleteComments] [Varchar](200) NOT NULL,
	[DateDeleted] [datetime2](7) NOT NULL,
	[LoadedDate] [datetime2](7) NOT NULL,
	[AuditID] [dbo].[AuditID] NOT NULL,
	[AuditItemID] [dbo].[AuditItemID] NOT NULL,
	[PhysicalFileRow] [int] NOT NULL,
	[ManufacturerID] [dbo].[PartyID] NULL,
	[SampleSupplierPartyID] [dbo].[PartyID] NULL,
	[MatchedODSPartyID] [dbo].[PartyID] NOT NULL,
	[PersonParentAuditItemID] [dbo].[AuditItemID] NULL,
	[MatchedODSPersonID] [dbo].[PartyID] NOT NULL,
	[LanguageID] [dbo].[LanguageID] NOT NULL,
	[PartySuppression] [bit] NOT NULL,
	[OrganisationParentAuditItemID] [dbo].[AuditItemID] NULL,
	[MatchedODSOrganisationID] [dbo].[PartyID] NOT NULL,
	[AddressParentAuditItemID] [dbo].[AuditItemID] NULL,
	[MatchedODSAddressID] [dbo].[ContactMechanismID] NOT NULL,
	[CountryID] [dbo].[CountryID] NULL,
	[PostalSuppression] [bit] NOT NULL,
	[AddressChecksum] [bigint] NULL,
	[MatchedODSTelID] [dbo].[ContactMechanismID] NULL,
	[MatchedODSPrivTelID] [dbo].[ContactMechanismID] NULL,
	[MatchedODSBusTelID] [dbo].[ContactMechanismID] NULL,
	[MatchedODSMobileTelID] [dbo].[ContactMechanismID] NULL,
	[MatchedODSPrivMobileTelID] [dbo].[ContactMechanismID] NULL,
	[MatchedODSEmailAddressID] [dbo].[ContactMechanismID] NULL,
	[MatchedODSPrivEmailAddressID] [dbo].[ContactMechanismID] NULL,
	[EmailSuppression] [bit] NOT NULL,
	[VehicleParentAuditItemID] [dbo].[AuditItemID] NULL,
	[MatchedODSVehicleID] [dbo].[VehicleID] NOT NULL,
	[ODSRegistrationID] [dbo].[RegistrationID] NULL,
	[MatchedODSModelID] [dbo].[ModelID] NULL,
	[OwnershipCycle] [dbo].[OwnershipCycle] NULL,
	[MatchedODSEventID] [dbo].[EventID] NOT NULL,
	[ODSEventTypeID] [dbo].[EventTypeID] NULL,
	[SaleDateOrig] [varchar](20) NULL,
	[SaleDate] [datetime2](7) NULL,
	[ServiceDateOrig] [varchar](20) NULL,
	[ServiceDate] [datetime2](7) NULL,
	[InvoiceDateOrig] [varchar](20) NULL,
	[InvoiceDate] [datetime2](7) NULL,
	[WarrantyID] [dbo].[WarrantyID] NULL,
	[SalesDealerCodeOriginatorPartyID] [dbo].[PartyID] NULL,
	[SalesDealerCode] [dbo].[DealerCode] NULL,
	[SalesDealerID] [dbo].[PartyID] NOT NULL,
	[ServiceDealerCodeOriginatorPartyID] [dbo].[PartyID] NULL,
	[ServiceDealerCode] [dbo].[DealerCode] NULL,
	[ServiceDealerID] [dbo].[PartyID] NOT NULL,
	[Brand] [dbo].[OrganisationName] NULL,
	[Market] [dbo].[Country] NULL,
	[Questionnaire] [dbo].[Requirement] NULL,
	[QuestionnaireRequirementID] [dbo].[RequirementID] NULL,
	[StartDays] [int] NULL,
	[EndDays] [int] NULL,
	[SuppliedName] [bit] NOT NULL,
	[SuppliedAddress] [bit] NOT NULL,
	[SuppliedPhoneNumber] [bit] NOT NULL,
	[SuppliedMobilePhone] [bit] NOT NULL,
	[SuppliedEmail] [bit] NOT NULL,
	[SuppliedVehicle] [bit] NOT NULL,
	[SuppliedRegistration] [bit] NOT NULL,
	[SuppliedEventDate] [bit] NOT NULL,
	[EventDateOutOfDate] [bit] NOT NULL,
	[EventNonSolicitation] [bit] NOT NULL,
	[PartyNonSolicitation] [bit] NOT NULL,
	[UnmatchedModel] [bit] NOT NULL,
	[UncodedDealer] [bit] NOT NULL,
	[EventAlreadySelected] [bit] NOT NULL,
	[NonLatestEvent] [bit] NOT NULL,
	[InvalidOwnershipCycle] [bit] NOT NULL,
	[RecontactPeriod] [bit] NOT NULL,
	[InvalidVehicleRole] [bit] NOT NULL,
	[CrossBorderAddress] [bit] NOT NULL,
	[CrossBorderDealer] [bit] NOT NULL,
	[ExclusionListMatch] [bit] NOT NULL,
	[InvalidEmailAddress] [bit] NOT NULL,
	[BarredEmailAddress] [bit] NOT NULL,
	[BarredDomain] [bit] NOT NULL,
	[CaseID] [dbo].[CaseID] NULL,
	[SampleRowProcessed] [bit] NOT NULL,
	[SampleRowProcessedDate] [datetime2](7) NULL,
	[WrongEventType] [bit] NOT NULL,
	[MissingStreet] [bit] NOT NULL,
	[MissingPostcode] [bit] NOT NULL,
	[MissingEmail] [bit] NOT NULL,
	[MissingTelephone] [bit] NOT NULL,
	[MissingStreetAndEmail] [bit] NOT NULL,
	[MissingTelephoneAndEmail] [bit] NOT NULL,
	[InvalidModel] [bit] NOT NULL,
	[MissingMobilePhone] [bit] NOT NULL,
	[MissingMobilePhoneAndEmail] [bit] NOT NULL,
	[MissingLanguage] [bit] NOT NULL,
	[CaseIDPrevious] [int] NULL,
	[RelativeRecontactPeriod] [int] NOT NULL,
	[MissingPartyName] [bit] NOT NULL,
	[InvalidManufacturer] [bit] NOT NULL,
	[InternalDealer] [bit] NOT NULL,
	[EventDateTooYoung]	[bit]	NOT NULL
)