CREATE TABLE [dbo].[ChinaVINsReport]
(
	[VIN] [nvarchar](50) NOT NULL,
	[ModelID] [varchar](10) NULL,
	[ModelDescription] [varchar](50) NULL,
	[ModelVariantID] [smallint] NULL,
	[Variant] [varchar](50) NULL,
	[EV_FLAG] [varchar](4) NULL,
	[ReportDate] [datetime] NULL,			--BUG 18109
	[SVOType] [int] NULL,
	[ModelCode] [varchar](10) NULL,			--18304 (CHANGED TO VARHAR - PART OF TASK 665)
    [ModelYear] [INT] NULL,					-- 18304 
	[AuditID] [bigint] NULL,				-- TASK 824
	[AuditItemID] [bigint] NULL,			-- TASK 824
	[VehicleParentAuditItemID] [int] NULL,	-- TASK 824
	[AlreadyLoaded] [int] NULL,				-- TASK 824
	[SubBrand] [varchar] (100)				-- TASK 1017	
)
