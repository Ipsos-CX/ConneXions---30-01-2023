CREATE TABLE [ContactMechanism].[Countries] (
    [CountryID]         dbo.CountryID  IDENTITY(1,1) NOT NULL,
    [Country]       dbo.Country NOT NULL,
    [CountryShortName]  VARCHAR (100) NULL,
    [CountryInitialism] VARCHAR (20)  NULL,
    [ISOAlpha2]         CHAR (2)       NULL,
    [ISOAlpha3]         CHAR (3)       NULL,
    [NumericCode]       SMALLINT       NULL,
    [DefaultLanguageID] dbo.LanguageID  NULL,
    [InternationalDiallingCode] varchar(5) NULL
);

