CREATE TABLE [ParallelRun].[CustomerUpdate_EmailAddress](
	[PartyID] [int] NOT NULL,
	[CaseID] [int] NOT NULL,
	[EmailAddress] [nvarchar](510) NULL,
	[ContactMechanismPurposeType] [varchar](255) NULL,
	[ContactMechanismPurposeTypeID] [smallint] NULL,
	[ContactMechanismID] [int] NULL,
	[AuditID] [bigint] NOT NULL,
	[AuditItemID] [bigint] NOT NULL,
	[CasePartyCombinationValid] [bit] NOT NULL,
	[ParentAuditItemID] [bigint] NULL,
	[DateProcessed] [datetime2](7) NOT NULL
)