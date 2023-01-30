CREATE TABLE [Stage].[Removed_Records_Staging_Tables]
--BUG 15311
(
	
	[AuditID] [bigint] NOT NULL,
	[FileName] [varchar](100) NOT NULL,
	[ActionDate] [datetime2](7) NOT NULL,
	[PhysicalFileRow] [int] NOT NULL,
	[VIN] [nvarchar](50) NULL,
	[Misaligned_ModelYear] nvarchar(400) NULL,
	[EmailSent] [datetime2](7) NULL
	
)
