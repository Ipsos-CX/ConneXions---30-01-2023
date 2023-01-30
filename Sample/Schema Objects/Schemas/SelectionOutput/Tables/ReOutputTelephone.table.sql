CREATE TABLE [SelectionOutput].[ReOutputTelephone] (
    [VIN]                     [dbo].[VIN]                     NULL,
    [DealerCode]              [dbo].[DealerCode]              NULL,
    [ModelDesc]               [dbo].[ModelDescription]        NULL,
    [CoName]                  [dbo].[OrganisationName]        NULL,
    [Add1]                    [dbo].[AddressText]             NULL,
    [Add2]                    [dbo].[AddressText]             NULL,
    [Add3]                    [dbo].[AddressText]             NULL,
    [Add4]                    [dbo].[AddressText]             NULL,
    [Add5]                    [dbo].[AddressText]             NULL,
    [LandPhone]               [dbo].[ContactNumber]           NULL,
    [WorkPhone]               [dbo].[ContactNumber]           NULL,
    [MobilePhone]             [dbo].[ContactNumber]           NULL,
    [PartyID]                 [dbo].[PartyID]                 NULL,
    [CaseID]                  [dbo].[CaseID]                  NULL,
    [DateOutput]              DATETIME2 (7)                   NULL,
    [JLR]                     INT                             NULL,
    [EventTypeID]             [dbo].[EventTypeID]             NULL,
    [EventDate]               DATETIME2 (7)                   NULL,
    [RegNumber]               [dbo].[RegistrationNumber]      NULL,
    [RegDate]                 NVARCHAR (10)                   NULL,
    [LocalName]               [dbo].[OrganisationName]        NULL,
    [BMQID]                   INT                             NOT NULL,
    [SelectionOutputPassword] [dbo].[SelectionOutputPassword] NULL,
    [GDDDealerCode]           NVARCHAR (20)                   NULL,
    [ReportingDealerPartyID]  INT                             NULL,
    [VariantID]               SMALLINT                        NULL,
    [ModelVariant]            VARCHAR (50)                    NULL
);



