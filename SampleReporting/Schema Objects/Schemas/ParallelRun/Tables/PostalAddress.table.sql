CREATE TABLE [ParallelRun].[PostalAddress] (
	[FileName] [nvarchar](100) NULL,
	[PhysicalFileRow] [int] NOT NULL,
	[AuditID] [bigint] NOT NULL,
	[AuditItemID] [bigint] NOT NULL,
	[ContactMechanismID] [int] NULL,
	[BuildingName] [nvarchar](400) NULL,
	[SubStreetNumber] [nvarchar](40) NULL,
	[SubStreet] [nvarchar](400) NULL,
	[StreetNumber] [nvarchar](40) NULL,
	[Street] [nvarchar](400) NULL,
	[SubLocality] [nvarchar](400) NULL,
	[Locality] [nvarchar](400) NULL,
	[Town] [nvarchar](400) NULL,
	[Region] [nvarchar](400) NULL,
	[PostCode] [nvarchar](60) NULL,
	[CountryID] [smallint] NULL,
	[AddressChecksum] [bigint] NULL
);
