CREATE TABLE [DealerManagement].[DEALERS_JLRCSP_UPDATE_OutletName] (
    [IP_OutletNameChangeID]       INT                      IDENTITY (1, 1) NOT NULL,
    [ID]                          INT                      NULL,
    [OutletFunction]              NVARCHAR (25)            NOT NULL,
    [Manufacturer]                [dbo].[OrganisationName] NULL,
    [Market]                      [dbo].[Market]           NOT NULL,
    [OutletName]                  [dbo].[OrganisationName] NOT NULL,
    [OutletName_Short]            [dbo].[OrganisationName] NOT NULL,
    [OutletName_NativeLanguage]   [dbo].[OrganisationName] NULL,
    [OutletCode]                  [dbo].[DealerCode]       NULL,
    [IP_OutletPartyID]            [dbo].[PartyID]          NULL,
    [IP_SystemUser]               VARCHAR (50)             NOT NULL,
    [IP_AuditItemID]              [dbo].[AuditItemID]      NULL,
    [IP_DataValidated]            BIT                      NOT NULL,
    [IP_ValidationFailureReasons] VARCHAR (1000)           NULL,
    [IP_ProcessedDate]            DATETIME                 NULL
);

