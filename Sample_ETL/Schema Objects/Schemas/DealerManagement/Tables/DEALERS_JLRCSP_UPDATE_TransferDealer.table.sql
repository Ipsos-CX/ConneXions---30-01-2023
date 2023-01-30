CREATE TABLE [DealerManagement].[DEALERS_JLRCSP_UPDATE_TransferDealer] (
    [IP_TransferDealerChangeID]   INT                      IDENTITY (1, 1) NOT NULL,
    [ID]                          INT                      NULL,
    [OutletFunction]              NVARCHAR (25)            NULL,
    [Manufacturer]                [dbo].[OrganisationName] NULL,
    [Market]                      [dbo].[Market]           NOT NULL,
    [OutletCode]                  [dbo].[DealerCode]       NULL,
    [IP_OutletPartyID]            [dbo].[PartyID]          DEFAULT ((0)) NULL,
    [TransferOutletCode]          [dbo].[DealerCode]       NULL,
    [IP_TransferOutlet]           [dbo].[OrganisationName] NULL,
    [IP_TransferOutletPartyID]    [dbo].[PartyID]          DEFAULT ((0)) NULL,
    [IP_SystemUser]               VARCHAR (50)             NULL,
    [IP_AuditItemID]              [dbo].[AuditItemID]      NULL,
    [IP_DataValidated]            BIT                      NOT NULL,
    [IP_ValidationFailureReasons] VARCHAR (1000)           NULL,
    [IP_ProcessedDate]            DATETIME                 NULL
);

