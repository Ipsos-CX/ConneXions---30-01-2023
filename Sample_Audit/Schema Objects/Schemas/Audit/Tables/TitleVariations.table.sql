CREATE TABLE [Audit].[TitleVariations] (
    [AuditItemID] dbo.AuditItemID NOT NULL,
    [TitleVariationID] INT NOT NULL,
    [TitleID] dbo.TitleID NOT NULL,
    [TitleVariation] dbo.Title NOT NULL
);

