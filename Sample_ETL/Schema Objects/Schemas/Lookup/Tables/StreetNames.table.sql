CREATE TABLE [Lookup].[StreetNames] (
    [StreetNameID] INT            IDENTITY (1, 1) NOT NULL,
    [StreetName]   NVARCHAR (200) NULL,
    [CountryID]    dbo.CountryID       NULL
);

