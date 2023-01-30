CREATE TABLE [DealerManagement].[DEALERS_JLRCSP_UPDATE_Town] (
    [IP_TownChangeID]             INT                        IDENTITY (1, 1) NOT NULL,
    [ID]                          INT                        NULL,
    [Manufacturer]                [dbo].[OrganisationName]   NULL,
    [Market]                      [dbo].[Market]             NOT NULL,
    [Town]                        [dbo].[AddressText]        NOT NULL,
    [NewTown]                     [dbo].[AddressText]        NOT NULL,
    [OutletCode]                  [dbo].[DealerCode]         NULL,
    [IP_ContactMechanismID]       [dbo].[ContactMechanismID] NULL,
    [IP_OutletPartyID]            [dbo].[PartyID]            NULL,
    [IP_SystemUser]               VARCHAR (50)               NOT NULL,
    [IP_AuditItemID]              [dbo].[AuditItemID]        NULL,
    [IP_DataValidated]            BIT                        NOT NULL,
    [IP_ValidationFailureReasons] VARCHAR (1000)             NULL,
    [IP_ProcessedDate]            DATETIME                   NULL
);

