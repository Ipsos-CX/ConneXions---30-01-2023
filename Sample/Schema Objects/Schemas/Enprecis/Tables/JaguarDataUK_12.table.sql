CREATE TABLE [Enprecis].[JaguarDataUK_12M] (
    [SalesRecordType]       VARCHAR (14)   NOT NULL,
    [Country]               NVARCHAR (200) NULL,
    [VIN]                   NVARCHAR (50)  NOT NULL,
    [CustomerFirstName]     NVARCHAR (100) NULL,
    [CustomerLastName]      NVARCHAR (100) NULL,
    [CustomerAddressOne]    NVARCHAR (441) NULL,
    [CustomerAddressTwo]    NVARCHAR (400) NULL,
    [CustomerCity]          NVARCHAR (400) NULL,
    [CustomerState]         NVARCHAR (400) NULL,
    [CustomerZip]           NVARCHAR (60)  NULL,
    [CustomersEmailAddress] NVARCHAR (510) NULL,
    [CustomerPhoneOne]      NVARCHAR (70)  NULL,
    [CustomerPhoneTwo]      NVARCHAR (70)  NULL,
    [ModelType]             NVARCHAR (255) NOT NULL,
    [ModelYear]             NVARCHAR (800) NULL,
    [DealerName]            NVARCHAR (150) NULL,
    [DealerCode]            NVARCHAR (20)  NULL,
    [SalesRegion]           NVARCHAR (200) NOT NULL,
    [SalesDistrict]         VARCHAR (1)    NOT NULL,
    [SalesDate]             DATETIME       NULL,
    [RDRDate]               DATETIME       NULL,
    [ManufacturingDate]     VARCHAR (1)    NOT NULL,
    [TrimLevel]             VARCHAR (1)    NOT NULL,
    [ExteriorColor]         VARCHAR (1)    NOT NULL,
    [InteriorColor]         VARCHAR (1)    NOT NULL,
    [Transmission]          VARCHAR (1)    NOT NULL,
    [EngineType]            VARCHAR (1)    NOT NULL,
    [Caseid]                BIGINT         NOT NULL,
    [CustomerTitle]         NVARCHAR (200) NULL,
    [RegistrationPlate]     NVARCHAR (100) NULL,
    [Salutation]            NVARCHAR (200) NULL,
    [SecondSurname]         NVARCHAR (100) NULL,
    [OwnershipCycle]        TINYINT        NULL
);


