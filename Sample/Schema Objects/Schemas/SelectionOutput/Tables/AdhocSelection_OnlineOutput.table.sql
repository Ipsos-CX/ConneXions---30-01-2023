﻿CREATE TABLE [SelectionOutput].[AdhocSelection_OnlineOutput]
(
	[ID] [int] IDENTITY (1, 1) NOT NULL,
    [RequirementID] [dbo].[RequirementID] NOT NULL,
	[PartyID] [dbo].[PartyID] NULL,
	[FullModel] [varchar](50) NULL,
	[Model] [varchar](50) NULL,
	[sType] [dbo].[OrganisationName] NULL,
	[CarReg] [dbo].[RegistrationNumber] NULL,
	[Title] [dbo].[Title] NULL,
	[Initial] [dbo].[NameDetail] NULL,
	[Surname] [dbo].[NameDetail] NULL,
	[Fullname] [dbo].[AddressingText] NULL,
	[DearName] [dbo].[AddressingText] NULL,
	[CoName] [dbo].[OrganisationName] NULL,
	[Add1] [dbo].[AddressText] NULL,
	[Add2] [dbo].[AddressText] NULL,
	[Add3] [dbo].[AddressText] NULL,
	[Add4] [dbo].[AddressText] NULL,
	[Add5] [dbo].[AddressText] NULL,
	[Add6] [dbo].[AddressText] NULL,
	[Add7] [dbo].[AddressText] NULL,
	[Add8] [dbo].[Postcode] NULL,
	[Add9] [dbo].[AddressText] NULL,
	[CTRY] [dbo].[Country] NULL,
	[EmailAddress] [dbo].[EmailAddress] NULL,
	[Dealer] [dbo].[DealerName] NULL,
	[sno] [dbo].[VersionCode] NULL,
	[ccode] [dbo].[CountryID] NULL,
	[modelcode] [dbo].[RequirementID] NULL,
	[lang] [dbo].[LanguageID] NULL,
	[manuf] [dbo].[PartyID] NULL,
	[gender] [dbo].[GenderID] NULL,
	[qver] [dbo].[QuestionnaireVersion] NULL,
	[blank] [varchar](150) NULL,
	[etype] [dbo].[EventTypeID] NULL,
	[reminder] [int] NULL,
	[week] [int] NULL,
	[test] [int] NULL,
	[SampleFlag] [int] NULL,
	[SurveyFile] [varchar](100) NULL,
	[ITYPE] [varchar](5) NULL,
	[Expired] [datetime2](7) NULL,
	[EventDate] [varchar](50) NULL,
	[VIN] [dbo].[VIN] NULL,
	[DealerCode] [dbo].[DealerCode] NULL,
	[GlobalDealerCode] [dbo].[DealerCode] NULL,
	[LandPhone] [dbo].[ContactNumber] NULL,
	[WorkPhone] [dbo].[ContactNumber] NULL,
	[MobilePhone] [dbo].[ContactNumber] NULL,
	[ModelYear] [int] NULL,
	[CustomerUniqueID] [dbo].[CustomerIdentifier] NULL,
	[OwnershipCycle] [dbo].[OwnershipCycle] NULL,
	[EmployeeCode] [dbo].[NameDetail] NULL,
	[EmployeeName] [dbo].[NameDetail] NULL,
	[DealerPartyID] [dbo].[PartyID] NULL,
	[Password] [dbo].[SelectionOutputPassword] NULL,
	[ReportingDealerPartyID] [dbo].[PartyID] NULL,
	[ModelVariantCode] [dbo].[ModelID] NULL,
	[ModelVariantDescription] [varchar](50) NULL,
	[SelectionDate] [datetime2](7) NULL,
	[CampaignId] [varchar](50) NULL,
	[PilotCode] [varchar](10) NULL,
	[EmailContactMechanismID] [dbo].[ContactMechanismID] NULL,
	[PhoneContactMechanismID] [dbo].[ContactMechanismID] NULL,
	[LandlineContactMechanismID] [dbo].[ContactMechanismID] NULL,
	[MobileContactMechanismID] [dbo].[ContactMechanismID] NULL,
	[PostalContactMechanismID] [dbo].[ContactMechanismID] NULL,
	[EventID] [dbo].[EventID] NULL,
	[VehicleID] [dbo].[VehicleID] NULL
)
