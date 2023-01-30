CREATE TABLE [Lookup].[CompanyTypeWordVariances] (
    [CompanyTypeVarianceID] INT            IDENTITY (1, 1) NOT NULL,
    [CompanyTypeID]         INT            NULL,
    [CompanyTypeVariance]   NVARCHAR (400) NULL
);

