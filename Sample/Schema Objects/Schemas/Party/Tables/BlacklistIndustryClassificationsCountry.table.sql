CREATE TABLE [Party].[BlacklistIndustryClassificationsCountry] (
    [BlacklistStringID] dbo.BlacklistStringID      NOT NULL,
    [CountryID]			dbo.CountryID	NOT NULL,
    [FromDate]          DATETIME2 NOT NULL,
    [ThroughDate]		DATETIME2 NULL
);

