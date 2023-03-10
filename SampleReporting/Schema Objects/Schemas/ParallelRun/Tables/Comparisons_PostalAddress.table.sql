CREATE TABLE [ParallelRun].[Comparisons_PostalAddress](
	[ComparisonLoadDate] [date] NULL,
	[FileName] [nvarchar](100) NULL,
	[PhysicalFileRow] [int] NOT NULL,
	[RemoteAuditID] [bigint] NOT NULL,
	[LocalAuditID] [bigint] NOT NULL,
	[RemoteAuditItemID] [bigint] NOT NULL,
	[LocalAuditItemID] [bigint] NOT NULL,
	[Mismatch_ContactMechanismID] [int] NOT NULL,
	[Mismatch_BuildingName] [int] NOT NULL,
	[Mismatch_SubStreetNumber] [int] NOT NULL,
	[Mismatch_SubStreet] [int] NOT NULL,
	[Mismatch_StreetNumber] [int] NOT NULL,
	[Mismatch_Street] [int] NOT NULL,
	[Mismatch_SubLocality] [int] NOT NULL,
	[Mismatch_Locality] [int] NOT NULL,
	[Mismatch_Town] [int] NOT NULL,
	[Mismatch_Region] [int] NOT NULL,
	[Mismatch_PostCode] [int] NOT NULL,
	[Mismatch_CountryID] [int] NOT NULL,
	[Mismatch_AddressChecksum] [int] NOT NULL
)