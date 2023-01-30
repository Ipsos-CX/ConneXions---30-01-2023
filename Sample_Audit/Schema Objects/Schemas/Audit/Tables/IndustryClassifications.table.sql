CREATE TABLE [Audit].[IndustryClassifications] (
    [AuditItemID] dbo.AuditItemID   NOT NULL,
    [PartyTypeID] dbo.PartyTypeID NOT NULL,
    [PartyID]     dbo.PartyID      NOT NULL,
    [FromDate]    DATETIME2 NOT NULL,
	[PartyExclusionCategoryID]  dbo.ExclusionCategoryID NOT NULL		-- 09-12-2019 - BUG 16810
);

