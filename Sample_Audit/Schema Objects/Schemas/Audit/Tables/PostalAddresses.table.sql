CREATE TABLE [Audit].[PostalAddresses] (
    [AuditItemID]            [dbo].[AuditItemID]        NOT NULL,
    [ContactMechanismID]     [dbo].[ContactMechanismID] NOT NULL,
    [BuildingName]           [dbo].[AddressText]        NULL,
    [SubStreetAndNumberOrig] [dbo].[AddressText]        NULL,
    [SubStreetOrig]          [dbo].[AddressText]        NULL,
    [SubStreetNumber]        [dbo].[AddressNumberText]  NULL,
    [SubStreet]              [dbo].[AddressText]        NULL,
    [StreetAndNumberOrig]    [dbo].[AddressText]        NULL,
    [StreetOrig]             [dbo].[AddressText]        NULL,
    [StreetNumber]           [dbo].[AddressNumberText]  NULL,
    [Street]                 [dbo].[AddressText]        NULL,
    [SubLocality]            [dbo].[AddressText]        NULL,
    [Locality]               [dbo].[AddressText]        NULL,
    [Town]                   [dbo].[AddressText]        NULL,
    [Region]                 [dbo].[AddressText]        NULL,
    [PostCode]               [dbo].[Postcode]           NULL,
    [CountryID]              [dbo].[CountryID]          NOT NULL,
    [AddressChecksum]        INT                        NULL
);



