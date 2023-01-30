CREATE TABLE [dbo].[Removed_Records_Prevent_PartialLoad]
(
	[AuditID] [bigint] NOT NULL,
	[FileName] [varchar](100) NOT NULL,
	[ActionDate] [datetime2](7) NOT NULL,
	[PhysicalFileRow] [int] NOT NULL,
	[VIN] [nvarchar](50) NULL,
	[CountryCode] [nvarchar](10) NULL,
	[RemovalReason] [varchar](200) NOT NULL,
	[EmailSent] [datetime2](7) NULL
)
