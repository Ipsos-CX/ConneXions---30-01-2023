CREATE TABLE [ParallelRun].[Comparisons_EmailAddresses](
	[ComparisonLoadDate] [date] NULL,
	[FileName] [nvarchar](100) NULL,
	[PhysicalFileRow] [int] NOT NULL,
	[RemoteAuditID] [bigint] NOT NULL,
	[LocalAuditID] [bigint] NOT NULL,
	[RemoteAuditItemID] [bigint] NOT NULL,
	[LocalAuditItemID] [bigint] NOT NULL,
	[Mismatch_EmailAddress] [int] NOT NULL,
	[Mismatch_EmailAddressChecksum] [int] NOT NULL,
	[Mismatch_PrivEmailAddress] [int] NOT NULL,
	[Mismatch_PrivEmailAddressChecksum] [int] NOT NULL
) 