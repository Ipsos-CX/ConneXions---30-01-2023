CREATE TABLE [Warranty].[Countries] (
    [ID]           INT          IDENTITY (1, 1) NOT NULL,
    [Country]  dbo.Country NULL,
    [ISOCode]      CHAR(3)     NULL,
    [WarrantyCode] dbo.CountryID          NULL,
    [CountryID] dbo.CountryID          NULL
);

