CREATE TABLE [ParallelRun].[Comparisons_CustomerUpdate_EmailAddress](
	[PartyID] [int] NOT NULL,
	[CaseID] [int] NOT NULL,

	[RemoteAuditID] [bigint] NOT NULL,
	[LocalAuditID] [bigint] NOT NULL,
	[RemoteAuditItemID] [bigint] NOT NULL,
	[LocalAuditItemID] [bigint] NOT NULL,

	[Mismmatch_EmailAddress] INT NOT NULL,
	[Mismmatch_ContactMechanismPurposeType]  INT NOT NULL,
	[Mismmatch_ContactMechanismPurposeTypeID]  INT NOT NULL,
	[Mismmatch_ContactMechanismID]  INT NOT NULL,
	[Mismmatch_CasePartyCombinationValid]  INT NOT NULL,
	[Mismmatch_ParentAuditItemID]  INT NOT NULL,
	[Mismmatch_DateProcessed]  INT NOT NULL
)