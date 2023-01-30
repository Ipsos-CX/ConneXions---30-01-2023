CREATE TABLE [Lookup].[StreetNameVariances] (
    [StreetNameVarianceID] INT            IDENTITY (1, 1) NOT NULL,
    [StreetNameID]         INT            NULL,
    [StreetNameVariance]   NVARCHAR (200) NULL
);

