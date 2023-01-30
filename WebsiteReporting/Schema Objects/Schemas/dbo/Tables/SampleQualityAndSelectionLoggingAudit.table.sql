CREATE TABLE [dbo].[SampleQualityAndSelectionLoggingAudit] (
	[AuditTimestamp]					 DATETIME2 (7)              NOT NULL,
	
    [LoadedDate]                         DATETIME2 (7)              NOT NULL,
    [AuditID]                            [dbo].[AuditID]            NOT NULL,
    [AuditItemID]                        [dbo].[AuditItemID]        NOT NULL,
    [PhysicalFileRow]                    INT                        NOT NULL,
    [ManufacturerID]                     [dbo].[PartyID]            NULL,
    [SampleSupplierPartyID]              [dbo].[PartyID]            NULL,
    [MatchedODSPartyID]                  [dbo].[PartyID]            NOT NULL,
    [PersonParentAuditItemID]            [dbo].[AuditItemID]        NULL,
    [MatchedODSPersonID]                 [dbo].[PartyID]            NOT NULL,
    [LanguageID]                         [dbo].[LanguageID]         NOT NULL,
    [PartySuppression]                   BIT                        NOT NULL,
    [OrganisationParentAuditItemID]      [dbo].[AuditItemID]        NULL,
    [MatchedODSOrganisationID]           [dbo].[PartyID]            NOT NULL,
    [AddressParentAuditItemID]           [dbo].[AuditItemID]        NULL,
    [MatchedODSAddressID]                [dbo].[ContactMechanismID] NOT NULL,
    [CountryID]                          [dbo].[CountryID]          NULL,
    [PostalSuppression]                  BIT                        NOT NULL,
    [AddressChecksum]                    BIGINT                     NULL,
    [MatchedODSTelID]                    [dbo].[ContactMechanismID] NULL,
    [MatchedODSPrivTelID]                [dbo].[ContactMechanismID] NULL,
    [MatchedODSBusTelID]                 [dbo].[ContactMechanismID] NULL,
    [MatchedODSMobileTelID]              [dbo].[ContactMechanismID] NULL,
    [MatchedODSPrivMobileTelID]          [dbo].[ContactMechanismID] NULL,
    [MatchedODSEmailAddressID]           [dbo].[ContactMechanismID] NULL,
    [MatchedODSPrivEmailAddressID]       [dbo].[ContactMechanismID] NULL,
    [EmailSuppression]                   BIT                        NOT NULL,
    [VehicleParentAuditItemID]           [dbo].[AuditItemID]        NULL,
    [MatchedODSVehicleID]                [dbo].[VehicleID]          NOT NULL,
    [ODSRegistrationID]                  [dbo].[RegistrationID]     NULL,
    [MatchedODSModelID]                  [dbo].[ModelID]            NULL,
    [OwnershipCycle]                     [dbo].[OwnershipCycle]     NULL,
    [MatchedODSEventID]                  [dbo].[EventID]            NOT NULL,
    [ODSEventTypeID]                     [dbo].[EventTypeID]        NULL,
    [SaleDateOrig]                       VARCHAR (20)               NULL,
    [SaleDate]                           DATETIME2 (7)              NULL,
    [ServiceDateOrig]                    VARCHAR (20)               NULL,
    [ServiceDate]                        DATETIME2 (7)              NULL,
    [InvoiceDateOrig]                    VARCHAR (20)               NULL,
    [InvoiceDate]                        DATETIME2 (7)              NULL,
    [WarrantyID]                         [dbo].[WarrantyID]         NULL,
    [SalesDealerCodeOriginatorPartyID]   [dbo].[PartyID]            NULL,
    [SalesDealerCode]                    [dbo].[DealerCode]         NULL,
    [SalesDealerID]                      [dbo].[PartyID]            NOT NULL,
    [ServiceDealerCodeOriginatorPartyID] [dbo].[PartyID]            NULL,
    [ServiceDealerCode]                  [dbo].[DealerCode]         NULL,
    [ServiceDealerID]                    [dbo].[PartyID]            NOT NULL,

    [RoadsideNetworkOriginatorPartyID]   [dbo].[PartyID]            NULL,
    [RoadsideNetworkCode]                NVARCHAR(50)				NULL,
    [RoadsideNetworkPartyID]             [dbo].[PartyID]            NOT NULL,
    [RoadsideDate]						 DATETIME2 (7)              NULL,

    [CRCCentreOriginatorPartyID]		 [dbo].[PartyID]            NULL,
    [CRCCentreCode]                      NVARCHAR(50)				NULL,
    [CRCCentrePartyID]                   [dbo].[PartyID]            NOT NULL,
    [CRCDate]							 DATETIME2 (7)              NULL,

    [Brand]                              [dbo].[OrganisationName]   NULL,
    [Market]                             [dbo].[Country]            NULL,
    [Questionnaire]                      [dbo].[Requirement]        NULL,
    [QuestionnaireRequirementID]         [dbo].[RequirementID]      NULL,
    [StartDays]                          INT                        NULL,
    [EndDays]                            INT                        NULL,
    [SuppliedName]                       BIT                        NOT NULL,
    [SuppliedAddress]                    BIT                        NOT NULL,
    [SuppliedPhoneNumber]                BIT                        NOT NULL,
    [SuppliedMobilePhone]                BIT                        NOT NULL,
    [SuppliedEmail]                      BIT                        NOT NULL,
    [SuppliedVehicle]                    BIT                        NOT NULL,
    [SuppliedRegistration]               BIT                        NOT NULL,
    [SuppliedEventDate]                  BIT                        NOT NULL,
    [EventDateOutOfDate]                 BIT                        NOT NULL,
    [EventNonSolicitation]               BIT                        NOT NULL,
    [PartyNonSolicitation]               BIT                        NOT NULL,
    [UnmatchedModel]                     BIT                        NOT NULL,
    [UncodedDealer]                      BIT                        NOT NULL,
    [EventAlreadySelected]               BIT                        NOT NULL,
    [NonLatestEvent]                     BIT                        NOT NULL,
    [InvalidOwnershipCycle]              BIT                        NOT NULL,
    [RecontactPeriod]                    BIT                        NOT NULL,
    [InvalidVehicleRole]                 BIT                        NOT NULL,
    [CrossBorderAddress]                 BIT                        NOT NULL,
    [CrossBorderDealer]                  BIT                        NOT NULL,
    [ExclusionListMatch]                 BIT                        NOT NULL,
    [InvalidEmailAddress]                BIT                        NOT NULL,
    [BarredEmailAddress]                 BIT                        NOT NULL,
    [BarredDomain]                       BIT                        NOT NULL,
    [CaseID]                             [dbo].[CaseID]             NULL,
    [SampleRowProcessed]                 BIT                        NOT NULL,
    [SampleRowProcessedDate]             DATETIME2 (7)              NULL,
    [WrongEventType]                     BIT                        NOT NULL,
    [MissingStreet]                      BIT                        NOT NULL,
    [MissingPostcode]                    BIT                        NOT NULL,
    [MissingEmail]                       BIT                        NOT NULL,
    [MissingTelephone]                   BIT                        NOT NULL,
    [MissingStreetAndEmail]              BIT                        NOT NULL,
    [MissingTelephoneAndEmail]           BIT                        NOT NULL,
    [InvalidModel]                       BIT                        NOT NULL,
    [InvalidVariant]                     BIT                        NOT NULL,	-- 2019-04-15 BUG 15321
    [MissingMobilePhone]                 BIT                        NOT NULL,
    [MissingMobilePhoneAndEmail]         BIT                        NOT NULL,
    [MissingPartyName]                   BIT                        NOT NULL,
    [MissingLanguage]                    BIT                        NOT NULL,
    [CaseIDPrevious]                     INT                        NULL,
    [RelativeRecontactPeriod]			INT							NOT NULL,
    [InvalidManufacturer]				BIT							NOT NULL,
    [InternalDealer]					BIT							NOT NULL,
	[EventDateTooYoung]					BIT							NOT NULL,
	[InvalidRoleType]					BIT							NOT NULL,
	[InvalidSaleType]					BIT							NOT NULL,
	[InvalidAFRLCode]					BIT							NOT NULL,
	[SuppliedAFRLCode]				    VARCHAR(10)					NULL,
	[DealerExclusionListMatch]			BIT							NOT NULL,
	[PhoneSuppression]                  BIT                         NULL,
    [LostLeadDate]                      DATETIME2 (7)               NULL,
    [ContactPreferencesSuppression]		BIT							NULL,
    [NotInQuota]						BIT							NULL,
	[ContactPreferencesPartySuppress]	BIT							NULL,
	[ContactPreferencesEmailSuppress]	BIT							NULL,
	[ContactPreferencesPhoneSuppress]	BIT							NULL,
	[ContactPreferencesPostalSuppress]	BIT							NULL,
	[DealerPilotOutputFiltered]			BIT							NULL,
	[InvalidCRMSaleType]				BIT							NOT NULL,
	[MissingLostLeadAgency]				BIT							NULL,
	[BodyshopEventDateOrig]				[varchar](20)				NULL,
	[BodyshopEventDate]					[datetime2](7)				NULL,
	[BodyshopDealerCode]				[dbo].[DealerCode]			NULL,
	[BodyshopDealerID]					[dbo].[PartyID]				NULL,
	[BodyshopDealerCodeOriginatorPartyID] [dbo].[PartyID]			NULL,
	[PDIFlagSet]						BIT							NULL,				-- 06-09-2017 - BUG 14122
	[ContactPreferencesUnsubscribed]	BIT							NULL,				-- 21-12-2017 - BUG 14200
	SelectionOrganisationID				[dbo].[PartyID]				NULL,				-- 22-01-2018 - BUG 14399 - new reference column
	SelectionPostalID					[dbo].[ContactMechanismID]  NULL,				-- 22-01-2018 - BUG 14399 - new reference column
	SelectionEmailID					[dbo].[ContactMechanismID]  NULL,				-- 22-01-2018 - BUG 14399 - new reference column
	SelectionPhoneID					[dbo].[ContactMechanismID]  NULL,				-- 22-01-2018 - BUG 14399 - new reference column
	SelectionLandlineID					[dbo].[ContactMechanismID]  NULL,				-- 22-01-2018 - BUG 14399 - new reference column
	SelectionMobileID					[dbo].[ContactMechanismID]  NULL,				-- 22-01-2018 - BUG 14399 - new reference column
	NonSelectableWarrantyEvent			BIT							NOT NULL,			-- 21-05-2018 - BUG 14711
    IAssistanceCentreOriginatorPartyID	[dbo].[PartyID]				NULL,				-- BUG 15056
    IAssistanceCentreCode				NVARCHAR(50)				NULL,				-- BUG 15056
    IAssistanceCentrePartyID			[dbo].[PartyID]				NOT NULL,			-- BUG 15056
    IAssistanceDate						DATETIME2 (7)				NULL,				-- BUG 15056
    InvalidDateOfLastContact			BIT							NULL,				-- BUG 14820	
	CQIMissingExtraVehicleFeed			BIT							NULL,				-- BUG 16673
	GeneralEnquiryDate					DATETIME2(7)				NULL,				-- TASK 299
	MissingPerson						BIT							NULL,				-- TASK 441
	MissingOrganisation					BIT							NULL,				-- TASK 441
	InvalidDealerBrand					BIT							NULL,				-- TASK 474
	ExperienceEventDateOrig 				[varchar](20)			NULL,				-- TASK 877 - Land Rover Experience
	ExperienceEventDate						[datetime2](7)			NULL,				-- TASK 877 - Land Rover Experience
	ExperienceDealerCode					[dbo].[DealerCode]		NULL,				-- TASK 877 - Land Rover Experience
	ExperienceDealerID						[dbo].[PartyID]			NULL,				-- TASK 877 - Land Rover Experience
	ExperienceDealerCodeOriginatorPartyID	[dbo].[PartyID]			NULL				-- TASK 877 - Land Rover Experience
);






