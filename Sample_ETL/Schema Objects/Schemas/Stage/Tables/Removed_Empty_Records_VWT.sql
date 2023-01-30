CREATE TABLE [Stage].[Removed_Empty_Records_VWT]
(
	[AuditID] [bigint] NOT NULL, --BUG 15518
	[FileName] [varchar](100) NOT NULL,
	[ActionDate] [datetime2](7) NOT NULL,
	[PhysicalFileRow] [int] NOT NULL,
	[EmailSent] [datetime2](7) NULL
)
