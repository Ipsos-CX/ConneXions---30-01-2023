CREATE TABLE [Party].[BlacklistIndustryClassifications] (
    [BlacklistStringID] dbo.BlacklistStringID      NOT NULL,
    [PartyTypeID]       dbo.PartyTypeID NOT NULL,
	[PartyExclusionCategoryID]  dbo.ExclusionCategoryID NOT NULL,		-- 09-12-2019 - BUG 16810
    [FromDate]          DATETIME2 NOT NULL
);

