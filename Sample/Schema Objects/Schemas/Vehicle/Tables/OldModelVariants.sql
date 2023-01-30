CREATE TABLE [Vehicle].[OldModelVariants] (
    [Manufacturer]        VARCHAR (20) NULL,
    [ManufacturerPartyID] INT          NOT NULL,
    [OldModelID]          SMALLINT     NOT NULL,
    [Model]               VARCHAR (50) NOT NULL,
    [OldVariantID]        SMALLINT     NULL,
    [Variant]             VARCHAR (50) NOT NULL,
    [NorthAmericaVariant] VARCHAR (50) NOT NULL
);
