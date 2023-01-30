CREATE TABLE [SelectionOutput].[Base] (
    [VersionCode]                     [dbo].[VersionCode]             NULL,
    [SelectionTypeID]                 [dbo].[SelectionTypeID]         NULL,
    [Manufacturer]                    [dbo].[OrganisationName]        NULL,
    [ManufacturerPartyID]             [dbo].[PartyID]                 NOT NULL,
    [QuestionnaireVersion]            [dbo].[QuestionnaireVersion]    NULL,
    [CaseID]                          [dbo].[CaseID]                  NOT NULL,
    [CaseRejection]                   BIT                             NOT NULL,
    [Salutation]                      [dbo].[AddressingText]          NULL,
    [Title]                           [dbo].[Title]                   NULL,
    [FirstName]                       [dbo].[NameDetail]              NULL,
    [LastName]                        [dbo].[NameDetail]              NULL,
    [Addressee]                       [dbo].[AddressingText]          NULL,
    [OrganisationName]                [dbo].[OrganisationName]        NULL,
    [GenderID]                        [dbo].[GenderID]                NULL,
    [LanguageID]                      [dbo].[LanguageID]              NULL,
    [CountryID]                       [dbo].[CountryID]               NULL,
    [PartyID]                         [dbo].[PartyID]                 NULL,
    [EventTypeID]                     [dbo].[EventTypeID]             NOT NULL,
    [EventDate]                       DATETIME2 (7)                   NULL,
    [RegistrationNumber]              [dbo].[RegistrationNumber]      NULL,
    [ModelDescription]                VARCHAR(50)				      NULL,
    [VIN]                             [dbo].[VIN]                     NULL,
    [ModelRequirementID]              [dbo].[RequirementID]           NOT NULL,
    [DealerCode]                      [dbo].[DealerCode]              NULL,
    [DealerName]                      [dbo].[DealerName]              NULL,
    [PostalAddressContactMechanismID] [dbo].[ContactMechanismID]      NULL,
    [BuildingName]                    [dbo].[AddressText]             NULL,
    [SubStreet]                       [dbo].[AddressText]             NULL,
    [Street]                          [dbo].[AddressText]             NULL,
    [SubLocality]                     [dbo].[AddressText]             NULL,
    [Locality]                        [dbo].[AddressText]             NULL,
    [Town]                            [dbo].[AddressText]             NULL,
    [Region]                          [dbo].[AddressText]             NULL,
    [PostCode]                        [dbo].[Postcode]                NULL,
    [Country]                         [dbo].[Country]                 NULL,
    [EmailAddressContactMechanismID]  [dbo].[ContactMechanismID]      NULL,
    [EmailAddress]                    [dbo].[EmailAddress]            NULL,
    [LandPhone]                       [dbo].[ContactNumber]           NULL,
    [MobilePhone]                     [dbo].[ContactNumber]           NULL,
    [WorkPhone]                       [dbo].[ContactNumber]           NULL,
    [SelectionOutputPassword]         [dbo].[SelectionOutputPassword] NULL,
    [GDDDealerCode]                   NVARCHAR (20)                   NULL,
    [ReportingDealerPartyID]          INT                             NULL,
    [VariantID]                       SMALLINT                        NULL,
    [ModelVariant]                    VARCHAR (50)                    NULL,
    
    [BilingualFlag]					  BIT								NULL,			-- 18-10-2017 - BUG 14245
    [SalutationBilingual]             [dbo].[AddressingText]			NULL,			-- 18-10-2017 - BUG 14245
    [LanguageIDBilingual]             [dbo].[LanguageID]				NULL,			-- 18-10-2017 - BUG 14245
  
);




