CREATE TABLE [ParallelRun].[Comparisons_CustomerUpdate_Organisation](
	[PartyID] [int] NOT NULL,
	[CaseID] [int] NOT NULL,

	[RemoteAuditID] [bigint] NOT NULL,
	[LocalAuditID] [bigint] NOT NULL,
	[RemoteAuditItemID] [bigint] NOT NULL,
	[LocalAuditItemID] [bigint] NOT NULL,

	[Mismmatch_OrganisationName]			INT NOT NULL,
	[Mismmatch_ParentAuditItemID]			INT NOT NULL,
	[Mismmatch_CasePartyCombinationValid] INT NOT NULL,
	[Mismmatch_OrganisationPartyID]	INT NOT NULL,
	[Mismmatch_PartyTypeFlag]			INT NOT NULL,
	[Mismmatch_DateProcessed]			INT NOT NULL

)