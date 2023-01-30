CREATE TABLE [Party].[GDPR_RestrictionsLoaded](
	[PartyID] [int] NOT NULL,
	[FromDate] [datetime2](7) NULL,
	[FileName] [varchar](100) NOT NULL,
	[ActionDate] [datetime2](7) NOT NULL,
	[PhysicalFileRow] [int] NOT NULL,
	[EmailSent] [datetime2](7) NULL,
	[AuditItemID] [bigint] NOT NULL
) ON [PRIMARY]
GO