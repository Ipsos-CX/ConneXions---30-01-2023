CREATE PROCEDURE [ParallelRun].[uspGenerateComparisonData]
AS
    SET NOCOUNT ON;

    DECLARE @ErrorNumber INT;
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;
    DECLARE @ErrorLocation NVARCHAR(500);
    DECLARE @ErrorLine INT;
    DECLARE @ErrorMessage NVARCHAR(2048);

    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    BEGIN TRY


/*
	Purpose:	Populates the Parallel Run Comparison tables
		
	Version		Date				Developer			Comment
	1.0			20/06/2013			Chris Ross			Created
	1.1			10/07/2019			Chris Ledger		Fix NULLs
	1.2 		30/07/2019			Chris Ross			Add in CaseDetails
	1.3			31/07/2019			Chris Ledger		Add fix for duplicate files
	1.4			15/01/2020			Chris Ledger 		BUG 15372 - Correct incorrect cases
	
*/



		----------------------------------------------------------------------------------------------------
		-- Comparisons table - Logging
		----------------------------------------------------------------------------------------------------


		TRUNCATE TABLE [ParallelRun].[Comparisons_SampleQualityAndSelectionLogging]  

		INSERT INTO [ParallelRun].[Comparisons_SampleQualityAndSelectionLogging] ([ComparisonLoadDate], [FileName], [PhysicalFileRow], [RemoteLoadedDate], [LocalLoadedDate], [Mismatch_LoadedDay], [RemoteAuditID], [LocalAuditID], [RemoteAuditItemID], [LocalAuditItemID], [Mismatch_ManufacturerID], [Mismatch_SampleSupplierPartyID], [Mismatch_MatchedODSPartyID], [Mismatch_MatchedODSPersonID], [Mismatch_LanguageID], [Mismatch_PartySuppression], [Mismatch_MatchedODSOrganisationID], [Mismatch_MatchedODSAddressID], [Mismatch_CountryID], [Mismatch_PostalSuppression], [Mismatch_AddressChecksum], [Mismatch_MatchedODSTelID], [Mismatch_MatchedODSPrivTelID], [Mismatch_MatchedODSBusTelID], [Mismatch_MatchedODSMobileTelID], [Mismatch_MatchedODSPrivMobileTelID], [Mismatch_MatchedODSEmailAddressID], [Mismatch_MatchedODSPrivEmailAddressID], [Mismatch_EmailSuppression], [Mismatch_VehicleParentAuditItemID], [Mismatch_MatchedODSVehicleID], [Mismatch_ODSRegistrationID], [Mismatch_MatchedODSModelID], [Mismatch_OwnershipCycle], [Mismatch_MatchedODSEventID], [Mismatch_ODSEventTypeID], [Mismatch_SaleDateOrig], [Mismatch_SaleDate], [Mismatch_ServiceDateOrig], [Mismatch_ServiceDate], [Mismatch_InvoiceDateOrig], [Mismatch_InvoiceDate], [Mismatch_WarrantyID], [Mismatch_SalesDealerCodeOriginatorPartyID], [Mismatch_SalesDealerCode], [Mismatch_SalesDealerID], [Mismatch_ServiceDealerCodeOriginatorPartyID], [Mismatch_ServiceDealerCode], [Mismatch_ServiceDealerID], [Mismatch_RoadsideNetworkOriginatorPartyID], [Mismatch_RoadsideNetworkCode], [Mismatch_RoadsideNetworkPartyID], [Mismatch_RoadsideDate], [Mismatch_CRCCentreOriginatorPartyID], [Mismatch_CRCCentreCode], [Mismatch_CRCCentrePartyID], [Mismatch_CRCDate], [Mismatch_Brand], [Mismatch_Market], [Mismatch_Questionnaire], [Mismatch_QuestionnaireRequirementID], [Mismatch_StartDays], [Mismatch_EndDays], [Mismatch_SuppliedName], [Mismatch_SuppliedAddress], [Mismatch_SuppliedPhoneNumber], [Mismatch_SuppliedMobilePhone], [Mismatch_SuppliedEmail], [Mismatch_SuppliedVehicle], [Mismatch_SuppliedRegistration], [Mismatch_SuppliedEventDate], [Mismatch_EventDateOutOfDate], [Mismatch_EventNonSolicitation], [Mismatch_PartyNonSolicitation], [Mismatch_UnmatchedModel], [Mismatch_UncodedDealer], [Mismatch_EventAlreadySelected], [Mismatch_NonLatestEvent], [Mismatch_InvalidOwnershipCycle], [Mismatch_RecontactPeriod], [Mismatch_InvalidVehicleRole], [Mismatch_CrossBorderAddress], [Mismatch_CrossBorderDealer], [Mismatch_ExclusionListMatch], [Mismatch_InvalidEmailAddress], [Mismatch_BarredEmailAddress], [Mismatch_BarredDomain], [Mismatch_CaseID], [Mismatched_CaseCreation], [Mismatch_SampleRowProcessed], [Mismatch_SampleRowProcessedDate], [Mismatch_WrongEventType], [Mismatch_MissingStreet], [Mismatch_MissingPostcode], [Mismatch_MissingEmail], [Mismatch_MissingTelephone], [Mismatch_MissingStreetAndEmail], [Mismatch_MissingTelephoneAndEmail], [Mismatch_InvalidModel], [Mismatch_InvalidVariant], [Mismatch_MissingMobilePhone], [Mismatch_MissingMobilePhoneAndEmail], [Mismatch_MissingPartyName], [Mismatch_MissingLanguage], [Mismatch_CaseIDPrevious], [Mismatch_RelativeRecontactPeriod], [Mismatch_InvalidManufacturer], [Mismatch_InternalDealer], [Mismatch_EventDateTooYoung], [Mismatch_InvalidRoleType], [Mismatch_InvalidSaleType], [Mismatch_InvalidAFRLCode], [Mismatch_SuppliedAFRLCode], [Mismatch_DealerExclusionListMatch], [Mismatch_PhoneSuppression], [Mismatch_LostLeadDate], [Mismatch_ContactPreferencesSuppression], [Mismatch_NotInQuota], [Mismatch_ContactPreferencesPartySuppress], [Mismatch_ContactPreferencesEmailSuppress], [Mismatch_ContactPreferencesPhoneSuppress], [Mismatch_ContactPreferencesPostalSuppress], [Mismatch_DealerPilotOutputFiltered], [Mismatch_InvalidCRMSaleType], [Mismatch_MissingLostLeadAgency], [Mismatch_PDIFlagSet], [Mismatch_BodyshopEventDateOrig], [Mismatch_BodyshopEventDate], [Mismatch_BodyshopDealerCode], [Mismatch_BodyshopDealerID], [Mismatch_BodyshopDealerCodeOriginatorPartyID], [Mismatch_ContactPreferencesUnsubscribed], [Mismatch_SelectionOrganisationID], [Mismatch_SelectionPostalID], [Mismatch_SelectionEmailID], [Mismatch_SelectionPhoneID], [Mismatch_SelectionLandlineID], [Mismatch_SelectionMobileID], [Mismatch_NonSelectableWarrantyEvent], [Mismatch_IAssistanceCentreOriginatorPartyID], [Mismatch_IAssistanceCentreCode], [Mismatch_IAssistanceCentrePartyID], [Mismatch_IAssistanceDate], [Mismatch_InvalidDateOfLastContact])
		SELECT 
		CAST(GETDATE() AS DATE) AS ComparisonLoadDate,
		psl.FileName 
		,psl.PhysicalFileRow 
		,psl.LoadedDate AS RemoteLoadedDate, sl.LoadedDate AS LocalLoadedDate
		,CASE WHEN CAST(psl.LoadedDate AS DATE) <> CAST(sl.LoadedDate AS DATE) THEN 1 ELSE 0 END AS Mismatch_LoadedDay
		,psl.AuditID AS RemoteAuditID , sl.AuditID AS LocalAuditID
		,psl.AuditItemID AS RemoteAuditItemID , sl.AuditItemID LocalAuditItemID
		,CASE WHEN ISNULL(psl.ManufacturerID, 0) <> ISNULL(sl.ManufacturerID, 0) THEN 1 ELSE 0 END AS Mismatch_ManufacturerID
		,CASE WHEN ISNULL(psl.SampleSupplierPartyID, 0) <> ISNULL(sl.SampleSupplierPartyID, 0) THEN 1 ELSE 0 END AS Mismatch_SampleSupplierPartyID
		,CASE WHEN ISNULL(psl.MatchedODSPartyID, 0) <> ISNULL(sl.MatchedODSPartyID, 0) THEN 1 ELSE 0 END AS Mismatch_MatchedODSPartyID
		,CASE WHEN ISNULL(psl.MatchedODSPersonID, 0) <> ISNULL(sl.MatchedODSPersonID, 0) THEN 1 ELSE 0 END AS Mismatch_MatchedODSPersonID
		,CASE WHEN ISNULL(psl.LanguageID, 0) <> ISNULL(sl.LanguageID, 0) THEN 1 ELSE 0 END AS Mismatch_LanguageID
		,CASE WHEN ISNULL(psl.PartySuppression, 0) <> ISNULL(sl.PartySuppression, 0) THEN 1 ELSE 0 END AS Mismatch_PartySuppression
		,CASE WHEN ISNULL(psl.MatchedODSOrganisationID, 0) <> ISNULL(sl.MatchedODSOrganisationID, 0) THEN 1 ELSE 0 END AS Mismatch_MatchedODSOrganisationID
		,CASE WHEN ISNULL(psl.MatchedODSAddressID, 0) <> ISNULL(sl.MatchedODSAddressID, 0) THEN 1 ELSE 0 END AS Mismatch_MatchedODSAddressID
		,CASE WHEN ISNULL(psl.CountryID, 0) <> ISNULL(sl.CountryID, 0) THEN 1 ELSE 0 END AS Mismatch_CountryID
		,CASE WHEN ISNULL(psl.PostalSuppression,'') <> ISNULL(sl.PostalSuppression, 0) THEN 1 ELSE 0 END AS Mismatch_PostalSuppression
		,CASE WHEN ISNULL(psl.AddressChecksum, 0) <> ISNULL(sl.AddressChecksum, 0) THEN 1 ELSE 0 END AS Mismatch_AddressChecksum
		,CASE WHEN ISNULL(psl.MatchedODSTelID, 0) <> ISNULL(sl.MatchedODSTelID, 0) THEN 1 ELSE 0 END AS Mismatch_MatchedODSTelID
		,CASE WHEN ISNULL(psl.MatchedODSPrivTelID, 0) <> ISNULL(sl.MatchedODSPrivTelID, 0) THEN 1 ELSE 0 END AS Mismatch_MatchedODSPrivTelID
		,CASE WHEN ISNULL(psl.MatchedODSBusTelID, 0) <> ISNULL(sl.MatchedODSBusTelID, 0) THEN 1 ELSE 0 END AS Mismatch_MatchedODSBusTelID
		,CASE WHEN ISNULL(psl.MatchedODSMobileTelID, 0) <> ISNULL(sl.MatchedODSMobileTelID, 0) THEN 1 ELSE 0 END AS Mismatch_MatchedODSMobileTelID
		,CASE WHEN ISNULL(psl.MatchedODSPrivMobileTelID, 0) <> ISNULL(sl.MatchedODSPrivMobileTelID, 0) THEN 1 ELSE 0 END AS Mismatch_MatchedODSPrivMobileTelID
		,CASE WHEN ISNULL(psl.MatchedODSEmailAddressID, 0) <> ISNULL(sl.MatchedODSEmailAddressID, 0) THEN 1 ELSE 0 END AS Mismatch_MatchedODSEmailAddressID
		,CASE WHEN ISNULL(psl.MatchedODSPrivEmailAddressID, 0) <> ISNULL(sl.MatchedODSPrivEmailAddressID, 0) THEN 1 ELSE 0 END AS Mismatch_MatchedODSPrivEmailAddressID
		,CASE WHEN ISNULL(psl.EmailSuppression, 0) <> ISNULL(sl.EmailSuppression, 0) THEN 1 ELSE 0 END AS Mismatch_EmailSuppression
		,CASE WHEN ISNULL(psl.VehicleParentAuditItemID, 0) <> ISNULL(sl.VehicleParentAuditItemID, 0) THEN 1 ELSE 0 END AS Mismatch_VehicleParentAuditItemID
		,CASE WHEN ISNULL(psl.MatchedODSVehicleID, 0) <> ISNULL(sl.MatchedODSVehicleID, 0) THEN 1 ELSE 0 END AS Mismatch_MatchedODSVehicleID
		,CASE WHEN ISNULL(psl.ODSRegistrationID, 0) <> ISNULL(sl.ODSRegistrationID, 0) THEN 1 ELSE 0 END AS Mismatch_ODSRegistrationID
		,CASE WHEN ISNULL(psl.MatchedODSModelID, 0) <> ISNULL(sl.MatchedODSModelID, 0) THEN 1 ELSE 0 END AS Mismatch_MatchedODSModelID
		,CASE WHEN ISNULL(psl.OwnershipCycle, 0) <> ISNULL(sl.OwnershipCycle, 0) THEN 1 ELSE 0 END AS Mismatch_OwnershipCycle
		,CASE WHEN ISNULL(psl.MatchedODSEventID, 0) <> ISNULL(sl.MatchedODSEventID, 0) THEN 1 ELSE 0 END AS Mismatch_MatchedODSEventID
		,CASE WHEN ISNULL(psl.ODSEventTypeID, 0) <> ISNULL(sl.ODSEventTypeID, 0) THEN 1 ELSE 0 END AS Mismatch_ODSEventTypeID
		,CASE WHEN ISNULL(psl.SaleDateOrig, '') <> ISNULL(sl.SaleDateOrig, '') THEN 1 ELSE 0 END AS Mismatch_SaleDateOrig
		,CASE WHEN ISNULL(psl.SaleDate, '2099-12-12') <> ISNULL(sl.SaleDate, '2099-12-12') THEN 1 ELSE 0 END AS Mismatch_SaleDate
		,CASE WHEN ISNULL(psl.ServiceDateOrig,'') <> ISNULL(sl.ServiceDateOrig, '') THEN 1 ELSE 0 END AS Mismatch_ServiceDateOrig
		,CASE WHEN ISNULL(psl.ServiceDate, '2099-12-12') <> ISNULL(sl.ServiceDate, '2099-12-12') THEN 1 ELSE 0 END AS Mismatch_ServiceDate
		,CASE WHEN ISNULL(psl.InvoiceDateOrig,'') <> ISNULL(sl.InvoiceDateOrig, '') THEN 1 ELSE 0 END AS Mismatch_InvoiceDateOrig
		,CASE WHEN ISNULL(psl.InvoiceDate, '2099-12-12') <> ISNULL(sl.InvoiceDate, '2099-12-12') THEN 1 ELSE 0 END AS Mismatch_InvoiceDate
		,CASE WHEN ISNULL(psl.WarrantyID, 0) <> ISNULL(sl.WarrantyID, 0) THEN 1 ELSE 0 END AS Mismatch_WarrantyID
		,CASE WHEN ISNULL(psl.SalesDealerCodeOriginatorPartyID, 0) <> ISNULL(sl.SalesDealerCodeOriginatorPartyID, 0) THEN 1 ELSE 0 END AS Mismatch_SalesDealerCodeOriginatorPartyID
		,CASE WHEN ISNULL(psl.SalesDealerCode, '') <> ISNULL(sl.SalesDealerCode, '') THEN 1 ELSE 0 END AS Mismatch_SalesDealerCode
		,CASE WHEN ISNULL(psl.SalesDealerID, 0) <> ISNULL(sl.SalesDealerID, 0) THEN 1 ELSE 0 END AS Mismatch_SalesDealerID
		,CASE WHEN ISNULL(psl.ServiceDealerCodeOriginatorPartyID, 0) <> ISNULL(sl.ServiceDealerCodeOriginatorPartyID, 0) THEN 1 ELSE 0 END AS Mismatch_ServiceDealerCodeOriginatorPartyID
		,CASE WHEN ISNULL(psl.ServiceDealerCode, '') <> ISNULL(sl.ServiceDealerCode, '') THEN 1 ELSE 0 END AS Mismatch_ServiceDealerCode
		,CASE WHEN ISNULL(psl.ServiceDealerID, 0) <> ISNULL(sl.ServiceDealerID, 0) THEN 1 ELSE 0 END AS Mismatch_ServiceDealerID
		,CASE WHEN ISNULL(psl.RoadsideNetworkOriginatorPartyID, 0) <> ISNULL(sl.RoadsideNetworkOriginatorPartyID, 0) THEN 1 ELSE 0 END AS Mismatch_RoadsideNetworkOriginatorPartyID
		,CASE WHEN ISNULL(psl.RoadsideNetworkCode, '') <> ISNULL(sl.RoadsideNetworkCode, '') THEN 1 ELSE 0 END AS Mismatch_RoadsideNetworkCode
		,CASE WHEN ISNULL(psl.RoadsideNetworkPartyID, 0) <> ISNULL(sl.RoadsideNetworkPartyID, 0) THEN 1 ELSE 0 END AS Mismatch_RoadsideNetworkPartyID
		,CASE WHEN ISNULL(psl.RoadsideDate, '2099-12-12') <> ISNULL(sl.RoadsideDate, '2099-12-12') THEN 1 ELSE 0 END AS Mismatch_RoadsideDate
		,CASE WHEN ISNULL(psl.CRCCentreOriginatorPartyID, 0) <> ISNULL(sl.CRCCentreOriginatorPartyID, 0) THEN 1 ELSE 0 END AS Mismatch_CRCCentreOriginatorPartyID
		,CASE WHEN ISNULL(psl.CRCCentreCode, '') <> ISNULL(sl.CRCCentreCode, '') THEN 1 ELSE 0 END AS Mismatch_CRCCentreCode
		,CASE WHEN ISNULL(psl.CRCCentrePartyID, 0) <> ISNULL(sl.CRCCentrePartyID, 0) THEN 1 ELSE 0 END AS Mismatch_CRCCentrePartyID
		,CASE WHEN ISNULL(psl.CRCDate, '2099-12-12') <> ISNULL(sl.CRCDate, '2099-12-12') THEN 1 ELSE 0 END AS Mismatch_CRCDate
		,CASE WHEN ISNULL(psl.Brand, '') <> ISNULL(sl.Brand, '') THEN 1 ELSE 0 END AS Mismatch_Brand
		,CASE WHEN ISNULL(psl.Market, '') <> ISNULL(sl.Market, '') THEN 1 ELSE 0 END AS Mismatch_Market
		,CASE WHEN ISNULL(psl.Questionnaire, '') <> ISNULL(sl.Questionnaire, '') THEN 1 ELSE 0 END AS Mismatch_Questionnaire
		,CASE WHEN ISNULL(psl.QuestionnaireRequirementID, 0) <> ISNULL(sl.QuestionnaireRequirementID, 0) THEN 1 ELSE 0 END AS Mismatch_QuestionnaireRequirementID
		,CASE WHEN ISNULL(psl.StartDays, 0) <> ISNULL(sl.StartDays, 0) THEN 1 ELSE 0 END AS Mismatch_StartDays
		,CASE WHEN ISNULL(psl.EndDays, 0) <> ISNULL(sl.EndDays, 0) THEN 1 ELSE 0 END AS Mismatch_EndDays
		,CASE WHEN ISNULL(psl.SuppliedName, 0) <> ISNULL(sl.SuppliedName, 0) THEN 1 ELSE 0 END AS Mismatch_SuppliedName
		,CASE WHEN ISNULL(psl.SuppliedAddress, 0) <> ISNULL(sl.SuppliedAddress, 0) THEN 1 ELSE 0 END AS Mismatch_SuppliedAddress
		,CASE WHEN ISNULL(psl.SuppliedPhoneNumber, 0) <> ISNULL(sl.SuppliedPhoneNumber, 0) THEN 1 ELSE 0 END AS Mismatch_SuppliedPhoneNumber
		,CASE WHEN ISNULL(psl.SuppliedMobilePhone, 0) <> ISNULL(sl.SuppliedMobilePhone, 0) THEN 1 ELSE 0 END AS Mismatch_SuppliedMobilePhone
		,CASE WHEN ISNULL(psl.SuppliedEmail, 0) <> ISNULL(sl.SuppliedEmail, 0) THEN 1 ELSE 0 END AS Mismatch_SuppliedEmail
		,CASE WHEN ISNULL(psl.SuppliedVehicle, 0) <> ISNULL(sl.SuppliedVehicle, 0) THEN 1 ELSE 0 END AS Mismatch_SuppliedVehicle
		,CASE WHEN ISNULL(psl.SuppliedRegistration, 0) <> ISNULL(sl.SuppliedRegistration, 0) THEN 1 ELSE 0 END AS Mismatch_SuppliedRegistration
		,CASE WHEN ISNULL(psl.SuppliedEventDate, 0) <> ISNULL(sl.SuppliedEventDate, 0) THEN 1 ELSE 0 END AS Mismatch_SuppliedEventDate
		,CASE WHEN ISNULL(psl.EventDateOutOfDate, 0) <> ISNULL(sl.EventDateOutOfDate, 0) THEN 1 ELSE 0 END AS Mismatch_EventDateOutOfDate
		,CASE WHEN ISNULL(psl.EventNonSolicitation, 0) <> ISNULL(sl.EventNonSolicitation, 0) THEN 1 ELSE 0 END AS Mismatch_EventNonSolicitation
		,CASE WHEN ISNULL(psl.PartyNonSolicitation, 0) <> ISNULL(sl.PartyNonSolicitation, 0) THEN 1 ELSE 0 END AS Mismatch_PartyNonSolicitation
		,CASE WHEN ISNULL(psl.UnmatchedModel, 0) <> ISNULL(sl.UnmatchedModel, 0) THEN 1 ELSE 0 END AS Mismatch_UnmatchedModel
		,CASE WHEN ISNULL(psl.UncodedDealer, 0) <> ISNULL(sl.UncodedDealer, 0) THEN 1 ELSE 0 END AS Mismatch_UncodedDealer
		,CASE WHEN ISNULL(psl.EventAlreadySelected, 0) <> ISNULL(sl.EventAlreadySelected, 0) THEN 1 ELSE 0 END AS Mismatch_EventAlreadySelected
		,CASE WHEN ISNULL(psl.NonLatestEvent, 0) <> ISNULL(sl.NonLatestEvent, 0) THEN 1 ELSE 0 END AS Mismatch_NonLatestEvent
		,CASE WHEN ISNULL(psl.InvalidOwnershipCycle, 0) <> ISNULL(sl.InvalidOwnershipCycle, 0) THEN 1 ELSE 0 END AS Mismatch_InvalidOwnershipCycle
		,CASE WHEN ISNULL(psl.RecontactPeriod, 0) <> ISNULL(sl.RecontactPeriod, 0) THEN 1 ELSE 0 END AS Mismatch_RecontactPeriod
		,CASE WHEN ISNULL(psl.InvalidVehicleRole, 0) <> ISNULL(sl.InvalidVehicleRole, 0) THEN 1 ELSE 0 END AS Mismatch_InvalidVehicleRole
		,CASE WHEN ISNULL(psl.CrossBorderAddress, 0) <> ISNULL(sl.CrossBorderAddress, 0) THEN 1 ELSE 0 END AS Mismatch_CrossBorderAddress
		,CASE WHEN ISNULL(psl.CrossBorderDealer, 0) <> ISNULL(sl.CrossBorderDealer, 0) THEN 1 ELSE 0 END AS Mismatch_CrossBorderDealer
		,CASE WHEN ISNULL(psl.ExclusionListMatch, 0) <> ISNULL(sl.ExclusionListMatch, 0) THEN 1 ELSE 0 END AS Mismatch_ExclusionListMatch
		,CASE WHEN ISNULL(psl.InvalidEmailAddress, 0) <> ISNULL(sl.InvalidEmailAddress, 0) THEN 1 ELSE 0 END AS Mismatch_InvalidEmailAddress
		,CASE WHEN ISNULL(psl.BarredEmailAddress, 0) <> ISNULL(sl.BarredEmailAddress, 0) THEN 1 ELSE 0 END AS Mismatch_BarredEmailAddress
		,CASE WHEN ISNULL(psl.BarredDomain, 0) <> ISNULL(sl.BarredDomain, 0) THEN 1 ELSE 0 END AS Mismatch_BarredDomain
		,CASE WHEN ISNULL(psl.CaseID, 0) <> ISNULL(sl.CaseID, 0) THEN 1 ELSE 0 END AS Mismatch_CaseID
		,CASE WHEN (ISNULL(psl.CaseID, 0) = 0 AND ISNULL(sl.CaseID, 0) <> 0) OR (ISNULL(sl.CaseID, 0) = 0 AND ISNULL(psl.CaseID, 0) <> 0)  THEN 1 ELSE 0 END AS Mismatched_CaseCreation
		,CASE WHEN ISNULL(psl.SampleRowProcessed, 0) <> ISNULL(sl.SampleRowProcessed, 0) THEN 1 ELSE 0 END AS Mismatch_SampleRowProcessed
		,CASE WHEN CAST(psl.SampleRowProcessedDate AS DATE) <> CAST(sl.SampleRowProcessedDate AS DATE) THEN 1 ELSE 0 END AS Mismatch_SampleRowProcessedDate
		,CASE WHEN ISNULL(psl.WrongEventType, 0) <> ISNULL(sl.WrongEventType, 0) THEN 1 ELSE 0 END AS Mismatch_WrongEventType
		,CASE WHEN ISNULL(psl.MissingStreet, 0) <> ISNULL(sl.MissingStreet, 0) THEN 1 ELSE 0 END AS Mismatch_MissingStreet
		,CASE WHEN ISNULL(psl.MissingPostcode, 0) <> ISNULL(sl.MissingPostcode, 0) THEN 1 ELSE 0 END AS Mismatch_MissingPostcode
		,CASE WHEN ISNULL(psl.MissingEmail, 0) <> ISNULL(sl.MissingEmail, 0) THEN 1 ELSE 0 END AS Mismatch_MissingEmail
		,CASE WHEN ISNULL(psl.MissingTelephone, 0) <> ISNULL(sl.MissingTelephone, 0) THEN 1 ELSE 0 END AS Mismatch_MissingTelephone
		,CASE WHEN ISNULL(psl.MissingStreetAndEmail, 0) <> ISNULL(sl.MissingStreetAndEmail, 0) THEN 1 ELSE 0 END AS Mismatch_MissingStreetAndEmail
		,CASE WHEN ISNULL(psl.MissingTelephoneAndEmail, 0) <> ISNULL(sl.MissingTelephoneAndEmail, 0) THEN 1 ELSE 0 END AS Mismatch_MissingTelephoneAndEmail
		,CASE WHEN ISNULL(psl.InvalidModel, 0) <> ISNULL(sl.InvalidModel, 0) THEN 1 ELSE 0 END AS Mismatch_InvalidModel
		,CASE WHEN ISNULL(psl.InvalidVariant, 0) <> ISNULL(sl.InvalidVariant, 0) THEN 1 ELSE 0 END AS Mismatch_InvalidVariant
		,CASE WHEN ISNULL(psl.MissingMobilePhone, 0) <> ISNULL(sl.MissingMobilePhone, 0) THEN 1 ELSE 0 END AS Mismatch_MissingMobilePhone
		,CASE WHEN ISNULL(psl.MissingMobilePhoneAndEmail, 0) <> ISNULL(sl.MissingMobilePhoneAndEmail, 0) THEN 1 ELSE 0 END AS Mismatch_MissingMobilePhoneAndEmail
		,CASE WHEN ISNULL(psl.MissingPartyName, 0) <> ISNULL(sl.MissingPartyName, 0) THEN 1 ELSE 0 END AS Mismatch_MissingPartyName
		,CASE WHEN ISNULL(psl.MissingLanguage, 0) <> ISNULL(sl.MissingLanguage, 0) THEN 1 ELSE 0 END AS Mismatch_MissingLanguage
		,CASE WHEN ISNULL(psl.CaseIDPrevious, 0) <> ISNULL(sl.CaseIDPrevious, 0) THEN 1 ELSE 0 END AS Mismatch_CaseIDPrevious
		,CASE WHEN REPLACE(ISNULL(psl.RelativeRecontactPeriod, 0),-1,1) <> ISNULL(sl.RelativeRecontactPeriod, 0) THEN 1 ELSE 0 END AS Mismatch_RelativeRecontactPeriod
		,CASE WHEN ISNULL(psl.InvalidManufacturer, 0) <> ISNULL(sl.InvalidManufacturer, 0) THEN 1 ELSE 0 END AS Mismatch_InvalidManufacturer
		,CASE WHEN ISNULL(psl.InternalDealer, 0) <> ISNULL(sl.InternalDealer, 0) THEN 1 ELSE 0 END AS Mismatch_InternalDealer
		,CASE WHEN ISNULL(psl.EventDateTooYoung, 0) <> ISNULL(sl.EventDateTooYoung, 0) THEN 1 ELSE 0 END AS Mismatch_EventDateTooYoung
		,CASE WHEN ISNULL(psl.InvalidRoleType, 0) <> ISNULL(sl.InvalidRoleType, 0) THEN 1 ELSE 0 END AS Mismatch_InvalidRoleType
		,CASE WHEN ISNULL(psl.InvalidSaleType, 0) <> ISNULL(sl.InvalidSaleType, 0) THEN 1 ELSE 0 END AS Mismatch_InvalidSaleType
		,CASE WHEN ISNULL(psl.InvalidAFRLCode, 0) <> ISNULL(sl.InvalidAFRLCode, 0) THEN 1 ELSE 0 END AS Mismatch_InvalidAFRLCode
		,CASE WHEN ISNULL(psl.SuppliedAFRLCode, '') <> ISNULL(sl.SuppliedAFRLCode, '') THEN 1 ELSE 0 END AS Mismatch_SuppliedAFRLCode
		,CASE WHEN ISNULL(psl.DealerExclusionListMatch, 0) <> ISNULL(sl.DealerExclusionListMatch, 0) THEN 1 ELSE 0 END AS Mismatch_DealerExclusionListMatch
		,CASE WHEN ISNULL(psl.PhoneSuppression, 0) <> ISNULL(sl.PhoneSuppression, 0) THEN 1 ELSE 0 END AS Mismatch_PhoneSuppression
		,CASE WHEN ISNULL(psl.LostLeadDate, '2099-12-12') <> ISNULL(sl.LostLeadDate, '2099-12-12') THEN 1 ELSE 0 END AS Mismatch_LostLeadDate
		,CASE WHEN ISNULL(psl.ContactPreferencesSuppression, 0) <> ISNULL(sl.ContactPreferencesSuppression, 0) THEN 1 ELSE 0 END AS Mismatch_ContactPreferencesSuppression
		,CASE WHEN ISNULL(psl.NotInQuota, 0) <> ISNULL(sl.NotInQuota, 0) THEN 1 ELSE 0 END AS Mismatch_NotInQuota
		,CASE WHEN ISNULL(psl.ContactPreferencesPartySuppress, 0) <> ISNULL(sl.ContactPreferencesPartySuppress, 0) THEN 1 ELSE 0 END AS Mismatch_ContactPreferencesPartySuppress
		,CASE WHEN ISNULL(psl.ContactPreferencesEmailSuppress, 0) <> ISNULL(sl.ContactPreferencesEmailSuppress, 0) THEN 1 ELSE 0 END AS Mismatch_ContactPreferencesEmailSuppress
		,CASE WHEN ISNULL(psl.ContactPreferencesPhoneSuppress, 0) <> ISNULL(sl.ContactPreferencesPhoneSuppress, 0) THEN 1 ELSE 0 END AS Mismatch_ContactPreferencesPhoneSuppress
		,CASE WHEN ISNULL(psl.ContactPreferencesPostalSuppress, 0) <> ISNULL(sl.ContactPreferencesPostalSuppress, 0) THEN 1 ELSE 0 END AS Mismatch_ContactPreferencesPostalSuppress
		,CASE WHEN ISNULL(psl.DealerPilotOutputFiltered, 0) <> ISNULL(sl.DealerPilotOutputFiltered, 0) THEN 1 ELSE 0 END AS Mismatch_DealerPilotOutputFiltered
		,CASE WHEN ISNULL(psl.InvalidCRMSaleType, 0) <> ISNULL(sl.InvalidCRMSaleType, 0) THEN 1 ELSE 0 END AS Mismatch_InvalidCRMSaleType
		,CASE WHEN ISNULL(psl.MissingLostLeadAgency, 0) <> ISNULL(sl.MissingLostLeadAgency, 0) THEN 1 ELSE 0 END AS Mismatch_MissingLostLeadAgency
		,CASE WHEN ISNULL(psl.PDIFlagSet, 0) <> ISNULL(sl.PDIFlagSet, 0) THEN 1 ELSE 0 END AS Mismatch_PDIFlagSet
		,CASE WHEN ISNULL(psl.BodyshopEventDateOrig,'') <> ISNULL(sl.BodyshopEventDateOrig, '') THEN 1 ELSE 0 END AS Mismatch_BodyshopEventDateOrig
		,CASE WHEN ISNULL(psl.BodyshopEventDate, '2099-12-12') <> ISNULL(sl.BodyshopEventDate, '2099-12-12') THEN 1 ELSE 0 END AS Mismatch_BodyshopEventDate
		,CASE WHEN ISNULL(psl.BodyshopDealerCode,'') <> ISNULL(sl.BodyshopDealerCode, '') THEN 1 ELSE 0 END AS Mismatch_BodyshopDealerCode
		,CASE WHEN ISNULL(psl.BodyshopDealerID, 0) <> ISNULL(sl.BodyshopDealerID, 0) THEN 1 ELSE 0 END AS Mismatch_BodyshopDealerID
		,CASE WHEN ISNULL(psl.BodyshopDealerCodeOriginatorPartyID, 0) <> ISNULL(sl.BodyshopDealerCodeOriginatorPartyID, 0) THEN 1 ELSE 0 END AS Mismatch_BodyshopDealerCodeOriginatorPartyID
		,CASE WHEN ISNULL(psl.ContactPreferencesUnsubscribed,'') <> ISNULL(sl.ContactPreferencesUnsubscribed, 0) THEN 1 ELSE 0 END AS Mismatch_ContactPreferencesUnsubscribed
		,CASE WHEN ISNULL(psl.SelectionOrganisationID, 0) <> ISNULL(sl.SelectionOrganisationID, 0) THEN 1 ELSE 0 END AS Mismatch_SelectionOrganisationID
		,CASE WHEN ISNULL(psl.SelectionPostalID, 0) <> ISNULL(sl.SelectionPostalID, 0) THEN 1 ELSE 0 END AS Mismatch_SelectionPostalID
		,CASE WHEN ISNULL(psl.SelectionEmailID, 0) <> ISNULL(sl.SelectionEmailID, 0) THEN 1 ELSE 0 END AS Mismatch_SelectionEmailID
		,CASE WHEN ISNULL(psl.SelectionPhoneID, 0) <> ISNULL(sl.SelectionPhoneID, 0) THEN 1 ELSE 0 END AS Mismatch_SelectionPhoneID
		,CASE WHEN ISNULL(psl.SelectionLandlineID, 0) <> ISNULL(sl.SelectionLandlineID, 0) THEN 1 ELSE 0 END AS Mismatch_SelectionLandlineID
		,CASE WHEN ISNULL(psl.SelectionMobileID, 0) <> ISNULL(sl.SelectionMobileID, 0) THEN 1 ELSE 0 END AS Mismatch_SelectionMobileID
		,CASE WHEN ISNULL(psl.NonSelectableWarrantyEvent,'') <> ISNULL(sl.NonSelectableWarrantyEvent, 0) THEN 1 ELSE 0 END AS Mismatch_NonSelectableWarrantyEvent
		,CASE WHEN ISNULL(psl.IAssistanceCentreOriginatorPartyID, 0) <> ISNULL(sl.IAssistanceCentreOriginatorPartyID, 0) THEN 1 ELSE 0 END AS Mismatch_IAssistanceCentreOriginatorPartyID
		,CASE WHEN ISNULL(psl.IAssistanceCentreCode,'') <> ISNULL(sl.IAssistanceCentreCode, '') THEN 1 ELSE 0 END AS Mismatch_IAssistanceCentreCode
		,CASE WHEN ISNULL(psl.IAssistanceCentrePartyID, 0) <> ISNULL(sl.IAssistanceCentrePartyID, 0) THEN 1 ELSE 0 END AS Mismatch_IAssistanceCentrePartyID
		,CASE WHEN ISNULL(psl.IAssistanceDate, '2099-12-12') <> ISNULL(sl.IAssistanceDate, '2099-12-12') THEN 1 ELSE 0 END AS Mismatch_IAssistanceDate
		,CASE WHEN ISNULL(psl.InvalidDateOfLastContact,'') <> ISNULL(sl.InvalidDateOfLastContact, 0) THEN 1 ELSE 0 END AS Mismatch_InvalidDateOfLastContact
		FROM [ParallelRun].[SampleQualityAndSelectionLogging] psl
		INNER JOIN [$(AuditDB)].dbo.Files f ON f.FileName = psl.FileName
											AND CAST(psl.LoadedDate AS date) = CAST(F.ActionDate as date)		-- V1.2
		INNER JOIN [$(WebsiteReporting)].dbo.[SampleQualityAndSelectionLogging] sl ON sl.AuditID = f.AuditID 
																			 AND sl.PhysicalFileRow = psl.PhysicalFileRow 



		----------------------------------------------------------------------------------------------------
		-- Comparisons table - People and Orgs
		----------------------------------------------------------------------------------------------------


		TRUNCATE TABLE [ParallelRun].[Comparisons_PersonAndOrganisation]

		INSERT INTO [ParallelRun].[Comparisons_PersonAndOrganisation] ([ComparisonLoadDate], [FileName], [PhysicalFileRow], [RemoteAuditID], [LocalAuditID], [RemoteAuditItemID], [LocalAuditItemID], [Mismatch_FromDate], [Mismatch_TitleID], [Mismatch_Initials], [Mismatch_FirstName], [Mismatch_MiddleName], [Mismatch_LastName], [Mismatch_SecondLastName], [Mismatch_GenderID], [Mismatch_BirthDate], [Mismatch_MonthAndYearOfBirth], [Mismatch_PreferredMethodOfContact], [Mismatch_NameChecksum], [Mismatch_OrganisationName], [Mismatch_OrganisationNameChecksum])
		SELECT 
		CAST(GETDATE() AS DATE) AS ComparisonLoadDate
		,psl.FileName 
		,psl.PhysicalFileRow 
		,psl.AuditID AS RemoteAuditID , sl.AuditID AS LocalAuditID
		,psl.AuditItemID AS RemoteAuditItemID , sl.AuditItemID LocalAuditItemID
		,CASE WHEN CAST(ISNULL(psl.FromDate, '2099-12-12') AS DATE) <> CAST(ISNULL(p.FromDate, '2099-12-12') AS DATE) THEN 1 ELSE 0 END AS Mismatch_FromDate
		,CASE WHEN ISNULL(psl.TitleID, 0) <> ISNULL(p.TitleID, '') THEN 1 ELSE 0 END AS Mismatch_TitleID
		,CASE WHEN ISNULL(psl.Initials,'') <> ISNULL(p.Initials, '') THEN 1 ELSE 0 END AS Mismatch_Initials
		,CASE WHEN ISNULL(psl.FirstName,'') <> ISNULL(p.FirstName, '') THEN 1 ELSE 0 END AS Mismatch_FirstName
		,CASE WHEN ISNULL(psl.MiddleName,'') <> ISNULL(p.MiddleName, '') THEN 1 ELSE 0 END AS Mismatch_MiddleName
		,CASE WHEN ISNULL(psl.LastName,'') <> ISNULL(p.LastName, '') THEN 1 ELSE 0 END AS Mismatch_LastName
		,CASE WHEN ISNULL(psl.SecondLastName,'') <> ISNULL(p.SecondLastName, '') THEN 1 ELSE 0 END AS Mismatch_SecondLastName
		,CASE WHEN ISNULL(psl.GenderID, 0) <> ISNULL(p.GenderID, 0) THEN 1 ELSE 0 END AS Mismatch_GenderID
		,CASE WHEN ISNULL(psl.BirthDate, '2099-12-12') <> ISNULL(p.BirthDate, '2099-12-12') THEN 1 ELSE 0 END AS Mismatch_BirthDate
		,CASE WHEN ISNULL(psl.MonthAndYearOfBirth,'') <> ISNULL(p.MonthAndYearOfBirth, '') THEN 1 ELSE 0 END AS Mismatch_MonthAndYearOfBirth
		,CASE WHEN ISNULL(psl.PreferredMethodOfContact,'') <> ISNULL(p.PreferredMethodOfContact, '') THEN 1 ELSE 0 END AS Mismatch_PreferredMethodOfContact
		,CASE WHEN ISNULL(psl.NameChecksum, 0) <> ISNULL(p.NameChecksum, 0) THEN 1 ELSE 0 END AS Mismatch_NameChecksum
		,CASE WHEN ISNULL(psl.OrganisationName,'') <> ISNULL(o.OrganisationName, '') THEN 1 ELSE 0 END AS Mismatch_OrganisationName
		,CASE WHEN ISNULL(psl.OrganisationNameChecksum, 0) <> ISNULL(o.OrganisationNameChecksum, 0) THEN 1 ELSE 0 END AS Mismatch_OrganisationNameChecksum
		FROM [ParallelRun].PersonAndOrganisation psl
		INNER JOIN [$(AuditDB)].dbo.Files f ON f.FileName = psl.FileName
		INNER JOIN [$(WebsiteReporting)].dbo.[SampleQualityAndSelectionLogging] sl ON sl.AuditID = f.AuditID 
																			 AND sl.PhysicalFileRow = psl.PhysicalFileRow 
		LEFT JOIN [$(SampleDB)].Party.People p ON p.PartyID = sl.MatchedODSPersonID
		LEFT JOIN [$(SampleDB)].Party.Organisations o ON o.PartyID = sl.MatchedODSOrganisationID



		----------------------------------------------------------------------------------------------------
		-- Comparisons table - Postal Address
		----------------------------------------------------------------------------------------------------

		TRUNCATE TABLE [ParallelRun].[Comparisons_PostalAddress]

		INSERT INTO [ParallelRun].[Comparisons_PostalAddress] ([ComparisonLoadDate], [FileName], [PhysicalFileRow], [RemoteAuditID], [LocalAuditID], [RemoteAuditItemID], [LocalAuditItemID], [Mismatch_ContactMechanismID], [Mismatch_BuildingName], [Mismatch_SubStreetNumber], [Mismatch_SubStreet], [Mismatch_StreetNumber], [Mismatch_Street], [Mismatch_SubLocality], [Mismatch_Locality], [Mismatch_Town], [Mismatch_Region], [Mismatch_PostCode], [Mismatch_CountryID], [Mismatch_AddressChecksum])
		SELECT 
		CAST(GETDATE() AS DATE) AS ComparisonLoadDate
		,psl.FileName 
		,psl.PhysicalFileRow 
		,psl.AuditID AS RemoteAuditID , sl.AuditID AS LocalAuditID
		,psl.AuditItemID AS RemoteAuditItemID , sl.AuditItemID LocalAuditItemID
		,CASE WHEN ISNULL(psl.ContactMechanismID, 0) <> ISNULL(pa.ContactMechanismID, 0) THEN 1 ELSE 0 END AS Mismatch_ContactMechanismID
		,CASE WHEN ISNULL(psl.BuildingName,'') <> ISNULL(pa.BuildingName, '') THEN 1 ELSE 0 END AS Mismatch_BuildingName
		,CASE WHEN ISNULL(psl.SubStreetNumber,'') <> ISNULL(pa.SubStreetNumber, '') THEN 1 ELSE 0 END AS Mismatch_SubStreetNumber
		,CASE WHEN ISNULL(psl.SubStreet,'') <> ISNULL(pa.SubStreet, '') THEN 1 ELSE 0 END AS Mismatch_SubStreet
		,CASE WHEN ISNULL(psl.StreetNumber,'') <> ISNULL(pa.StreetNumber, '') THEN 1 ELSE 0 END AS Mismatch_StreetNumber
		,CASE WHEN ISNULL(psl.Street,'') <> ISNULL(pa.Street, '') THEN 1 ELSE 0 END AS Mismatch_Street
		,CASE WHEN ISNULL(psl.SubLocality,'') <> ISNULL(pa.SubLocality, '') THEN 1 ELSE 0 END AS Mismatch_SubLocality
		,CASE WHEN ISNULL(psl.Locality,'') <> ISNULL(pa.Locality, '') THEN 1 ELSE 0 END AS Mismatch_Locality
		,CASE WHEN ISNULL(psl.Town,'') <> ISNULL(pa.Town, '') THEN 1 ELSE 0 END AS Mismatch_Town
		,CASE WHEN ISNULL(psl.Region,'') <> ISNULL(pa.Region, '') THEN 1 ELSE 0 END AS Mismatch_Region
		,CASE WHEN ISNULL(psl.PostCode,'') <> ISNULL(pa.PostCode, '') THEN 1 ELSE 0 END AS Mismatch_PostCode
		,CASE WHEN ISNULL(psl.CountryID, 0) <> ISNULL(pa.CountryID, 0) THEN 1 ELSE 0 END AS Mismatch_CountryID
		,CASE WHEN ISNULL(psl.AddressChecksum, 0) <> ISNULL(pa.AddressChecksum, 0) THEN 1 ELSE 0 END AS Mismatch_AddressChecksum
		FROM [ParallelRun].PostalAddress psl
		INNER JOIN [$(AuditDB)].dbo.Files f ON f.FileName = psl.FileName
		INNER JOIN [$(WebsiteReporting)].dbo.[SampleQualityAndSelectionLogging] sl ON sl.AuditID = f.AuditID 
																			 AND sl.PhysicalFileRow = psl.PhysicalFileRow 
		LEFT JOIN [$(SampleDB)].ContactMechanism.PostalAddresses pa ON pa.ContactMechanismID = sl.MatchedODSAddressID




		----------------------------------------------------------------------------------------------------
		-- Comparisons table - Email Addresses
		----------------------------------------------------------------------------------------------------



		TRUNCATE TABLE [ParallelRun].[Comparisons_EmailAddresses]

		INSERT INTO [ParallelRun].[Comparisons_EmailAddresses] ([ComparisonLoadDate], [FileName], [PhysicalFileRow], [RemoteAuditID], [LocalAuditID], [RemoteAuditItemID], [LocalAuditItemID], [Mismatch_EmailAddress], [Mismatch_EmailAddressChecksum], [Mismatch_PrivEmailAddress], [Mismatch_PrivEmailAddressChecksum])
		SELECT 
		CAST(GETDATE() AS DATE) AS ComparisonLoadDate
		,psl.FileName 
		,psl.PhysicalFileRow 
		,psl.AuditID AS RemoteAuditID , sl.AuditID AS LocalAuditID
		,psl.AuditItemID AS RemoteAuditItemID , sl.AuditItemID LocalAuditItemID
		,CASE WHEN ISNULL(psl.EmailAddress,'') <> ISNULL(ea.EmailAddress, '') THEN 1 ELSE 0 END AS Mismatch_EmailAddress
		,CASE WHEN ISNULL(psl.EmailAddressChecksum, 0) <> ISNULL(ea.EmailAddressChecksum, 0) THEN 1 ELSE 0 END AS Mismatch_EmailAddressChecksum
		,CASE WHEN ISNULL(psl.PrivEmailAddress,'') <> ISNULL(pea.EmailAddress, '') THEN 1 ELSE 0 END AS Mismatch_PrivEmailAddress
		,CASE WHEN ISNULL(psl.PrivEmailAddressChecksum, 0) <> ISNULL(pea.EmailAddressChecksum, 0) THEN 1 ELSE 0 END AS Mismatch_PrivEmailAddressChecksum
		FROM [ParallelRun].EmailAddresses psl
		INNER JOIN [$(AuditDB)].dbo.Files f ON f.FileName = psl.FileName
		INNER JOIN [$(WebsiteReporting)].dbo.[SampleQualityAndSelectionLogging] sl ON sl.AuditID = f.AuditID 
																			 AND sl.PhysicalFileRow = psl.PhysicalFileRow 
		LEFT JOIN [$(SampleDB)].ContactMechanism.EmailAddresses ea ON ea.ContactMechanismID = sl.MatchedODSEmailAddressID
		LEFT JOIN [$(SampleDB)].ContactMechanism.EmailAddresses pea ON pea.ContactMechanismID = sl.MatchedODSPrivEmailAddressID



		----------------------------------------------------------------------------------------------------
		-- Comparisons table - Telephone Numbers
		----------------------------------------------------------------------------------------------------

		TRUNCATE TABLE [ParallelRun].[Comparisons_TelephoneNumbers]

		INSERT INTO [ParallelRun].[Comparisons_TelephoneNumbers] ([ComparisonLoadDate], [FileName], [PhysicalFileRow], [RemoteAuditID], [LocalAuditID], [RemoteAuditItemID], [LocalAuditItemID], [Mismatch_tn_ContactNumber], [Mismatch_tn_ContactNumberChecksum], [Mismatch_ptn_ContactNumber], [Mismatch_ptn_ContactNumberChecksum], [Mismatch_btn_ContactNumber], [Mismatch_btn_ContactNumberChecksum], [Mismatch_mtn_ContactNumber], [Mismatch_mtn_ContactNumberChecksum], [Mismatch_pmtn_ContactNumber], [Mismatch_pmtn_ContactNumberChecksum])
		SELECT 
		CAST(GETDATE() AS DATE) AS ComparisonLoadDate
		,psl.FileName 
		,psl.PhysicalFileRow 
		,psl.AuditID AS RemoteAuditID , sl.AuditID AS LocalAuditID
		,psl.AuditItemID AS RemoteAuditItemID , sl.AuditItemID LocalAuditItemID
		,CASE WHEN ISNULL(psl.tn_ContactNumber,'') <> ISNULL(tn.ContactNumber, '') THEN 1 ELSE 0 END AS Mismatch_tn_ContactNumber
		,CASE WHEN ISNULL(psl.tn_ContactNumberChecksum, 0) <> ISNULL(tn.ContactNumberChecksum, 0) THEN 1 ELSE 0 END AS Mismatch_tn_ContactNumberChecksum
		,CASE WHEN ISNULL(psl.ptn_ContactNumber,'') <> ISNULL(ptn.ContactNumber, '') THEN 1 ELSE 0 END AS Mismatch_ptn_ContactNumber
		,CASE WHEN ISNULL(psl.ptn_ContactNumberChecksum, 0) <> ISNULL(ptn.ContactNumberChecksum, 0) THEN 1 ELSE 0 END AS Mismatch_ptn_ContactNumberChecksum
		,CASE WHEN ISNULL(psl.btn_ContactNumber,'') <> ISNULL(btn.ContactNumber, '') THEN 1 ELSE 0 END AS Mismatch_btn_ContactNumber
		,CASE WHEN ISNULL(psl.btn_ContactNumberChecksum, 0) <> ISNULL(btn.ContactNumberChecksum, 0) THEN 1 ELSE 0 END AS Mismatch_btn_ContactNumberChecksum
		,CASE WHEN ISNULL(psl.mtn_ContactNumber,'') <> ISNULL(mtn.ContactNumber, '') THEN 1 ELSE 0 END AS Mismatch_mtn_ContactNumber
		,CASE WHEN ISNULL(psl.mtn_ContactNumberChecksum, 0) <> ISNULL(mtn.ContactNumberChecksum, 0) THEN 1 ELSE 0 END AS Mismatch_mtn_ContactNumberChecksum
		,CASE WHEN ISNULL(psl.pmtn_ContactNumber,'') <> ISNULL(pmtn.ContactNumber, '') THEN 1 ELSE 0 END AS Mismatch_pmtn_ContactNumber
		,CASE WHEN ISNULL(psl.pmtn_ContactNumberChecksum, 0) <> ISNULL(pmtn.ContactNumberChecksum, 0) THEN 1 ELSE 0 END AS Mismatch_pmtn_ContactNumberChecksum
		FROM [ParallelRun].TelephoneNumbers psl
		INNER JOIN [$(AuditDB)].dbo.Files f ON f.FileName = psl.FileName
		INNER JOIN [$(WebsiteReporting)].dbo.[SampleQualityAndSelectionLogging] sl ON sl.AuditID = f.AuditID 
																			 AND sl.PhysicalFileRow = psl.PhysicalFileRow 
		LEFT JOIN [$(SampleDB)].ContactMechanism.TelephoneNumbers tn ON tn.ContactMechanismID = sl.MatchedODSTelID
		LEFT JOIN [$(SampleDB)].ContactMechanism.TelephoneNumbers ptn ON ptn.ContactMechanismID = sl.MatchedODSPrivTelID
		LEFT JOIN [$(SampleDB)].ContactMechanism.TelephoneNumbers btn ON btn.ContactMechanismID = sl.MatchedODSBusTelID
		LEFT JOIN [$(SampleDB)].ContactMechanism.TelephoneNumbers mtn ON mtn.ContactMechanismID = sl.MatchedODSMobileTelID
		LEFT JOIN [$(SampleDB)].ContactMechanism.TelephoneNumbers pmtn ON pmtn.ContactMechanismID = sl.MatchedODSPrivMobileTelID



		----------------------------------------------------------------------------------------------------
		-- Comparisons table - Vehicle
		----------------------------------------------------------------------------------------------------


		TRUNCATE TABLE [ParallelRun].[Comparisons_Vehicle]

		INSERT INTO [ParallelRun].[Comparisons_Vehicle] ([ComparisonLoadDate], [FileName], [PhysicalFileRow], [RemoteAuditID], [LocalAuditID], [RemoteAuditItemID], [LocalAuditItemID], [Mismatch_VehicleID], [Mismatch_ModelID], [Mismatch_VIN], [Mismatch_VehicleIdentificationNumberUsable], [Mismatch_VINPrefix], [Mismatch_ChassisNumber], [Mismatch_BuildDate], [Mismatch_BuildYear], [Mismatch_ThroughDate], [Mismatch_ModelVariantID], [Mismatch_SVOTypeID], [Mismatch_FOBCode], [Mismatch_RegistrationID], [Mismatch_RegistrationNumber], [Mismatch_RegistrationDate], [Mismatch_Reg_ThroughDate])
		SELECT 
		CAST(GETDATE() AS DATE) AS ComparisonLoadDate
		,psl.FileName 
		,psl.PhysicalFileRow 
		,psl.AuditID AS RemoteAuditID , sl.AuditID AS LocalAuditID
		,psl.AuditItemID AS RemoteAuditItemID , sl.AuditItemID LocalAuditItemID
		,CASE WHEN ISNULL(psl.VehicleID, 0) <> ISNULL(v.VehicleID, 0) THEN 1 ELSE 0 END AS Mismatch_VehicleID
		,CASE WHEN ISNULL(psl.ModelID, 0) <> ISNULL(v.ModelID, 0) THEN 1 ELSE 0 END AS Mismatch_ModelID
		,CASE WHEN ISNULL(psl.VIN,'') <> ISNULL(v.VIN, '') THEN 1 ELSE 0 END AS Mismatch_VIN
		,CASE WHEN ISNULL(psl.VehicleIdentificationNumberUsable, 0) <> ISNULL(v.VehicleIdentificationNumberUsable, 0) THEN 1 ELSE 0 END AS Mismatch_VehicleIdentificationNumberUsable
		,CASE WHEN ISNULL(psl.VINPrefix,'') <> ISNULL(v.VINPrefix, '') THEN 1 ELSE 0 END AS Mismatch_VINPrefix
		,CASE WHEN ISNULL(psl.ChassisNumber,'') <> ISNULL(v.ChassisNumber, '') THEN 1 ELSE 0 END AS Mismatch_ChassisNumber
		,CASE WHEN ISNULL(psl.BuildDate, '2099-12-12') <> ISNULL(v.BuildDate, '2099-12-12') THEN 1 ELSE 0 END AS Mismatch_BuildDate
		,CASE WHEN ISNULL(psl.BuildYear,'') <> ISNULL(v.BuildYear, '') THEN 1 ELSE 0 END AS Mismatch_BuildYear
		,CASE WHEN ISNULL(psl.ThroughDate, '2099-12-12') <> ISNULL(v.ThroughDate, '2099-12-12') THEN 1 ELSE 0 END AS Mismatch_ThroughDate
		,CASE WHEN ISNULL(psl.ModelVariantID, 0) <> ISNULL(v.ModelVariantID, 0) THEN 1 ELSE 0 END AS Mismatch_ModelVariantID
		,CASE WHEN ISNULL(psl.SVOTypeID, 0) <> ISNULL(v.SVOTypeID, 0) THEN 1 ELSE 0 END AS Mismatch_SVOTypeID
		,CASE WHEN ISNULL(psl.FOBCode,'') <> ISNULL(v.FOBCode, 0) THEN 1 ELSE 0 END AS Mismatch_FOBCode
		,CASE WHEN ISNULL(psl.RegistrationID, 0) <> ISNULL(r.RegistrationID, 0) THEN 1 ELSE 0 END AS Mismatch_RegistrationID
		,CASE WHEN ISNULL(psl.RegistrationNumber,'') <> ISNULL(r.RegistrationNumber, '') THEN 1 ELSE 0 END AS Mismatch_RegistrationNumber
		,CASE WHEN ISNULL(psl.RegistrationDate, '2099-12-12') <> ISNULL(r.RegistrationDate, '2099-12-12') THEN 1 ELSE 0 END AS Mismatch_RegistrationDate
		,CASE WHEN ISNULL(psl.Reg_ThroughDate, '2099-12-12') <> ISNULL(r.ThroughDate, '2099-12-12') THEN 1 ELSE 0 END AS Mismatch_Reg_ThroughDate
		FROM [ParallelRun].Vehicle psl
		INNER JOIN [$(AuditDB)].dbo.Files f ON f.FileName = psl.FileName
		INNER JOIN [$(WebsiteReporting)].dbo.[SampleQualityAndSelectionLogging] sl ON sl.AuditID = f.AuditID 
																			 AND sl.PhysicalFileRow = psl.PhysicalFileRow 
		LEFT JOIN [$(SampleDB)].Vehicle.Vehicles v ON v.VehicleID = sl.MatchedODSVehicleID
		LEFT JOIN [$(SampleDB)].Vehicle.Registrations r ON r.RegistrationID = sl.ODSRegistrationID


		----------------------------------------------------------------------------------------------------
		-- Comparisons table - CaseDetails															 -- v1.2
		----------------------------------------------------------------------------------------------------

		TRUNCATE TABLE [ParallelRun].[Comparisons_CaseDetails]

		INSERT INTO [ParallelRun].[Comparisons_CaseDetails] ([CaseID], [PartyID], [OrganisationPartyID], [Mismatch_CreationDate], [Mismatch_CaseStatusTypeID], [Mismatch_CaseRejection], [Mismatch_Questionnaire], [Mismatch_QuestionnaireRequirementID], [Mismatch_QuestionnaireVersion], [Mismatch_SelectionTypeID], [Mismatch_Selection], [Mismatch_ModelDerivative], [Mismatch_Title], [Mismatch_FirstName], [Mismatch_Initials], [Mismatch_MiddleName], [Mismatch_LastName], [Mismatch_SecondLastName], [Mismatch_GenderID], [Mismatch_LanguageID], [Mismatch_OrganisationName], [Mismatch_OrganisationPartyID], [Mismatch_PostalAddressContactMechanismID], [Mismatch_EmailAddressContactMechanismID], [Mismatch_CountryID], [Mismatch_Country], [Mismatch_CountryISOAlpha3], [Mismatch_CountryISOAlpha2], [Mismatch_EventTypeID], [Mismatch_EventType], [Mismatch_EventDate], [Mismatch_PartyID], [Mismatch_VehicleRoleTypeID], [Mismatch_VehicleID], [Mismatch_EventID], [Mismatch_OwnershipCycle], [Mismatch_SelectionRequirementID], [Mismatch_ModelRequirementID], [Mismatch_RegistrationNumber], [Mismatch_RegistrationDate], [Mismatch_ModelDescription], [Mismatch_VIN], [Mismatch_VinPrefix], [Mismatch_ChassisNumber], [Mismatch_ManufacturerPartyID], [Mismatch_DealerPartyID], [Mismatch_DealerCode], [Mismatch_DealerName], [Mismatch_RoadsideNetworkPartyID], [Mismatch_RoadsideNetworkCode], [Mismatch_RoadsideNetworkName], [Mismatch_SaleType], [Mismatch_VariantID], [Mismatch_ModelVariant])
		SELECT 
		--CAST(GETDATE() AS DATE) AS ComparisonLoadDate
		pcd.CaseID,
		CASE WHEN pcd.PartyID <> ISNULL(cd.PartyID, 0) THEN 1 ELSE 0 END AS Mismatch_PartyID,
		CASE WHEN pcd.OrganisationPartyID <> ISNULL(cd.OrganisationPartyID, 0) THEN 1 ELSE 0 END AS Mismatch_OrganisationPartyID,
		CASE WHEN CAST(pcd.CreationDate AS DATE) <> CAST(c.CreationDate AS DATE) THEN 1 ELSE 0 END AS Mismatch_CreationDate,
		CASE WHEN pcd.CaseStatusTypeID <> ISNULL(cd.CaseStatusTypeID, 0) THEN 1 ELSE 0 END AS Mismatch_CaseStatusTypeID,
		CASE WHEN pcd.CaseRejection <> ISNULL(cd.CaseRejection, 0) THEN 1 ELSE 0 END AS Mismatch_CaseRejection,
		CASE WHEN pcd.Questionnaire <> ISNULL(cd.Questionnaire, 0) THEN 1 ELSE 0 END AS Mismatch_Questionnaire,
		CASE WHEN pcd.QuestionnaireRequirementID <> ISNULL(cd.QuestionnaireRequirementID, 0) THEN 1 ELSE 0 END AS Mismatch_QuestionnaireRequirementID,
		CASE WHEN pcd.QuestionnaireVersion <> ISNULL(cd.QuestionnaireVersion, 0) THEN 1 ELSE 0 END AS Mismatch_QuestionnaireVersion,
		CASE WHEN pcd.SelectionTypeID <> ISNULL(cd.SelectionTypeID, 0) THEN 1 ELSE 0 END AS Mismatch_SelectionTypeID,
		CASE WHEN pcd.Selection <> ISNULL(cd.Selection, '') THEN 1 ELSE 0 END AS Mismatch_Selection,
		CASE WHEN pcd.ModelDerivative <> ISNULL(cd.ModelDerivative, '') THEN 1 ELSE 0 END AS Mismatch_ModelDerivative,
		CASE WHEN ISNULL(pcd.Title, '') <> ISNULL(cd.Title, '') THEN 1 ELSE 0 END AS Mismatch_Title,
		CASE WHEN ISNULL(pcd.FirstName, '') <> ISNULL(cd.FirstName, '') THEN 1 ELSE 0 END AS Mismatch_FirstName,
		CASE WHEN ISNULL(pcd.Initials, '') <> ISNULL(cd.Initials, '') THEN 1 ELSE 0 END AS Mismatch_Initials,
		CASE WHEN ISNULL(pcd.MiddleName, '') <> ISNULL(cd.MiddleName, '') THEN 1 ELSE 0 END AS Mismatch_MiddleName,
		CASE WHEN ISNULL(pcd.LastName, '') <> ISNULL(cd.LastName, '') THEN 1 ELSE 0 END AS Mismatch_LastName,
		CASE WHEN ISNULL(pcd.SecondLastName, '') <> ISNULL(cd.SecondLastName, '') THEN 1 ELSE 0 END AS Mismatch_SecondLastName,
		CASE WHEN ISNULL(pcd.GenderID, 0) <> ISNULL(cd.GenderID, 0) THEN 1 ELSE 0 END AS Mismatch_GenderID,
		CASE WHEN ISNULL(pcd.LanguageID,0) <> ISNULL(cd.LanguageID, 0) THEN 1 ELSE 0 END AS Mismatch_LanguageID,
		CASE WHEN ISNULL(pcd.OrganisationName, '') <> ISNULL(cd.OrganisationName, '') THEN 1 ELSE 0 END AS Mismatch_OrganisationName,
		CASE WHEN ISNULL(pcd.OrganisationPartyID,0) <> ISNULL(cd.OrganisationPartyID, 0) THEN 1 ELSE 0 END AS Mismatch_OrganisationPartyID,
		CASE WHEN ISNULL(pcd.PostalAddressContactMechanismID,0) <> ISNULL(cd.PostalAddressContactMechanismID, 0) THEN 1 ELSE 0 END AS Mismatch_PostalAddressContactMechanismID,
		CASE WHEN ISNULL(pcd.EmailAddressContactMechanismID, 0) <> ISNULL(cd.EmailAddressContactMechanismID, 0) THEN 1 ELSE 0 END AS Mismatch_EmailAddressContactMechanismID,
		CASE WHEN ISNULL(pcd.CountryID, 0) <> ISNULL(cd.CountryID, 0) THEN 1 ELSE 0 END AS Mismatch_CountryID,
		CASE WHEN ISNULL(pcd.Country, '') <> ISNULL(cd.Country, '') THEN 1 ELSE 0 END AS Mismatch_Country,
		CASE WHEN ISNULL(pcd.CountryISOAlpha3, '')  <> ISNULL(cd.CountryISOAlpha3, '') THEN 1 ELSE 0 END AS Mismatch_CountryISOAlpha3,
		CASE WHEN ISNULL(pcd.CountryISOAlpha2, '')  <> ISNULL(cd.CountryISOAlpha2, '') THEN 1 ELSE 0 END AS Mismatch_CountryISOAlpha2,
		CASE WHEN ISNULL(pcd.EventTypeID, 0) <> ISNULL(cd.EventTypeID, 0) THEN 1 ELSE 0 END AS Mismatch_EventTypeID,
		CASE WHEN ISNULL(pcd.EventType, '') <> ISNULL(cd.EventType, '') THEN 1 ELSE 0 END AS Mismatch_EventType,
		CASE WHEN ISNULL(pcd.EventDate, '2099-12-12') <> ISNULL(cd.EventDate, '2099-12-12') THEN 1 ELSE 0 END AS Mismatch_EventDate,
		CASE WHEN ISNULL(pcd.PartyID, 0) <> ISNULL(cd.PartyID, 0) THEN 1 ELSE 0 END AS Mismatch_PartyID,
		CASE WHEN ISNULL(pcd.VehicleRoleTypeID, 0) <> ISNULL(cd.VehicleRoleTypeID, 0) THEN 1 ELSE 0 END AS Mismatch_VehicleRoleTypeID,
		CASE WHEN ISNULL(pcd.VehicleID, 0) <> ISNULL(cd.VehicleID, 0) THEN 1 ELSE 0 END AS Mismatch_VehicleID,
		CASE WHEN ISNULL(pcd.EventID, 0) <> ISNULL(cd.EventID, 0) THEN 1 ELSE 0 END AS Mismatch_EventID,
		CASE WHEN ISNULL(pcd.OwnershipCycle,0) <> ISNULL(cd.OwnershipCycle, 0) THEN 1 ELSE 0 END AS Mismatch_OwnershipCycle,
		CASE WHEN ISNULL(pcd.SelectionRequirementID,0)  <> ISNULL(cd.SelectionRequirementID, 0) THEN 1 ELSE 0 END AS Mismatch_SelectionRequirementID,
		CASE WHEN ISNULL(pcd.ModelRequirementID,0)  <> ISNULL(cd.ModelRequirementID, 0) THEN 1 ELSE 0 END AS Mismatch_ModelRequirementID,
		CASE WHEN ISNULL(pcd.RegistrationNumber, '') <> ISNULL(cd.RegistrationNumber, '') THEN 1 ELSE 0 END AS Mismatch_RegistrationNumber,
		CASE WHEN ISNULL(pcd.RegistrationDate, '2099-12-12')  <> ISNULL(cd.RegistrationDate, '2099-12-12')  THEN 1 ELSE 0 END AS Mismatch_RegistrationDate,
		CASE WHEN ISNULL(pcd.ModelDescription, '') <> ISNULL(cd.ModelDescription, '') THEN 1 ELSE 0 END AS Mismatch_ModelDescription,
		CASE WHEN ISNULL(pcd.VIN, '') <> ISNULL(cd.VIN, '') THEN 1 ELSE 0 END AS Mismatch_VIN,
		CASE WHEN ISNULL(pcd.VinPrefix, '') <> ISNULL(cd.VinPrefix, '') THEN 1 ELSE 0 END AS Mismatch_VinPrefix,
		CASE WHEN ISNULL(pcd.ChassisNumber, '') <> ISNULL(cd.ChassisNumber, '') THEN 1 ELSE 0 END AS Mismatch_ChassisNumber,
		CASE WHEN ISNULL(pcd.ManufacturerPartyID,0)  <> ISNULL(cd.ManufacturerPartyID, 0) THEN 1 ELSE 0 END AS Mismatch_ManufacturerPartyID,
		CASE WHEN ISNULL(pcd.DealerPartyID,0)  <> ISNULL(cd.DealerPartyID, 0) THEN 1 ELSE 0 END AS Mismatch_DealerPartyID,
		CASE WHEN ISNULL(pcd.DealerCode, '') <> ISNULL(cd.DealerCode, '') THEN 1 ELSE 0 END AS Mismatch_DealerCode,
		CASE WHEN ISNULL(pcd.DealerName, '') <> ISNULL(cd.DealerName, '') THEN 1 ELSE 0 END AS Mismatch_DealerName,
		CASE WHEN ISNULL(pcd.RoadsideNetworkPartyID,0)  <> ISNULL(cd.RoadsideNetworkPartyID, 0) THEN 1 ELSE 0 END AS Mismatch_RoadsideNetworkPartyID,
		CASE WHEN ISNULL(pcd.RoadsideNetworkCode, '') <> ISNULL(cd.RoadsideNetworkCode, '') THEN 1 ELSE 0 END AS Mismatch_RoadsideNetworkCode,
		CASE WHEN ISNULL(pcd.RoadsideNetworkName, '') <> ISNULL(cd.RoadsideNetworkName, '') THEN 1 ELSE 0 END AS Mismatch_RoadsideNetworkName,
		CASE WHEN ISNULL(pcd.SaleType, '') <> ISNULL(cd.SaleType, '') THEN 1 ELSE 0 END AS Mismatch_SaleType,
		CASE WHEN ISNULL(pcd.VariantID,0)  <> ISNULL(cd.VariantID, 0) THEN 1 ELSE 0 END AS Mismatch_VariantID,
		CASE WHEN ISNULL(pcd.ModelVariant, '') <> ISNULL(cd.ModelVariant, '') THEN 1 ELSE 0 END AS Mismatch_ModelVariant
		FROM ParallelRun.CaseDetails pcd 
		LEFT JOIN [$(SampleDB)].Meta.CaseDetails cd ON cd.CaseID = pcd.CaseID
		LEFT JOIN [$(SampleDB)].Event.Cases c On c.CaseID = pcd.CaseID


    END TRY
    BEGIN CATCH

        SELECT  @ErrorNumber = ERROR_NUMBER() ,
                @ErrorSeverity = ERROR_SEVERITY() ,
                @ErrorState = ERROR_STATE() ,
                @ErrorLocation = ERROR_PROCEDURE() ,
                @ErrorLine = ERROR_LINE() ,
                @ErrorMessage = ERROR_MESSAGE();

        EXEC [$(ErrorDB)].[dbo].uspLogDatabaseError @ErrorNumber,
            @ErrorSeverity, @ErrorState, @ErrorLocation, @ErrorLine,
            @ErrorMessage;
		
        RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine);
		
END CATCH;

GO


