CREATE TABLE [Party].[IndustryClassifications] (
    [PartyTypeID] dbo.PartyTypeID NOT NULL,
    [PartyID]     dbo.PartyID      NOT NULL,
	[PartyExclusionCategoryID]  dbo.ExclusionCategoryID NULL		-- 09-12-2019 - BUG 16810
);

