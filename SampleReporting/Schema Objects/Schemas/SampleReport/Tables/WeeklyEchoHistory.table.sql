CREATE TABLE [SampleReport].[WeeklyEchoHistory]
(
AuditItemId bigint not null,
AuditId bigint not null,
ReportDate datetime not null,
[EventDateTooYoung] [int] NOT NULL,
[RecontactPeriod] [int] NOT NULL,
[UncodedDealer] [int] NOT NULL,
[EventNonSolicitation] [int] NOT NULL,
[PostalSuppression] [int] NOT NULL,
[EmailSuppression] [int] NOT NULL,
[UnmatchedModel] [int] NOT NULL,
[PartyNonSolicitation] [int] NOT NULL,
[PartySuppression] [bigint] NOT NULL,
[PhoneSuppression] [int] NOT NULL,
[CaseOutputType] [varchar](100) NOT NULL,
[UsebleFlag] [int] NULL,
[SentFlag] [INT] NULL,
[CaseID] [INT] NULL,
[RespondedFlag] [INT] NULL,
[ClosureDate] datetime NULL,
[PreviousEventBounceBack] [INT] NULL,
[EventAlreadySelected] [INT] NULL,
[HardBounce] [INT] NULL,
[SoftBounce] [INT] NULL,
[BouncebackFlag] [INT] NULL,
[ManualRejectionFlag] [INT] NULL

 


)
