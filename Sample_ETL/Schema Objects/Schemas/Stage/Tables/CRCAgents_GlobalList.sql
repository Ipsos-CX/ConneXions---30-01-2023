CREATE TABLE [Stage].[CRCAgents_GlobalList]
(
	[ID]                     INT				 IDENTITY (1, 1) NOT NULL,
    [AuditID]                [dbo].[AuditID]     NULL,
    [AuditItemID]            [dbo].[AuditItemID] NULL,
    [ParentAuditItemID]      [dbo].[AuditItemID] NULL,
    [CDSID]                  [dbo].[NameDetail]  NOT NULL,
    [FirstName]              [dbo].[NameDetail]  NOT NULL,
    [Surname]                [dbo].[NameDetail]  NOT NULL,
    [DisplayOnQuestionnaire] [dbo].[NameDetail]  NOT NULL,
    [DisplayOnWebsite]       [dbo].[NameDetail]  NULL,
    [FullName]               [dbo].[NameDetail]  NOT NULL,
    [Market]                 [dbo].[Country]     NOT NULL,
    [MarketCode]             VARCHAR (50)        NULL, 
    [IP_DataErrorDescription] VARCHAR(1000) NULL
)
