CREATE TABLE [OWAP].[RunTimeLog](
	[LogID] [int] IDENTITY(1,1) NOT NULL,
	[LogDateTime] [datetime2](7) NULL,
	[UserName] [nvarchar](100) NULL,
	[AuditID] [dbo].[AuditID] NULL,
	[UserPartyRoleID] [dbo].[PartyRoleID] NULL,
	[SessionID] [dbo].[SessionID] NULL,
	[LogStr] [nvarchar](2048) NULL
)
