﻿CREATE TABLE [Selection].[NPS_SelectedEvents_ForExcelOutput]
(
	[SelectionDate] [SMALLDATETIME] NOT NULL,
	[MIS] [NVARCHAR](6) NOT NULL,
	[EventID] [INT] NOT NULL,
	[VehicleID] [INT] NOT NULL,
	[VehicleRoleTypeID] [TINYINT] NOT NULL,
	[Password] [NVARCHAR](10) NOT NULL,
	[CaseID] [INT] NULL,
	[NewCaseID] [INT] IDENTITY (32035640,1) NOT NULL,
	[FullModel] [NVARCHAR](50) NOT NULL,
	[Model] [NVARCHAR](50) NOT NULL,
	[VIN] [NVARCHAR](50) NOT NULL,
	[sType] [NVARCHAR](10) NOT NULL,
	[CarReg] [NVARCHAR](100) NULL,
	[Title] [NVARCHAR](100) NULL,
	[Initial] [NVARCHAR](100) NULL,
	[Surname] [NVARCHAR](100) NULL,
	[Fullname] [NVARCHAR](400) NULL,
	[DearName] [NVARCHAR](400) NULL,
	[CoName] [NVARCHAR](400) NULL,
	[PostalContactMechanismID] [INT] NULL,
	[Add1] [NVARCHAR](400) NULL,
	[Add2] [NVARCHAR](400) NULL,
	[Add3] [NVARCHAR](400) NULL,
	[Add4] [NVARCHAR](400) NULL,
	[Add5] [NVARCHAR](400) NULL,
	[Add6] [NVARCHAR](400) NULL,
	[Add7] [NVARCHAR](400) NULL,
	[Add8] [NVARCHAR](400) NULL,
	[Add9] [NVARCHAR](400) NULL,
	[CTRY] [NVARCHAR](200) NULL,
	[EmailAddress] [NVARCHAR](500) NULL,
	[Dealer] [NVARCHAR](510) NOT NULL,
	[sno] [TINYINT] NOT NULL,
	[ccode] [SMALLINT] NOT NULL,
	[modelcode] [SMALLINT] NULL,
	[lang] [SMALLINT] NULL,
	[manuf] [INT] NOT NULL,
	[gender] [TINYINT] NOT NULL,
	[qver] [TINYINT] NOT NULL,
	[blank] [NCHAR](1) NOT NULL,
	[etype] [TINYINT] NOT NULL,
	[reminder] [TINYINT] NOT NULL,
	[week] [TINYINT] NOT NULL,
	[test] [TINYINT] NOT NULL,
	[SampleFlag] [TINYINT] NOT NULL,
	[EventDate] [SMALLDATETIME] NOT NULL,
	[DealerCode] [NVARCHAR](20) NULL,
	[RespondentPartyID] [INT] NOT NULL,
	[HomeNumber] [NVARCHAR](70) NULL,
	[WorkNumber] [NVARCHAR](70) NULL,
	[MobileNumber] [NVARCHAR](70) NULL,
	[ManufacturerDealerCode] [NVARCHAR](20) NULL,
	[ModelYear] [INT] NULL,
	[OwnershipCycle] [TINYINT] NULL,
	[DealerPartyID] [INT] NOT NULL,
	[GDDDealerCode] [NVARCHAR](20) NULL,
	[SuperNationalRegion] [NVARCHAR](200) NULL,
	[ReportingDealerPartyID] [INT] NULL,
	[VariantID] [TINYINT] NOT NULL,
	[ModelVariant] [NVARCHAR](50) NOT NULL,
	[ITYPE] [NCHAR](1) NULL,
	[CLPSalesCaseID] NVARCHAR(50) NULL,
	[CLPServiceCaseID] NVARCHAR(50) NULL,
	[RoadSideCaseID] NVARCHAR(50) NULL,
	[NewUsed] [NCHAR](1)NOT NULL
)
