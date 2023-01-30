﻿CREATE TABLE [DealerManagement].[DEALERS_JLRCSP_UPDATE_OutletCode] (
    [IP_OutletCodeChangeID]       INT                      IDENTITY (1, 1) NOT NULL,
    [ID]                          INT                      NULL,
    [OutletFunction]              NVARCHAR (25)            NULL,
    [Manufacturer]                [dbo].[OrganisationName] NULL,
    [Market]                      [dbo].[Market]           NOT NULL,
    [IP_OutletPartyID]            [dbo].[PartyID]          DEFAULT ((0)) NULL,
    [OutletCode]                  [dbo].[DealerCode]       NULL,
    [NewOutletCode]               [dbo].[DealerCode]       NULL,
    [IP_SystemUser]               VARCHAR (50)             NULL,
    [IP_AuditItemID]              [dbo].[AuditItemID]      NULL,
    [IP_DataValidated]            BIT                      DEFAULT ((0)) NOT NULL,
    [IP_ValidationFailureReasons] VARCHAR (1000)           NULL,
    [IP_ProcessedDate]            DATETIME                 NULL
);

