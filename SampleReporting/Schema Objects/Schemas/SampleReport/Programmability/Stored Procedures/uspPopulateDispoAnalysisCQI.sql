CREATE PROCEDURE [SampleReport].[uspPopulateDispoAnalysisCQI]

AS
SET NOCOUNT ON

/*
	Purpose:	Produce weekly CQI report
			
	Release		Version			Date			Developer			Comment
	LIVE		1.0				2021-11-11		Ben King			Task 691
	LIVE        1.1             2021-12-15      Ben King            Task 723 - automated report - adding France and Netherlands
	LIVE		1.2				2022-07-14		Chris Ledger		Replace SL.* with individual columns (i.e. SL.LoadedDate)
*/

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)


BEGIN TRY
		
		TRUNCATE TABLE SampleReport.DispoCQI

		TRUNCATE TABLE SampleReport.ReasonForNonSelectionCQI

		TRUNCATE TABLE SampleReport.DataFeedCQI
		

		--"MINI DISPO" tab in Excel template
		INSERT INTO SampleReport.DispoCQI ([Market_], [Questionnaire_], [Brand_], [FileName], [FileRowCount], [EndDays_], [StartDays_], [Sale_Date], [EndWindow], [StartWindow], [CaseID_], [Requirement], [VIN], [LoadedDate], [AuditID], [AuditItemID], [PhysicalFileRow], [ManufacturerID], [SampleSupplierPartyID], [MatchedODSPartyID], [PersonParentAuditItemID], [MatchedODSPersonID], [LanguageID], [PartySuppression], [OrganisationParentAuditItemID], [MatchedODSOrganisationID], [AddressParentAuditItemID], [MatchedODSAddressID], [CountryID], [PostalSuppression], [AddressChecksum], [MatchedODSTelID], [MatchedODSPrivTelID], [MatchedODSBusTelID], [MatchedODSMobileTelID], [MatchedODSPrivMobileTelID], [MatchedODSEmailAddressID], [MatchedODSPrivEmailAddressID], [EmailSuppression], [VehicleParentAuditItemID], [MatchedODSVehicleID], [ODSRegistrationID], [MatchedODSModelID], [OwnershipCycle], [MatchedODSEventID], [ODSEventTypeID], [SaleDateOrig], [SaleDate], [ServiceDateOrig], [ServiceDate], [InvoiceDateOrig], [InvoiceDate], [WarrantyID], [SalesDealerCodeOriginatorPartyID], [SalesDealerCode], [SalesDealerID], [ServiceDealerCodeOriginatorPartyID], [ServiceDealerCode], [ServiceDealerID], [RoadsideNetworkOriginatorPartyID], [RoadsideNetworkCode], [RoadsideNetworkPartyID], [RoadsideDate], [CRCCentreOriginatorPartyID], [CRCCentreCode], [CRCCentrePartyID], [CRCDate], [Brand], [Market], [Questionnaire], [QuestionnaireRequirementID], [StartDays], [EndDays], [SuppliedName], [SuppliedAddress], [SuppliedPhoneNumber], [SuppliedMobilePhone], [SuppliedEmail], [SuppliedVehicle], [SuppliedRegistration], [SuppliedEventDate], [EventDateOutOfDate], [EventNonSolicitation], [PartyNonSolicitation], [UnmatchedModel], [UncodedDealer], [EventAlreadySelected], [NonLatestEvent], [InvalidOwnershipCycle], [RecontactPeriod], [InvalidVehicleRole], [CrossBorderAddress], [CrossBorderDealer], [ExclusionListMatch], [InvalidEmailAddress], [BarredEmailAddress], [BarredDomain], [CaseID], [SampleRowProcessed], [SampleRowProcessedDate], [WrongEventType], [MissingStreet], [MissingPostcode], [MissingEmail], [MissingTelephone], [MissingStreetAndEmail], [MissingTelephoneAndEmail], [InvalidModel], [InvalidVariant], [MissingMobilePhone], [MissingMobilePhoneAndEmail], [MissingPartyName], [MissingLanguage], [CaseIDPrevious], [RelativeRecontactPeriod], [InvalidManufacturer], [InternalDealer], [EventDateTooYoung], [InvalidRoleType], [InvalidSaleType], [InvalidAFRLCode], [SuppliedAFRLCode], [DealerExclusionListMatch], [PhoneSuppression], [LostLeadDate], [ContactPreferencesSuppression], [NotInQuota], [ContactPreferencesPartySuppress], [ContactPreferencesEmailSuppress], [ContactPreferencesPhoneSuppress], [ContactPreferencesPostalSuppress], [DealerPilotOutputFiltered], [InvalidCRMSaleType], [MissingLostLeadAgency], [PDIFlagSet], [BodyshopEventDateOrig], [BodyshopEventDate], [BodyshopDealerCode], [BodyshopDealerID], [BodyshopDealerCodeOriginatorPartyID], [ContactPreferencesUnsubscribed], [SelectionOrganisationID], [SelectionPostalID], [SelectionEmailID], [SelectionPhoneID], [SelectionLandlineID], [SelectionMobileID], [NonSelectableWarrantyEvent], [IAssistanceCentreOriginatorPartyID], [IAssistanceCentreCode], [IAssistanceCentrePartyID], [IAssistanceDate], [InvalidDateOfLastContact], [CQIMissingExtraVehicleFeed], [GeneralEnquiryDate], [MissingPerson], [MissingOrganisation], [InvalidDealerBrand], [PreviousCaseDate], [CASES], [TOTAL])
		SELECT 
			SL.Market AS Market_,
			SL.Questionnaire AS Questionnaire_,
			SL.Brand AS Brand_,
			F.FileName,
			F.FileRowCount,
			SL.EndDays AS EndDays_,
			SL.StartDays AS StartDays_,
			SL.SaleDate AS Sale_Date,
			DATEADD(DD,SL.EndDays,(SELECT DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE() - 1), 0))) AS EndWindow,
			DATEADD(DD,SL.StartDays,(SELECT DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE() - 1), 0))) AS StartWindow,
			SL.CaseID AS CaseID_,
			R.Requirement,
			V.VIN,
			SL.LoadedDate, 
			SL.AuditID, 
			SL.AuditItemID, 
			SL.PhysicalFileRow, 
			SL.ManufacturerID, 
			SL.SampleSupplierPartyID, 
			SL.MatchedODSPartyID, 
			SL.PersonParentAuditItemID, 
			SL.MatchedODSPersonID, 
			SL.LanguageID, 
			SL.PartySuppression, 
			SL.OrganisationParentAuditItemID, 
			SL.MatchedODSOrganisationID, 
			SL.AddressParentAuditItemID, 
			SL.MatchedODSAddressID, 
			SL.CountryID, 
			SL.PostalSuppression, 
			SL.AddressChecksum, 
			SL.MatchedODSTelID, 
			SL.MatchedODSPrivTelID, 
			SL.MatchedODSBusTelID, 
			SL.MatchedODSMobileTelID, 
			SL.MatchedODSPrivMobileTelID, 
			SL.MatchedODSEmailAddressID, 
			SL.MatchedODSPrivEmailAddressID, 
			SL.EmailSuppression, 
			SL.VehicleParentAuditItemID, 
			SL.MatchedODSVehicleID, 
			SL.ODSRegistrationID, 
			SL.MatchedODSModelID, 
			SL.OwnershipCycle, 
			SL.MatchedODSEventID, 
			SL.ODSEventTypeID, 
			SL.SaleDateOrig, 
			SL.SaleDate, 
			SL.ServiceDateOrig, 
			SL.ServiceDate,
			SL.InvoiceDateOrig, 
			SL.InvoiceDate, 
			SL.WarrantyID, 
			SL.SalesDealerCodeOriginatorPartyID, 
			SL.SalesDealerCode, 
			SL.SalesDealerID, 
			SL.ServiceDealerCodeOriginatorPartyID, 
			SL.ServiceDealerCode, 
			SL.ServiceDealerID, 
			SL.RoadsideNetworkOriginatorPartyID, 
			SL.RoadsideNetworkCode, 
			SL.RoadsideNetworkPartyID, 
			SL.RoadsideDate, 
			SL.CRCCentreOriginatorPartyID, 
			SL.CRCCentreCode, 
			SL.CRCCentrePartyID, 
			SL.CRCDate, 
			SL.Brand, 
			SL.Market, 
			SL.Questionnaire, 
			SL.QuestionnaireRequirementID, 
			SL.StartDays, 
			SL.EndDays, 
			SL.SuppliedName, 
			SL.SuppliedAddress, 
			SL.SuppliedPhoneNumber, 
			SL.SuppliedMobilePhone, 
			SL.SuppliedEmail, 
			SL.SuppliedVehicle, 
			SL.SuppliedRegistration, 
			SL.SuppliedEventDate, 
			SL.EventDateOutOfDate, 
			SL.EventNonSolicitation, 
			SL.PartyNonSolicitation, 
			SL.UnmatchedModel, 
			SL.UncodedDealer, 
			SL.EventAlreadySelected, 
			SL.NonLatestEvent, 
			SL.InvalidOwnershipCycle, 
			SL.RecontactPeriod, 
			SL.InvalidVehicleRole, 
			SL.CrossBorderAddress, 
			SL.CrossBorderDealer, 
			SL.ExclusionListMatch, 
			SL.InvalidEmailAddress, 
			SL.BarredEmailAddress, 
			SL.BarredDomain, 
			SL.CaseID, 
			SL.SampleRowProcessed, 
			SL.SampleRowProcessedDate, 
			SL.WrongEventType, 
			SL.MissingStreet, 
			SL.MissingPostcode, 
			SL.MissingEmail, 
			SL.MissingTelephone, 
			SL.MissingStreetAndEmail, 
			SL.MissingTelephoneAndEmail, 
			SL.InvalidModel, 
			SL.InvalidVariant, 
			SL.MissingMobilePhone, 
			SL.MissingMobilePhoneAndEmail, 
			SL.MissingPartyName, 
			SL.MissingLanguage, 
			SL.CaseIDPrevious, 
			SL.RelativeRecontactPeriod, 
			SL.InvalidManufacturer, 
			SL.InternalDealer, 
			SL.EventDateTooYoung, 
			SL.InvalidRoleType, 
			SL.InvalidSaleType, 
			SL.InvalidAFRLCode, 
			SL.SuppliedAFRLCode, 
			SL.DealerExclusionListMatch, 
			SL.PhoneSuppression, 
			SL.LostLeadDate, 
			SL.ContactPreferencesSuppression, 
			SL.NotInQuota, 
			SL.ContactPreferencesPartySuppress, 
			SL.ContactPreferencesEmailSuppress, 
			SL.ContactPreferencesPhoneSuppress, 
			SL.ContactPreferencesPostalSuppress, 
			SL.DealerPilotOutputFiltered, 
			SL.InvalidCRMSaleType, 
			SL.MissingLostLeadAgency, 
			SL.PDIFlagSet, 
			SL.BodyshopEventDateOrig, 
			SL.BodyshopEventDate, 
			SL.BodyshopDealerCode, 
			SL.BodyshopDealerID, 
			SL.BodyshopDealerCodeOriginatorPartyID, 
			SL.ContactPreferencesUnsubscribed, 
			SL.SelectionOrganisationID, 
			SL.SelectionPostalID, 
			SL.SelectionEmailID, 
			SL.SelectionPhoneID, 
			SL.SelectionLandlineID, 
			SL.SelectionMobileID, 
			SL.NonSelectableWarrantyEvent, 
			SL.IAssistanceCentreOriginatorPartyID, 
			SL.IAssistanceCentreCode, 
			SL.IAssistanceCentrePartyID, 
			SL.IAssistanceDate, 
			SL.InvalidDateOfLastContact, 
			SL.CQIMissingExtraVehicleFeed, 
			SL.GeneralEnquiryDate, 
			SL.MissingPerson, 
			SL.MissingOrganisation, 
			SL.InvalidDealerBrand,
			CONVERT(VARCHAR, C.CreationDate, 103) AS PreviousCaseDate,
			CASE WHEN ISNULL(SL.CaseID,0) > 0 THEN 1
				 ELSE 0 END AS [CASES],
			1 AS TOTAL
		FROM [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL
			LEFT JOIN [$(SampleDB)].Vehicle.Vehicles V ON V.VehicleID = SL.MatchedODSVehicleID
			INNER JOIN [$(AuditDB)].dbo.Files F ON F.AuditID = SL.AuditID
			LEFT JOIN [$(AuditDB)].Audit.Registrations AR ON AR.AuditItemID = SL.AuditItemID
			LEFT JOIN [$(SampleDB)].Event.Cases C ON SL.CaseID = C.CaseID
			LEFT JOIN [$(SampleDB)].Requirement.SelectionCases SC ON SL.CaseID = SC.CaseID
			LEFT JOIN [$(SampleDB)].Requirement.Requirements R ON SC.RequirementIDPartOf = R.RequirementID
		WHERE F.ActionDate >= (SELECT DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE() - 1), 0))		-- MONDAY
			AND SL.Questionnaire LIKE 'CQI%'
		

		DROP TABLE IF EXISTS #Exclusions

		-- Count Exclusion/non selection flags
		SELECT 
			SUM(CASE WHEN SuppliedName = 1 THEN 1 ELSE 0 END) AS SuppliedName,
			SUM(CASE WHEN SuppliedAddress = 1 THEN 1 ELSE 0 END) AS SuppliedAddress,
			SUM(CASE WHEN SuppliedPhoneNumber = 1 THEN 1 ELSE 0 END) AS SuppliedPhoneNumber,
			SUM(CASE WHEN SuppliedMobilePhone = 1 THEN 1 ELSE 0 END) AS SuppliedMobilePhone,
			SUM(CASE WHEN SuppliedEmail = 1 THEN 1 ELSE 0 END) AS SuppliedEmail,
			SUM(CASE WHEN SuppliedEventDate = 1 THEN 1 ELSE 0 END) AS SuppliedEventDate,
			SUM(CASE WHEN SampleRowProcessed = 1 THEN 1 ELSE 0 END) AS SampleRowProcessed,
			SUM(CASE WHEN LEN(CaseID) > 1 THEN 1 ELSE 0 END) AS CASES,
			SUM(CASE WHEN EventDateOutOfDate = 1 THEN 1 ELSE 0 END) AS EventDateOutOfDate,
			SUM(CASE WHEN EventNonSolicitation = 1 THEN 1 ELSE 0 END) AS EventNonSolicitation,
			SUM(CASE WHEN PartyNonSolicitation = 1 THEN 1 ELSE 0 END) AS PartyNonSolicitation,
			SUM(CASE WHEN UnmatchedModel = 1 THEN 1 ELSE 0 END) AS UnmatchedModel,
			SUM(CASE WHEN UncodedDealer = 1 THEN 1 ELSE 0 END) AS UncodedDealer,
			SUM(CASE WHEN EventAlreadySelected = 1 THEN 1 ELSE 0 END) AS EventAlreadySelected,
			SUM(CASE WHEN NonLatestEvent = 1 THEN 1 ELSE 0 END) AS NonLatestEvent,
			SUM(CASE WHEN InvalidOwnershipCycle = 1 THEN 1 ELSE 0 END) AS InvalidOwnershipCycle,
			SUM(CASE WHEN RecontactPeriod = 1 THEN 1 ELSE 0 END) AS RecontactPeriod,
			SUM(CASE WHEN InvalidVehicleRole = 1 THEN 1 ELSE 0 END) AS InvalidVehicleRole,
			SUM(CASE WHEN CrossBorderAddress = 1 THEN 1 ELSE 0 END) AS CrossBorderAddress,
			SUM(CASE WHEN CrossBorderDealer = 1 THEN 1 ELSE 0 END) AS CrossBorderDealer,
			SUM(CASE WHEN ExclusionListMatch = 1 THEN 1 ELSE 0 END) AS ExclusionListMatch,
			SUM(CASE WHEN InvalidEmailAddress = 1 THEN 1 ELSE 0 END) AS InvalidEmailAddress,
			SUM(CASE WHEN BarredEmailAddress = 1 THEN 1 ELSE 0 END) AS BarredEmailAddress,
			SUM(CASE WHEN BarredDomain = 1 THEN 1 ELSE 0 END) AS BarredDomain,
			SUM(CASE WHEN WrongEventType = 1 THEN 1 ELSE 0 END) AS WrongEventType,
			SUM(CASE WHEN MissingStreet = 1 THEN 1 ELSE 0 END) AS MissingStreet,
			SUM(CASE WHEN MissingPostcode = 1 THEN 1 ELSE 0 END) AS MissingPostcode,
			SUM(CASE WHEN MissingEmail = 1 THEN 1 ELSE 0 END) AS MissingEmail,
			SUM(CASE WHEN MissingTelephone = 1 THEN 1 ELSE 0 END) AS MissingTelephone,
			SUM(CASE WHEN MissingStreetAndEmail = 1 THEN 1 ELSE 0 END) AS MissingStreetAndEmail,
			SUM(CASE WHEN MissingTelephoneAndEmail = 1 THEN 1 ELSE 0 END) AS MissingTelephoneAndEmail,
			SUM(CASE WHEN InvalidModel = 1 THEN 1 ELSE 0 END) AS InvalidModel,
			SUM(CASE WHEN InvalidVariant = 1 THEN 1 ELSE 0 END) AS InvalidVariant,
			SUM(CASE WHEN MissingMobilePhone = 1 THEN 1 ELSE 0 END) AS MissingMobilePhone,
			SUM(CASE WHEN MissingMobilePhoneAndEmail = 1 THEN 1 ELSE 0 END) AS MissingMobilePhoneAndEmail,
			SUM(CASE WHEN MissingPartyName = 1 THEN 1 ELSE 0 END) AS MissingPartyName,
			SUM(CASE WHEN MissingLanguage = 1 THEN 1 ELSE 0 END) AS MissingLanguage,
			SUM(CASE WHEN CaseIDPrevious = 1 THEN 1 ELSE 0 END) AS CaseIDPrevious,
			SUM(CASE WHEN RelativeRecontactPeriod = 1 THEN 1 ELSE 0 END) AS RelativeRecontactPeriod,
			SUM(CASE WHEN InvalidManufacturer = 1 THEN 1 ELSE 0 END) AS InvalidManufacturer,
			SUM(CASE WHEN InternalDealer = 1 THEN 1 ELSE 0 END) AS InternalDealer,
			SUM(CASE WHEN EventDateTooYoung = 1 THEN 1 ELSE 0 END) AS EventDateTooYoung,
			SUM(CASE WHEN InvalidRoleType = 1 THEN 1 ELSE 0 END) AS InvalidRoleType,
			SUM(CASE WHEN InvalidSaleType = 1 THEN 1 ELSE 0 END) AS InvalidSaleType,
			SUM(CASE WHEN InvalidAFRLCode = 1 THEN 1 ELSE 0 END) AS InvalidAFRLCode,
			SUM(CASE WHEN SuppliedAFRLCode = 1 THEN 1 ELSE 0 END) AS SuppliedAFRLCode,
			SUM(CASE WHEN DealerExclusionListMatch = 1 THEN 1 ELSE 0 END) AS DealerExclusionListMatch,
			SUM(CASE WHEN PhoneSuppression = 1 THEN 1 ELSE 0 END) AS PhoneSuppression,
			SUM(CASE WHEN ContactPreferencesSuppression = 1 THEN 1 ELSE 0 END) AS ContactPreferencesSuppression,
			SUM(CASE WHEN NotInQuota = 1 THEN 1 ELSE 0 END) AS NotInQuota,
			SUM(CASE WHEN ContactPreferencesPartySuppress = 1 THEN 1 ELSE 0 END) AS ContactPreferencesPartySuppress,
			SUM(CASE WHEN ContactPreferencesEmailSuppress = 1 THEN 1 ELSE 0 END) AS ContactPreferencesEmailSuppress,
			SUM(CASE WHEN ContactPreferencesPhoneSuppress = 1 THEN 1 ELSE 0 END) AS ContactPreferencesPhoneSuppress,
			SUM(CASE WHEN ContactPreferencesPostalSuppress = 1 THEN 1 ELSE 0 END) AS ContactPreferencesPostalSuppress,
			SUM(CASE WHEN DealerPilotOutputFiltered = 1 THEN 1 ELSE 0 END) AS DealerPilotOutputFiltered,
			SUM(CASE WHEN InvalidCRMSaleType = 1 THEN 1 ELSE 0 END) AS InvalidCRMSaleType,
			SUM(CASE WHEN MissingLostLeadAgency = 1 THEN 1 ELSE 0 END) AS MissingLostLeadAgency,
			SUM(CASE WHEN PDIFlagSet = 1 THEN 1 ELSE 0 END) AS PDIFlagSet,
			SUM(CASE WHEN ContactPreferencesUnsubscribed = 1 THEN 1 ELSE 0 END) AS ContactPreferencesUnsubscribed,
			SUM(CASE WHEN NonSelectableWarrantyEvent = 1 THEN 1 ELSE 0 END) AS NonSelectableWarrantyEvent,
			SUM(CASE WHEN IAssistanceCentreOriginatorPartyID = 1 THEN 1 ELSE 0 END) AS IAssistanceCentreOriginatorPartyID,
			SUM(CASE WHEN IAssistanceCentreCode = 1 THEN 1 ELSE 0 END) AS IAssistanceCentreCode,
			SUM(CASE WHEN IAssistanceCentrePartyID = 1 THEN 1 ELSE 0 END) AS IAssistanceCentrePartyID,
			SUM(CASE WHEN InvalidDateOfLastContact = 1 THEN 1 ELSE 0 END) AS InvalidDateOfLastContact,
			SUM(CASE WHEN CQIMissingExtraVehicleFeed = 1 THEN 1 ELSE 0 END) AS CQIMissingExtraVehicleFeed,
			SUM(CASE WHEN MissingPerson = 1 THEN 1 ELSE 0 END) AS MissingPerson,
			SUM(CASE WHEN MissingOrganisation = 1 THEN 1 ELSE 0 END) AS MissingOrganisation,
			SUM(CASE WHEN InvalidDealerBrand = 1 THEN 1 ELSE 0 END) AS InvalidDealerBrand,
			COUNT(*) AS Total
		INTO #Exclusions
		FROM SampleReport.DispoCQI


		--"SampleReport.DataFeedCQI" tab in Excel template
		INSERT INTO SampleReport.ReasonForNonSelectionCQI
		SELECT Exclusion, TotalCount
		FROM #Exclusions
		UNPIVOT
			(
				TotalCount
				FOR Exclusion IN 
				(
					SuppliedAddress, 
					SuppliedPhoneNumber, 
					SuppliedMobilePhone, 
					SuppliedEmail, 
					SuppliedEventDate, 
					SampleRowProcessed, 
					CASES, 
					EventDateOutOfDate, 
					EventNonSolicitation, 
					PartyNonSolicitation, 
					UnmatchedModel, 
					UncodedDealer, 
					EventAlreadySelected, 
					NonLatestEvent, 
					InvalidOwnershipCycle, 
					RecontactPeriod, 
					InvalidVehicleRole, 
					CrossBorderAddress, 
					CrossBorderDealer, 
					ExclusionListMatch, 
					InvalidEmailAddress, 
					BarredEmailAddress, 
					BarredDomain, 
					WrongEventType, 
					MissingStreet, 
					MissingPostcode, 
					MissingEmail, 
					MissingTelephone, 
					MissingStreetAndEmail, 
					MissingTelephoneAndEmail, 
					InvalidModel, 
					InvalidVariant, 
					MissingMobilePhone, 
					MissingMobilePhoneAndEmail, 
					MissingPartyName, 
					MissingLanguage, 
					CaseIDPrevious, 
					RelativeRecontactPeriod, 
					InvalidManufacturer, 
					InternalDealer, 
					EventDateTooYoung, 
					InvalidRoleType, 
					InvalidSaleType, 
					InvalidAFRLCode, 
					SuppliedAFRLCode, 
					DealerExclusionListMatch, 
					PhoneSuppression, 
					ContactPreferencesSuppression, 
					NotInQuota, 
					ContactPreferencesPartySuppress, 
					ContactPreferencesEmailSuppress, 
					ContactPreferencesPhoneSuppress, 
					ContactPreferencesPostalSuppress, 
					DealerPilotOutputFiltered, 
					InvalidCRMSaleType, 
					MissingLostLeadAgency, 
					PDIFlagSet, 
					ContactPreferencesUnsubscribed, 
					NonSelectableWarrantyEvent, 
					IAssistanceCentreOriginatorPartyID, 
					IAssistanceCentreCode, 
					IAssistanceCentrePartyID, 
					InvalidDateOfLastContact, 
					CQIMissingExtraVehicleFeed, 
					MissingPerson, 
					MissingOrganisation, 
					InvalidDealerBrand,
					Total
				)	
			) U

		--Remove zero counts
		DELETE 
		FROM SampleReport.ReasonForNonSelectionCQI
		WHERE TotalCount = 0
	

		--"CQI Data" tab in Excel template
		;WITH CTE_CQIMarket AS 
		(
			SELECT SM.Market,
				SM.Brand,
				SM.Questionnaire,
				SM.QuestionnaireRequirementID
			FROM [$(SampleDB)].dbo.vwBrandMarketQuestionnaireSampleMetadata SM
			WHERE SM.Questionnaire IN ('CQI 3MIS','CQI 24MIS')
				AND SM.SampleLoadActive = 1
			GROUP BY SM.Market,
				SM.Brand,
				SM.Questionnaire,
				SM.QuestionnaireRequirementID

			UNION -- V1.1

			SELECT SM.Market,
				SM.Brand,
				SM.Questionnaire,
				SM.QuestionnaireRequirementID
			FROM [$(SampleDB)].dbo.vwBrandMarketQuestionnaireSampleMetadata SM
			WHERE SM.SelectionName IN ('CQI JAG FRA 3MIS','CQI JAG FRA 24MIS','CQI LR FRA 3MIS','CQI LR FRA 24MIS',
									   'CQI JAG NLD 3MIS','CQI JAG NLD 24MIS','CQI LR NLD 3MIS','CQI LR NLD 24MIS')
			GROUP BY SM.Market,
				SM.Brand,
				SM.Questionnaire,
				SM.QuestionnaireRequirementID

		)
		INSERT INTO SampleReport.DataFeedCQI ([Market], [Brand], [Questionnaire], [Requirement], [SelectionDate], [CaseID], [SaleDate], [Week], [Week Starting], [DATA])
		SELECT M.Market,
			M.Brand,
			M.Questionnaire,
			R.Requirement,
			CAST(SR.SelectionDate AS DATE) AS SelectionDate,
			CD.CaseID,
			CAST(CD.EventDate AS DATE) AS SaleDate,
			DATEPART(WW,CD.EventDate) AS [Week],
			CAST(DATEADD(DD, 1 - DATEPART(DW, CD.EventDate), CD.EventDate) AS DATE) AS [Week Starting],	 
			1 AS DATA
		FROM [$(SampleDB)].Requirement.SelectionRequirements SR
			INNER JOIN [$(SampleDB)].Requirement.RequirementRollups RR ON SR.RequirementID = RR.RequirementIDMadeUpOf
			INNER JOIN CTE_CQIMarket M ON RR.RequirementIDPartOf = M.QuestionnaireRequirementID
			INNER JOIN [$(SampleDB)].Requirement.Requirements R ON SR.RequirementID = R.RequirementID
			INNER JOIN [$(SampleDB)].Requirement.SelectionCases SC ON SR.RequirementID = SC.RequirementIDPartOf
			INNER JOIN [$(SampleDB)].Meta.CaseDetails CD ON SC.CaseID = CD.CaseID
		WHERE SR.ScheduledRunDate >= '2021-01-01'	


END TRY


BEGIN CATCH

	SELECT
		 @ErrorNumber = Error_Number()
		,@ErrorSeverity = Error_Severity()
		,@ErrorState = Error_State()
		,@ErrorLocation = Error_Procedure()
		,@ErrorLine = Error_Line()
		,@ErrorMessage = Error_Message()

	EXEC [$(ErrorDB)].dbo.uspLogDatabaseError
		 @ErrorNumber
		,@ErrorSeverity
		,@ErrorState
		,@ErrorLocation
		,@ErrorLine
		,@ErrorMessage
		
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH

GO
