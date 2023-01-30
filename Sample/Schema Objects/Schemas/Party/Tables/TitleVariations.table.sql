CREATE TABLE [Party].[TitleVariations] (
    [TitleVariationID] INT IDENTITY (1, 1) NOT NULL,
    [TitleID] dbo.TitleID NOT NULL,
    [TitleVariation] dbo.Title NOT NULL
);

