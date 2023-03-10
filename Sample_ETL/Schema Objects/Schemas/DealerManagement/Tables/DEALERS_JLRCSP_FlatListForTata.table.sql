CREATE TABLE [DealerManagement].[DEALERS_JLRCSP_FlatListForTata] (
    [Manufacturer]             NVARCHAR (255) NOT NULL,
    [SuperNationalRegion]      NVARCHAR (255) NULL,
    [Market]                   NVARCHAR (255) NOT NULL,
    [SubNationalRegion]        NVARCHAR (255) NULL,
    [DealerGroup]              NVARCHAR (255) NULL,
    [DealerName]               NVARCHAR (255) NULL,
    [DealerCode]               NVARCHAR (50)  NULL,
    [ManufacturerDealerCode]   NVARCHAR (50)  NULL,
    [OutletPartyID]            INT            NULL,
    [OutletFunction]           NVARCHAR (25)  NULL,
    [OutletFunctionID]         SMALLINT       NULL,
    [FromDate]                 DATETIME       NULL,
    [ThroughDate]              DATETIME       NULL,
    [TransferDealerName]       NVARCHAR (255) NULL,
    [TransferDealerCode]       NVARCHAR (10)  NULL,
    [TransferPartyID]          INT            NULL,
    [DealerCode_1]             NVARCHAR (50)  NULL,
    [DealerCode_2]             NVARCHAR (50)  NULL,
    [DealerCode_3]             NVARCHAR (50)  NULL,
    [DealerCode_4]             NVARCHAR (50)  NULL,
    [DealerCode_5]             NVARCHAR (50)  NULL,
    [ManufacturerDealerCode_1] NVARCHAR (50)  NULL,
    [ManufacturerDealerCode_2] NVARCHAR (50)  NULL,
    [ManufacturerDealerCode_3] NVARCHAR (50)  NULL,
    [ManufacturerDealerCode_4] NVARCHAR (50)  NULL,
    [ManufacturerDealerCode_5] NVARCHAR (50)  NULL,
    [Town]                     NVARCHAR (100) NULL
);

