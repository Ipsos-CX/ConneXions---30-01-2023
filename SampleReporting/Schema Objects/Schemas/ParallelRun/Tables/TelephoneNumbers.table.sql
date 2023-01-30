CREATE TABLE [ParallelRun].[TelephoneNumbers] (
	[FileName] [nvarchar](100) NULL,
	[PhysicalFileRow] [int] NOT NULL,
	[AuditID] [bigint] NOT NULL,
	[AuditItemID] [bigint] NOT NULL,
	[tn_ContactNumber] [nvarchar](70) NULL,
	[tn_ContactNumberChecksum] [int] NULL,
	[ptn_ContactNumber] [nvarchar](70) NULL,
	[ptn_ContactNumberChecksum] [int] NULL,
	[btn_ContactNumber] [nvarchar](70) NULL,
	[btn_ContactNumberChecksum] [int] NULL,
	[mtn_ContactNumber] [nvarchar](70) NULL,
	[mtn_ContactNumberChecksum] [int] NULL,
	[pmtn_ContactNumber] [nvarchar](70) NULL,
	[pmtn_ContactNumberChecksum] [int] NULL
);
