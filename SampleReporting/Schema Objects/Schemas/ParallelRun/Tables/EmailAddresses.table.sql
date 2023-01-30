CREATE TABLE [ParallelRun].[EmailAddresses] (
	[FileName] [nvarchar](100) NULL,
	[PhysicalFileRow] [int] NOT NULL,
	[AuditID] [bigint] NOT NULL,
	[AuditItemID] [bigint] NOT NULL,
	[EmailAddress] [nvarchar](510) NULL,
	[EmailAddressChecksum] [int] NULL,
	[PrivEmailAddress] [nvarchar](510) NULL,
	[PrivEmailAddressChecksum] [int] NULL
);
