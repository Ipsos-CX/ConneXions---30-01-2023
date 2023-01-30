CREATE TABLE [ParallelRun].[CustomerUpdate_Organisation](
	[PartyID] [int] NOT NULL,
	[CaseID] [int] NOT NULL,
	[OrganisationName] [nvarchar](510) NULL,
	[AuditID] [bigint] NOT NULL,
	[AuditItemID] [bigint] NOT NULL,
	[ParentAuditItemID] [bigint] NULL,
	[CasePartyCombinationValid] [bit] NOT NULL,
	[OrganisationPartyID] [int] NULL,
	[PartyTypeFlag] [varchar](10) NULL,
	[DateProcessed] [datetime2](7) NOT NULL
)