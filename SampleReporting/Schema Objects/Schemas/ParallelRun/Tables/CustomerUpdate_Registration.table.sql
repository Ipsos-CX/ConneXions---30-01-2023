CREATE TABLE [ParallelRun].[CustomerUpdate_Registration](
	[PartyID] [int] NOT NULL,
	[CaseID] [int] NOT NULL,
	[RegNumber] [nvarchar](100) NULL,
	[AuditID] [bigint] NOT NULL,
	[AuditItemID] [bigint] NOT NULL,
	[ParentAuditItemID] [bigint] NULL,
	[EventID] [bigint] NULL,
	[VehicleRegistrationEventMatch] [bit] NULL,
	[RegistrationID] [int] NULL,
	[DateProcessed] [datetime2](7) NOT NULL
) 