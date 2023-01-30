CREATE TABLE [LostLeads].[CaseLostLeadStatuses]
(
	[CaseID] [dbo].[CaseID] NOT NULL,
	[EventID] [bigint] NOT NULL,
	[LeadStatusID] [int]  NULL,
	[SequenceID]	[int] NULL,
	[LoadedToConnexions] [datetime2](7) NULL,
	[DateAddedForOutput] [datetime2](7) NULL,
	[AddedByProcess] [varchar](200) NULL,
	[OutputDate] [datetime2](7) NULL,
	[OutputAgencyCode] NVARCHAR(50) NULL
)

