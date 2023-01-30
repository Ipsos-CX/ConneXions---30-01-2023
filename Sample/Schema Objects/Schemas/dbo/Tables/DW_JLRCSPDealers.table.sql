CREATE TABLE [dbo].[DW_JLRCSPDealers] (
    [id]						INT IDENTITY (1, 1) NOT NULL,
    [Manufacturer]              dbo.OrganisationName NOT NULL,
    [SuperNationalRegion]       NVARCHAR(150) NULL,
    [Market]                    NVARCHAR(255) NOT NULL,
    [SubNationalTerritory]		NVARCHAR(255) NULL,
    [SubNationalRegion]         NVARCHAR(255) NULL,
    [CombinedDealer]            NVARCHAR(255) NULL,
    [CombinedDealerCode]        dbo.DealerCode  NULL,
    [TransferDealer]            dbo.DealerName NULL,
    [TransferDealerCode]        dbo.DealerCode  NULL,
    [Outlet]                    dbo.DealerName NULL,
    [OutletCode]                dbo.DealerCode  NULL,
    [OutletFunction]            NVARCHAR(25) NULL,
    [ManufacturerPartyID]       dbo.PartyID NOT NULL,
    [SuperNationalRegionPartyID]	dbo.PartyID NULL,
    [MarketPartyID]             dbo.PartyID NOT NULL,
    [SubNationalRegionPartyID]  dbo.PartyID NULL,
    [CombinedDealerPartyID]     dbo.PartyID NULL,
    [TransferPartyID]           dbo.PartyID NULL,
    [OutletPartyID]             dbo.PartyID NULL,
    [OutletLevelReport]         BIT NOT NULL,
    [OutletLevelWeb]            BIT NOT NULL,
    [OutletFunctionID]          dbo.RoleTypeID NULL,
    [OutletSiteCode]			dbo.DealerCode NULL,
    [FromDate]                  DATETIME2 NULL,
    [ThroughDate]               DATETIME2 NULL,
    [TransferDealerCode_GDD]	NVARCHAR(20) NULL,
	[OutletCode_GDD]			NVARCHAR(20) NULL,
	[PAGCode]					dbo.PAGCode  NULL,
	[PAGName]					dbo.PAGName NULL,
	[BusinessRegion]			NVARCHAR(150) NULL,
	[RockarDealer]				BIT NOT NULL,
	[BilingualSelectionOutput]	BIT NULL,						-- 18-10-2017 - BUG 14245
	[SVODealer]					BIT	NOT NULL,					-- 2017-11-11 BUG 14365
	[FleetDealer]				BIT	NOT NULL,					-- 2017-11-11 BUG 14365
	[InterCompanyOwnUseDealer]	BIT	NOT NULL,					-- 2017-11-16 BUG 14347
	[Dealer10DigitCode]			dbo.Dealer10DigitCode NULL,		-- 2020-01-17 BUG 16793
	[ChinaDMSRetailerCode]      NVARCHAR(100) NULL,
	[ReportingRetailerName]		NVARCHAR (150) NULL,			-- TASK 643
	[AlternateMarketEventX]		NVARCHAR (255) NULL,			-- TASK 692
    [ApprovedUser]				NVARCHAR(10) NULL,			-- TASK 751
	[GoogleCID]					NVARCHAR (255) NULL			-- TASK 786
	
	);				

