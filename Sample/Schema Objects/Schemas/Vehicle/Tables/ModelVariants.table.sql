CREATE TABLE [Vehicle].[ModelVariants] (
    [VariantID]      SMALLINT     NULL,
    [ManufacturerPartyID] INT          NOT NULL,
    [ModelID]             SMALLINT     NOT NULL,
    [Variant]             VARCHAR (50) NOT NULL,
    [NorthAmericaVariant] VARCHAR (50) NOT NULL
);

