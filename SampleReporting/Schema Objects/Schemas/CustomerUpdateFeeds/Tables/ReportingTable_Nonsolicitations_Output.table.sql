﻿CREATE TABLE [CustomerUpdateFeeds].[ReportingTable_Nonsolicitations_Output](
	[PartyID] [int] NULL,
	[FirstName] [nvarchar](100) NULL,
	[LastName] [nvarchar](100) NULL,
	[OrganisationName] [nvarchar](510) NULL,
	[StreetNumber]        NVARCHAR (400) NULL,
    [Street]              NVARCHAR (400) NULL,
    [SubLocality]         NVARCHAR (400) NULL,
    [Locality]            NVARCHAR (400) NULL,
    [Town]                NVARCHAR (400) NULL,
    [Region]              NVARCHAR (400) NULL,
    [PostCode]            NVARCHAR (60)  NULL,
    [Country]             NVARCHAR (200) NULL,
    [ManufacturerPartyID] INT            NULL,
    [DealerCode]          NVARCHAR (100) NULL,
    [DealerName]          NVARCHAR (200) NULL,
    [RegistrationNumber]  NVARCHAR (100) NULL,
    [VIN]                 NVARCHAR (50)  NULL,
    [Source]              NVARCHAR (200) NULL,
    [UpdateFileName]      NVARCHAR (200) NULL,
    [DateOfUpdate]        VARCHAR (10)   NULL,
	[CustomerID] [nvarchar](60) NULL,
	[EmailAddress] [nvarchar](200) NULL
)