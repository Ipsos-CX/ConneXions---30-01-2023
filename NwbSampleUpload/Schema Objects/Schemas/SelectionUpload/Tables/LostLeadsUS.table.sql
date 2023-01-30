﻿CREATE TABLE [SelectionUpload].[LostLeadsUS](
	[PartyID] [bigint] NOT NULL,
	[ID] [bigint] NOT NULL,
	[FullModel] [varchar](50) NULL,
	[Model] [varchar](50) NULL,
	[sType] [nvarchar](510) NULL,
	[CarReg] [nvarchar](100) NULL,
	[Title] [nvarchar](200) NULL,
	[Initial] [nvarchar](100) NULL,
	[Surname] [nvarchar](100) NULL,
	[Fullname] [nvarchar](500) NULL,
	[DearName] [nvarchar](500) NULL,
	[CoName] [nvarchar](510) NULL,
	[Add1] [nvarchar](400) NULL,
	[Add2] [nvarchar](400) NULL,
	[Add3] [nvarchar](400) NULL,
	[Add4] [nvarchar](400) NULL,
	[Add5] [nvarchar](400) NULL,
	[Add6] [nvarchar](400) NULL,
	[Add7] [nvarchar](400) NULL,
	[Add8] [nvarchar](60) NULL,
	[Add9] [nvarchar](400) NULL,
	[CTRY] [varchar](200) NULL,
	[EmailAddress] [nvarchar](510) NULL,
	[Dealer] [nvarchar](150) NULL,
	[sno] [varchar](200) NULL,
	[ccode] [smallint] NULL,
	[modelcode] [int] NULL,
	[lang] [smallint] NULL,
	[manuf] [int] NULL,
	[gender] [tinyint] NULL,
	[qver] [tinyint] NULL,
	[blank] [varchar](150) NULL,
	[etype] [smallint] NULL,
	[reminder] [int] NULL,
	[week] [int] NULL,
	[test] [int] NULL,
	[SampleFlag] [int] NULL,
	[LOSTLEADSsurveyfile] [varchar](1) NULL,
	[ITYPE] [varchar](5) NULL,
	[Expired] [datetime2](7) NULL,
	[EventDate] [datetime2](7) NULL,
	[VIN] [nvarchar](50) NULL,
	[DealerCode] [nvarchar](50) NULL,
	[GlobalDealerCode] [nvarchar](20) NULL,
	[HomeNumber] [nvarchar](70) NULL,
	[WorkNumber] [nvarchar](70) NULL,
	[MobileNumber] [nvarchar](70) NULL,
	[ModelYear] [int] NULL,
	[CustomerUniqueID] [nvarchar](60) NULL,
	[OwnershipCycle] [tinyint] NULL,
	[SalesEmployeeCode] [nvarchar](100) NULL,
	[SalesEmployeeName] [nvarchar](100) NULL,
	[ServiceEmployeeCode] [nvarchar](100) NULL,
	[ServiceEmployeeName] [nvarchar](100) NULL,
	[DealerPartyID] [int] NULL,
	[Password] [varchar](20) NULL,
	[ReportingDealerPartyID] [int] NULL,
	[ModelVariantCode] [int] NULL,
	[ModelVariantDescription] [varchar](50) NULL,
	[SelectionDate] [datetime2](7) NULL,
	[CampaignId] [nvarchar](100) NULL,
	[EmailSignator] [nvarchar](500) NULL,
	[EmailSignatorTitle] [nvarchar](500) NULL,
	[EmailContactText] [nvarchar](2000) NULL,
	[EmailCompanyDetails] [nvarchar](2000) NULL,
	[JLRPrivacyPolicy] [nvarchar](500) NULL,
	[JLRCompanyname] [nvarchar](2000) NULL,
	[SVOvehicle] [varchar](200) NULL,
	[FOBCode] [int] NULL,
	[BilingualFlag] [bit] NULL,
	[langBilingual] [smallint] NULL,
	[DearNameBilingual] [nvarchar](500) NULL,
	[EmailSignatorTitleBilingual] [nvarchar](500) NULL,
	[EmailContactTextBilingual] [nvarchar](2000) NULL,
	[EmailCompanyDetailsBilingual] [nvarchar](2000) NULL,
	[JLRPrivacyPolicyBilingual] [nvarchar](500) NULL,
	[NSCFlag] [varchar](1) NULL,
	[JLREventType] [varchar](50) NULL,
	[DealerType] VARCHAR(50) NULL
) 