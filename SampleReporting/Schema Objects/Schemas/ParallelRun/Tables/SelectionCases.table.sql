CREATE TABLE [ParallelRun].[SelectionCases](
	[RequirementID] [int] NOT NULL,
	[CaseID] [int] NOT NULL,
	[CaseStatusTypeID] [tinyint] NULL,
	[CreationDate] [datetime2](7) NULL,
	[ClosureDate] [datetime2](7) NULL,
	[OnlineExpiryDate] [datetime2](7) NULL,
	[SelectionOutputPassword] [varchar](10) NULL,
	[AnonymityDealer] [bit] NULL,
	[AnonymityManufacturer] [bit] NULL
) 