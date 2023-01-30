﻿CREATE TABLE [SelectionUpload].[CATIService](
	[PartyID] [bigint] NULL,
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
	[NewSurveyFile] [varchar](1) NULL,
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
	[SVOvehicle] [varchar](200) NULL,
	[FOBCode] [int] NULL,
	[SurveyURL] [varchar](500) NULL,
	[CATIType] [int] NULL,
	[Filedate] [varchar](30) NULL,
	[Queue] [varchar](10) NULL,
	[AssignedMode] [varchar](10) NULL,
	[RequiresManualDial] [varchar](1) NULL,
	[CallRecordingsCount] [varchar](1) NULL,
	[TimeZone] [int] NULL,
	[CallOutcome] [varchar](10) NULL,
	[PhoneNumber] [nvarchar](70) NULL,
	[PhoneSource] [varchar](50) NULL,
	[Language] [varchar](10) NULL,
	[ExpirationTime] [datetime2](7) NULL,
	[HomePhoneNumber] [nvarchar](70) NULL,
	[WorkPhoneNumber] [nvarchar](70) NULL,
	[MobilePhoneNumber] [nvarchar](70) NULL,
	[SampleFileName] [varchar](512) NULL, 
    [ServiceEventType] VARCHAR(50) NULL
) 