CREATE TABLE [ParallelRun].[CustomerUpdate_Person](
	[PartyID] [int] NOT NULL,
	[CaseID] [int] NOT NULL,
	[Title] [nvarchar](200) NULL,
	[FirstName] [nvarchar](100) NULL,
	[LastName] [nvarchar](100) NULL,
	[SecondLastName] [nvarchar](100) NULL,
	[AuditID] [bigint] NOT NULL,
	[AuditItemID] [bigint] NOT NULL,
	[ParentAuditItemID] [bigint] NULL,
	[TitleID] [smallint] NULL,
	[CasePartyCombinationValid] [bit] NOT NULL,
	[DateProcessed] [datetime2](7) NOT NULL
)