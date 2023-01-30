
CREATE TABLE  [Stage].[Combined_DDW_Service] (
    [ID]                        INT            IDENTITY (1, 1) NOT NULL,
    [AuditID]                   dbo.AuditID    NULL,
    [PhysicalRowID]             INT            NULL,
	[Region]					dbo.LoadText NULL,
	[Country]					dbo.LoadText NULL,
	[RepairingDealerCode]		dbo.LoadText NULL,
	[RONumber]					dbo.LoadText NULL,
	[ROSEQNumber]				dbo.LoadText NULL,
	[ClaimNo]					dbo.LoadText NULL,
	[VIN]						dbo.LoadText NULL,
	[RepairDate]				dbo.LoadText NULL,
	[ClaimStatus]				dbo.LoadText NULL,
	[WIAA02_CLAIM_TYPE_C]		dbo.LoadText NULL,
	[CoverageCategory]			dbo.LoadText NULL,
	[ProgramCode]				dbo.LoadText NULL,
	[WIAA02_TOTAL_LABOR_A]		dbo.LoadText NULL,
    [ConvertedRepairDate]		DATETIME2    NULL
);

