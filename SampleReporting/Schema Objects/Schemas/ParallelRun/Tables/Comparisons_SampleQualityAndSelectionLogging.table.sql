CREATE TABLE [ParallelRun].[Comparisons_SampleQualityAndSelectionLogging](
	[ComparisonLoadDate] DATETIME NOT NULL,
	[FileName] [varchar](100) NOT NULL,
	[PhysicalFileRow] [int] NOT NULL,
	[RemoteLoadedDate] [datetime2](7) NOT NULL,
	[LocalLoadedDate] [datetime2](7) NOT NULL,
	[Mismatch_LoadedDay] [int] NOT NULL,
	[RemoteAuditID] [bigint] NOT NULL,
	[LocalAuditID] [bigint] NOT NULL,
	[RemoteAuditItemID] [bigint] NOT NULL,
	[LocalAuditItemID] [bigint] NOT NULL,
	[Mismatch_ManufacturerID] [int] NOT NULL,
	[Mismatch_SampleSupplierPartyID] [int] NOT NULL,
	[Mismatch_MatchedODSPartyID] [int] NOT NULL,
	[Mismatch_MatchedODSPersonID] [int] NOT NULL,
	[Mismatch_LanguageID] [int] NOT NULL,
	[Mismatch_PartySuppression] [int] NOT NULL,
	[Mismatch_MatchedODSOrganisationID] [int] NOT NULL,
	[Mismatch_MatchedODSAddressID] [int] NOT NULL,
	[Mismatch_CountryID] [int] NOT NULL,
	[Mismatch_PostalSuppression] [int] NOT NULL,
	[Mismatch_AddressChecksum] [int] NOT NULL,
	[Mismatch_MatchedODSTelID] [int] NOT NULL,
	[Mismatch_MatchedODSPrivTelID] [int] NOT NULL,
	[Mismatch_MatchedODSBusTelID] [int] NOT NULL,
	[Mismatch_MatchedODSMobileTelID] [int] NOT NULL,
	[Mismatch_MatchedODSPrivMobileTelID] [int] NOT NULL,
	[Mismatch_MatchedODSEmailAddressID] [int] NOT NULL,
	[Mismatch_MatchedODSPrivEmailAddressID] [int] NOT NULL,
	[Mismatch_EmailSuppression] [int] NOT NULL,
	[Mismatch_VehicleParentAuditItemID] [int] NOT NULL,
	[Mismatch_MatchedODSVehicleID] [int] NOT NULL,
	[Mismatch_ODSRegistrationID] [int] NOT NULL,
	[Mismatch_MatchedODSModelID] [int] NOT NULL,
	[Mismatch_OwnershipCycle] [int] NOT NULL,
	[Mismatch_MatchedODSEventID] [int] NOT NULL,
	[Mismatch_ODSEventTypeID] [int] NOT NULL,
	[Mismatch_SaleDateOrig] [int] NOT NULL,
	[Mismatch_SaleDate] [int] NOT NULL,
	[Mismatch_ServiceDateOrig] [int] NOT NULL,
	[Mismatch_ServiceDate] [int] NOT NULL,
	[Mismatch_InvoiceDateOrig] [int] NOT NULL,
	[Mismatch_InvoiceDate] [int] NOT NULL,
	[Mismatch_WarrantyID] [int] NOT NULL,
	[Mismatch_SalesDealerCodeOriginatorPartyID] [int] NOT NULL,
	[Mismatch_SalesDealerCode] [int] NOT NULL,
	[Mismatch_SalesDealerID] [int] NOT NULL,
	[Mismatch_ServiceDealerCodeOriginatorPartyID] [int] NOT NULL,
	[Mismatch_ServiceDealerCode] [int] NOT NULL,
	[Mismatch_ServiceDealerID] [int] NOT NULL,
	[Mismatch_RoadsideNetworkOriginatorPartyID] [int] NOT NULL,
	[Mismatch_RoadsideNetworkCode] [int] NOT NULL,
	[Mismatch_RoadsideNetworkPartyID] [int] NOT NULL,
	[Mismatch_RoadsideDate] [int] NOT NULL,
	[Mismatch_CRCCentreOriginatorPartyID] [int] NOT NULL,
	[Mismatch_CRCCentreCode] [int] NOT NULL,
	[Mismatch_CRCCentrePartyID] [int] NOT NULL,
	[Mismatch_CRCDate] [int] NOT NULL,
	[Mismatch_Brand] [int] NOT NULL,
	[Mismatch_Market] [int] NOT NULL,
	[Mismatch_Questionnaire] [int] NOT NULL,
	[Mismatch_QuestionnaireRequirementID] [int] NOT NULL,
	[Mismatch_StartDays] [int] NOT NULL,
	[Mismatch_EndDays] [int] NOT NULL,
	[Mismatch_SuppliedName] [int] NOT NULL,
	[Mismatch_SuppliedAddress] [int] NOT NULL,
	[Mismatch_SuppliedPhoneNumber] [int] NOT NULL,
	[Mismatch_SuppliedMobilePhone] [int] NOT NULL,
	[Mismatch_SuppliedEmail] [int] NOT NULL,
	[Mismatch_SuppliedVehicle] [int] NOT NULL,
	[Mismatch_SuppliedRegistration] [int] NOT NULL,
	[Mismatch_SuppliedEventDate] [int] NOT NULL,
	[Mismatch_EventDateOutOfDate] [int] NOT NULL,
	[Mismatch_EventNonSolicitation] [int] NOT NULL,
	[Mismatch_PartyNonSolicitation] [int] NOT NULL,
	[Mismatch_UnmatchedModel] [int] NOT NULL,
	[Mismatch_UncodedDealer] [int] NOT NULL,
	[Mismatch_EventAlreadySelected] [int] NOT NULL,
	[Mismatch_NonLatestEvent] [int] NOT NULL,
	[Mismatch_InvalidOwnershipCycle] [int] NOT NULL,
	[Mismatch_RecontactPeriod] [int] NOT NULL,
	[Mismatch_InvalidVehicleRole] [int] NOT NULL,
	[Mismatch_CrossBorderAddress] [int] NOT NULL,
	[Mismatch_CrossBorderDealer] [int] NOT NULL,
	[Mismatch_ExclusionListMatch] [int] NOT NULL,
	[Mismatch_InvalidEmailAddress] [int] NOT NULL,
	[Mismatch_BarredEmailAddress] [int] NOT NULL,
	[Mismatch_BarredDomain] [int] NOT NULL,
	[Mismatch_CaseID] [int] NOT NULL,
	[Mismatched_CaseCreation] [int] NOT NULL,
	[Mismatch_SampleRowProcessed] [int] NOT NULL,
	[Mismatch_SampleRowProcessedDate] [int] NOT NULL,
	[Mismatch_WrongEventType] [int] NOT NULL,
	[Mismatch_MissingStreet] [int] NOT NULL,
	[Mismatch_MissingPostcode] [int] NOT NULL,
	[Mismatch_MissingEmail] [int] NOT NULL,
	[Mismatch_MissingTelephone] [int] NOT NULL,
	[Mismatch_MissingStreetAndEmail] [int] NOT NULL,
	[Mismatch_MissingTelephoneAndEmail] [int] NOT NULL,
	[Mismatch_InvalidModel] [int] NOT NULL,
	[Mismatch_InvalidVariant] [int] NOT NULL,
	[Mismatch_MissingMobilePhone] [int] NOT NULL,
	[Mismatch_MissingMobilePhoneAndEmail] [int] NOT NULL,
	[Mismatch_MissingPartyName] [int] NOT NULL,
	[Mismatch_MissingLanguage] [int] NOT NULL,
	[Mismatch_CaseIDPrevious] [int] NOT NULL,
	[Mismatch_RelativeRecontactPeriod] [int] NOT NULL,
	[Mismatch_InvalidManufacturer] [int] NOT NULL,
	[Mismatch_InternalDealer] [int] NOT NULL,
	[Mismatch_EventDateTooYoung] [int] NOT NULL,
	[Mismatch_InvalidRoleType] [int] NOT NULL,
	[Mismatch_InvalidSaleType] [int] NOT NULL,
	[Mismatch_InvalidAFRLCode] [int] NOT NULL,
	[Mismatch_SuppliedAFRLCode] [int] NOT NULL,
	[Mismatch_DealerExclusionListMatch] [int] NOT NULL,
	[Mismatch_PhoneSuppression] [int] NOT NULL,
	[Mismatch_LostLeadDate] [int] NOT NULL,
	[Mismatch_ContactPreferencesSuppression] [int] NOT NULL,
	[Mismatch_NotInQuota] [int] NOT NULL,
	[Mismatch_ContactPreferencesPartySuppress] [int] NOT NULL,
	[Mismatch_ContactPreferencesEmailSuppress] [int] NOT NULL,
	[Mismatch_ContactPreferencesPhoneSuppress] [int] NOT NULL,
	[Mismatch_ContactPreferencesPostalSuppress] [int] NOT NULL,
	[Mismatch_DealerPilotOutputFiltered] [int] NOT NULL,
	[Mismatch_InvalidCRMSaleType] [int] NOT NULL,
	[Mismatch_MissingLostLeadAgency] [int] NOT NULL,
	[Mismatch_PDIFlagSet] [int] NOT NULL,
	[Mismatch_BodyshopEventDateOrig] [int] NOT NULL,
	[Mismatch_BodyshopEventDate] [int] NOT NULL,
	[Mismatch_BodyshopDealerCode] [int] NOT NULL,
	[Mismatch_BodyshopDealerID] [int] NOT NULL,
	[Mismatch_BodyshopDealerCodeOriginatorPartyID] [int] NOT NULL,
	[Mismatch_ContactPreferencesUnsubscribed] [int] NOT NULL,
	[Mismatch_SelectionOrganisationID] [int] NOT NULL,
	[Mismatch_SelectionPostalID] [int] NOT NULL,
	[Mismatch_SelectionEmailID] [int] NOT NULL,
	[Mismatch_SelectionPhoneID] [int] NOT NULL,
	[Mismatch_SelectionLandlineID] [int] NOT NULL,
	[Mismatch_SelectionMobileID] [int] NOT NULL,
	[Mismatch_NonSelectableWarrantyEvent] [int] NOT NULL,
	[Mismatch_IAssistanceCentreOriginatorPartyID] [int] NOT NULL,
	[Mismatch_IAssistanceCentreCode] [int] NOT NULL,
	[Mismatch_IAssistanceCentrePartyID] [int] NOT NULL,
	[Mismatch_IAssistanceDate] [int] NOT NULL,
	[Mismatch_InvalidDateOfLastContact] [int] NOT NULL,
	
	MatchedODSPersonIDNew				INT DEFAULT 0,
	MatchedODSOrganisationIDNew			INT DEFAULT 0,
	MatchedODSAddressIDNew				INT DEFAULT 0,
	MatchedODSTelIDNew					INT DEFAULT 0,
	MatchedODSPrivTelIDNew				INT DEFAULT 0,
	MatchedODSMobileTelIDNew			INT DEFAULT 0,
	MatchedODSEmailAddressIDNew			INT DEFAULT 0,
	MatchedODSPrivEmailAddressIDNew		INT DEFAULT 0,
	MatchedODSVehicleIDNew				INT DEFAULT 0,
	MatchedODSBusTelIDNew             INT DEFAULT 0,
	MatchedODSEventIDNew              INT DEFAULT 0,
	SelectionOrganisationIDNew        INT DEFAULT 0,
	SelectionPostalIDNew              INT DEFAULT 0,
	SelectionEmailIDNew               INT DEFAULT 0,
	SelectionPhoneIDNew               INT DEFAULT 0,
	SelectionLandlineIDNew            INT DEFAULT 0,
	SelectionMobileIDNew              INT DEFAULT 0


	
)