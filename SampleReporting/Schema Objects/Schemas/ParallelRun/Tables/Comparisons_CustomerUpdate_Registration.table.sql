CREATE TABLE [ParallelRun].[Comparisons_CustomerUpdate_Registration](
	[PartyID] [int] NOT NULL,
	[CaseID] [int] NOT NULL,

	[RemoteAuditID] [bigint] NOT NULL,
	[LocalAuditID] [bigint] NOT NULL,
	[RemoteAuditItemID] [bigint] NOT NULL,
	[LocalAuditItemID] [bigint] NOT NULL,

	[Mismatch_RegNumber] INT NOT NULL,
	[Mismatch_ParentAuditItemID] INT NOT NULL,
	[Mismatch_EventID]  INT NOT NULL,
	[Mismatch_VehicleRegistrationEventMatch] INT NOT NULL,
	[Mismatch_RegistrationID] INT NOT NULL,
	[Mismatch_DateProcessed] INT NOT NULL
) 