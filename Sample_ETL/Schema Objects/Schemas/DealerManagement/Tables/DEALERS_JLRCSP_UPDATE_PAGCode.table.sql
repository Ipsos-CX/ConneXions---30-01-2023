CREATE TABLE [DealerManagement].[DEALERS_JLRCSP_UPDATE_PAGCode]
(
	[IP_PAGCodeChangeID] [int] IDENTITY(1,1) NOT NULL,
	[ID] [int] NULL,
	[OutletFunction] [nvarchar](25) NOT NULL,
	[Manufacturer] [dbo].[OrganisationName] NULL,
	[Market] [dbo].[Market] NOT NULL,
	[PAGCode] [dbo].[PAGCode] NOT NULL,
	[PAGName] [dbo].[PAGName] NOT NULL,
	[OutletCode] [dbo].[DealerCode] NULL,
	[IP_OutletPartyID] [dbo].[PartyID] NULL,
	[IP_SystemUser] [varchar](50) NOT NULL,
	[IP_AuditItemID] [dbo].[AuditItemID] NULL,
	[IP_DataValidated] [bit] NOT NULL,
	[IP_ValidationFailureReasons] [varchar](1000) NULL,
	[IP_ProcessedDate] [datetime] NULL
)
