CREATE TABLE [Vehicle].[NewModelVariants] (
    [VariantID]      SMALLINT     IDENTITY(1,1) NOT NULL,
    [ManufacturerPartyID] INT          NOT NULL,
    [ModelID]             SMALLINT     NOT NULL,
    [Variant]             VARCHAR (50) NULL,
    [NorthAmericaVariant] VARCHAR (50) NULL
);