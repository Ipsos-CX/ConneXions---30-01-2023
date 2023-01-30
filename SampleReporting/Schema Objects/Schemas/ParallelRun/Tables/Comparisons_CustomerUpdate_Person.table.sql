CREATE TABLE [ParallelRun].[Comparisons_CustomerUpdate_Person](
	[PartyID] [int] NOT NULL,
	[CaseID] [int] NOT NULL,

	[RemoteAuditID] [bigint] NOT NULL,
	[LocalAuditID] [bigint] NOT NULL,
	[RemoteAuditItemID] [bigint] NOT NULL,
	[LocalAuditItemID] [bigint] NOT NULL,

	[Mismatch_Title] INT NOT NULL,
	[Mismatch_FirstName] INT NOT NULL,
	[Mismatch_LastName]  INT NOT NULL,
	[Mismatch_SecondLastName] INT NOT NULL,
	[Mismatch_ParentAuditItemID] INT NOT NULL,
	[Mismatch_TitleID] INT NOT NULL,
	[Mismatch_CasePartyCombinationValid]  INT NOT NULL,
	[Mismatch_DateProcessed]  INT NOT NULL
)