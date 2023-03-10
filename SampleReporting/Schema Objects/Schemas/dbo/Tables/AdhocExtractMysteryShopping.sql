CREATE TABLE [dbo].[AdhocExtractMysteryShopping] (
    [PartyID]            INT            NULL,
    [CaseID]             INT            NULL,
    [VIN]                NVARCHAR (50)  NOT NULL,
    [EventDate]          DATETIME2 (7)  NULL,
    [ModelDescription]   VARCHAR (20)   NOT NULL,
    [RegistrationNumber] NVARCHAR (100) NULL,
    [Title]              NVARCHAR (200) NULL,
    [FirstName]          NVARCHAR (100) NULL,
    [LastName]           NVARCHAR (100) NULL,
    [SecondLastName]     NVARCHAR (100) NULL,
    [OrganisationName]   NVARCHAR (255) NULL,
    [BuildingName]       NVARCHAR (255) NULL,
    [SubStreet]          NVARCHAR (255) NULL,
    [StreetNumber]       NVARCHAR (40)  NULL,
    [Street]             NVARCHAR (255) NULL,
    [SubLocality]        NVARCHAR (255) NULL,
    [Town]               NVARCHAR (255) NULL,
    [Region]             NVARCHAR (255) NULL,
    [PostCode]           NVARCHAR (60)  NULL,
    [CountryID]          SMALLINT       NULL,
    [DealerName]         NVARCHAR (150) NULL,
    [DealerCode]         NVARCHAR (20)  NULL,
    [MobileID]           VARCHAR (200)  NULL,
    [WorklandlineID]     VARCHAR (200)  NULL,
    [LandlineID]         VARCHAR (200)  NULL,
    [EmailAddress]       NVARCHAR (255) NULL
);

