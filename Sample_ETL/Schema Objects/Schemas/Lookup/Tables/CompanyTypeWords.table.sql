CREATE TABLE [Lookup].[CompanyTypeWords] (
    [CompanyTypeID] INT IDENTITY (1, 1) NOT NULL,
    [CountryID]     dbo.CountryID  NULL,
    [CompanyType]   NVARCHAR (400) NULL
)