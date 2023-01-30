CREATE TABLE [DealerManagement].[DEALERS_JLRCSP_UPDATE_Dealer10DigitCode]
(
	[IP_Dealer10DigitCodeChangeID] [int] IDENTITY(1,1) NOT NULL,
	[ID] [int] NULL,
	[OutletFunction] [nvarchar](25) NOT NULL,
	[Manufacturer] [dbo].[OrganisationName] NULL,
	[Market] [dbo].[Market] NOT NULL,
	[Dealer10DigitCode] [dbo].[Dealer10DigitCode] NOT NULL,
	[OutletCode] [dbo].[DealerCode] NULL,
	[IP_OutletPartyID] [dbo].[PartyID] NULL,
	[IP_SystemUser] [varchar](50) NOT NULL,
	[IP_AuditItemID] [dbo].[AuditItemID] NULL,
	[IP_DataValidated] [bit] NOT NULL DEFAULT 0,
	[IP_ValidationFailureReasons] [varchar](1000) NULL,
	[IP_ProcessedDate] [datetime] NULL
)
