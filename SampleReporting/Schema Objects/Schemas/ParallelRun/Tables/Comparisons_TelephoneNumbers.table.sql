CREATE TABLE [ParallelRun].[Comparisons_TelephoneNumbers](
	[ComparisonLoadDate] [date] NULL,
	[FileName] [nvarchar](100) NULL,
	[PhysicalFileRow] [int] NOT NULL,
	[RemoteAuditID] [bigint] NOT NULL,
	[LocalAuditID] [bigint] NOT NULL,
	[RemoteAuditItemID] [bigint] NOT NULL,
	[LocalAuditItemID] [bigint] NOT NULL,
	[Mismatch_tn_ContactNumber] [int] NOT NULL,
	[Mismatch_tn_ContactNumberChecksum] [int] NOT NULL,
	[Mismatch_ptn_ContactNumber] [int] NOT NULL,
	[Mismatch_ptn_ContactNumberChecksum] [int] NOT NULL,
	[Mismatch_btn_ContactNumber] [int] NOT NULL,
	[Mismatch_btn_ContactNumberChecksum] [int] NOT NULL,
	[Mismatch_mtn_ContactNumber] [int] NOT NULL,
	[Mismatch_mtn_ContactNumberChecksum] [int] NOT NULL,
	[Mismatch_pmtn_ContactNumber] [int] NOT NULL,
	[Mismatch_pmtn_ContactNumberChecksum] [int] NOT NULL
)