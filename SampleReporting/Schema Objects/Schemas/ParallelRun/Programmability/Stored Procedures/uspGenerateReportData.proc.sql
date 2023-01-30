CREATE PROCEDURE [ParallelRun].[uspGenerateReportData]

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
	Purpose:	Populates the Parallel Run Reporting tables
		
	Version		Date				Developer			Comment
	1.0			16/07/2019			Chris Ledger		Populate Reporting Tables		
	1.1			29/07/2019			Chris Ledger		Edit MismatchChecking
	1.2			02/08/2019			Chris Ledger		Add Update MatchedIDNew fields
	1.3			15/01/2020			Chris Ledger 		BUG 15372 - Fix cases
	
*/

	--DECLARE @DateLastRun DATETIME

	--SELECT  @DateLastRun = 
	--	MAX(
	--	DATEADD(SECOND,
	--	((h.run_duration / 1000000) * 86400)
	--		+ (((h.run_duration - ((h.run_duration / 1000000)* 1000000)) / 10000) * 3600)
	--		+ (((h.run_duration - ((h.run_duration / 10000) * 10000)) / 100) * 60) + (h.run_duration - (h.run_duration / 100) * 100), 
	--	CAST(STR(h.run_date, 8, 0) AS DATETIME)
	--		+ CAST(STUFF(STUFF(RIGHT('000000'
	--		+ CAST (h.run_time AS VARCHAR(6)), 6), 5, 0, ':'), 3, 0, ':') AS DATETIME)))
	--FROM msdb..sysjobhistory h
	--INNER JOIN msdb..sysjobs j ON j.job_id = h.job_id
	--WHERE h.step_name = 'ReIndex Tables'		-- V1.6 ReIndex Step (i.e. all required steps completed N.B. last 2 steps always run)
	--AND h.run_status = 1 
	--AND j.name = N'Sample Load and Selection'

	--SET @DateLastRun = (SELECT RD.SystemRefreshDate FROM ParallelRun.RefreshDate RD)

	DECLARE @DateLastRun DateTime = '2019-07-22 06:00'

	TRUNCATE TABLE [ParallelRun].[FileSummary]
	TRUNCATE TABLE [ParallelRun].[SelectionSummary]
	TRUNCATE TABLE [ParallelRun].[MismatchChecking]
	TRUNCATE TABLE [ParallelRun].[MismatchEmailAddresses]
	TRUNCATE TABLE [ParallelRun].[MismatchMiniDispo]
	TRUNCATE TABLE [ParallelRun].[MismatchOrganisations]
	TRUNCATE TABLE [ParallelRun].[MismatchPeople]
	TRUNCATE TABLE [ParallelRun].[MismatchPostalAddresses]
	TRUNCATE TABLE [ParallelRun].[MismatchRegistrations]
	TRUNCATE TABLE [ParallelRun].[MismatchSelections]
	TRUNCATE TABLE [ParallelRun].[MismatchSummary]
	TRUNCATE TABLE [ParallelRun].[MismatchTelephoneNumbers]
	TRUNCATE TABLE [ParallelRun].[MismatchVehicles]


	-- Mismatch Summary
	--DROP TABLE #Summary
	SELECT
	SUM([Mismatch_ManufacturerID]) AS [Mismatch_ManufacturerID],
	SUM([Mismatch_SampleSupplierPartyID]) AS [Mismatch_SampleSupplierPartyID],
	--SUM([Mismatch_MatchedODSPartyID]) AS [Mismatch_MatchedODSPartyID],
	(SUM([Mismatch_MatchedODSPersonID])-SUM(ISNULL([MatchedODSPersonIDNew],0))) AS [Mismatch_MatchedODSPersonIDExclNew],
	SUM([Mismatch_LanguageID]) AS [Mismatch_LanguageID],
	SUM([Mismatch_PartySuppression]) AS [Mismatch_PartySuppression],
	(SUM([Mismatch_MatchedODSOrganisationID])-SUM(ISNULL([MatchedODSOrganisationIDNew],0))) AS [Mismatch_MatchedODSOrganisationIDExclNew],
	(SUM([Mismatch_MatchedODSAddressID]) - SUM(ISNULL([MatchedODSAddressIDNew],0))) AS [Mismatch_MatchedODSAddressIDExclNew],
	SUM([Mismatch_CountryID]) AS [Mismatch_CountryID],
	SUM([Mismatch_PostalSuppression]) AS [Mismatch_PostalSuppression],
	SUM([Mismatch_AddressChecksum]) AS [Mismatch_AddressChecksum],
	(SUM([Mismatch_MatchedODSTelID]) - SUM(ISNULL([MatchedODSTelIDNew],0))) AS [Mismatch_MatchedODSTelIDExclNew],
	(SUM([Mismatch_MatchedODSPrivTelID]) - SUM(ISNULL([MatchedODSPrivTelIDNew],0)))  AS [Mismatch_MatchedODSPrivTelIDExclNew],
	(SUM([Mismatch_MatchedODSBusTelID]) - SUM(ISNULL([MatchedODSBusTelIDNew],0))) AS [Mismatch_MatchedODSBusTelIDExclNew],
	(SUM([Mismatch_MatchedODSMobileTelID]) - SUM(ISNULL([MatchedODSMobileTelIDNew],0))) AS [Mismatch_MatchedODSMobileTelIDExclNew],
	SUM([Mismatch_MatchedODSPrivMobileTelID]) AS [Mismatch_MatchedODSPrivMobileTelID],
	(SUM([Mismatch_MatchedODSEmailAddressID]) - SUM(ISNULL([MatchedODSEmailAddressIDNew],0))) AS [Mismatch_MatchedODSEmailAddressIDExclNew],
	(SUM([Mismatch_MatchedODSPrivEmailAddressID]) - SUM(ISNULL([MatchedODSPrivEmailAddressIDNew],0))) AS [Mismatch_MatchedODSPrivEmailAddressIDExclNew],
	SUM([Mismatch_EmailSuppression]) AS [Mismatch_EmailSuppression],
	(SUM([Mismatch_MatchedODSVehicleID]) - SUM(ISNULL([MatchedODSVehicleIDNew],0))) AS [Mismatch_MatchedODSVehicleIDExclNew],
	SUM([Mismatch_ODSRegistrationID]) AS [Mismatch_ODSRegistrationID],
	SUM([Mismatch_MatchedODSModelID]) AS [Mismatch_MatchedODSModelID],
	SUM([Mismatch_OwnershipCycle]) AS [Mismatch_OwnershipCycle],
	(SUM([Mismatch_MatchedODSEventID]) - SUM(ISNULL([MatchedODSEventIDNew],0))) AS [Mismatch_MatchedODSEventIDExclNew],
	SUM([Mismatch_ODSEventTypeID]) AS [Mismatch_ODSEventTypeID],
	SUM([Mismatch_SaleDateOrig]) AS [Mismatch_SaleDateOrig],
	SUM([Mismatch_SaleDate]) AS [Mismatch_SaleDate],
	SUM([Mismatch_ServiceDateOrig]) AS [Mismatch_ServiceDateOrig],
	SUM([Mismatch_ServiceDate]) AS [Mismatch_ServiceDate],
	SUM([Mismatch_InvoiceDateOrig]) AS [Mismatch_InvoiceDateOrig],
	SUM([Mismatch_InvoiceDate]) AS [Mismatch_InvoiceDate],
	SUM([Mismatch_WarrantyID]) AS [Mismatch_WarrantyID],
	SUM([Mismatch_SalesDealerCodeOriginatorPartyID]) AS [Mismatch_SalesDealerCodeOriginatorPartyID],
	SUM([Mismatch_SalesDealerCode]) AS [Mismatch_SalesDealerCode],
	SUM([Mismatch_SalesDealerID]) AS [Mismatch_SalesDealerID],
	SUM([Mismatch_ServiceDealerCodeOriginatorPartyID]) AS [Mismatch_ServiceDealerCodeOriginatorPartyID],
	SUM([Mismatch_ServiceDealerCode]) AS [Mismatch_ServiceDealerCode],
	SUM([Mismatch_ServiceDealerID]) AS [Mismatch_ServiceDealerID],
	SUM([Mismatch_RoadsideNetworkOriginatorPartyID]) AS [Mismatch_RoadsideNetworkOriginatorPartyID],
	SUM([Mismatch_RoadsideNetworkCode]) AS [Mismatch_RoadsideNetworkCode],
	SUM([Mismatch_RoadsideNetworkPartyID]) AS [Mismatch_RoadsideNetworkPartyID],
	SUM([Mismatch_RoadsideDate]) AS [Mismatch_RoadsideDate],
	SUM([Mismatch_CRCCentreOriginatorPartyID]) AS [Mismatch_CRCCentreOriginatorPartyID],
	SUM([Mismatch_CRCCentreCode]) AS [Mismatch_CRCCentreCode],
	SUM([Mismatch_CRCCentrePartyID]) AS [Mismatch_CRCCentrePartyID],
	SUM([Mismatch_CRCDate]) AS [Mismatch_CRCDate],
	SUM([Mismatch_Brand]) AS [Mismatch_Brand],
	SUM([Mismatch_Market]) AS [Mismatch_Market],
	SUM([Mismatch_Questionnaire]) AS [Mismatch_Questionnaire],
	SUM([Mismatch_QuestionnaireRequirementID]) AS [Mismatch_QuestionnaireRequirementID],
	SUM([Mismatch_StartDays]) AS [Mismatch_StartDays],
	SUM([Mismatch_EndDays]) AS [Mismatch_EndDays],
	SUM([Mismatch_SuppliedName]) AS [Mismatch_SuppliedName],
	SUM([Mismatch_SuppliedAddress]) AS [Mismatch_SuppliedAddress],
	SUM([Mismatch_SuppliedPhoneNumber]) AS [Mismatch_SuppliedPhoneNumber],
	SUM([Mismatch_SuppliedMobilePhone]) AS [Mismatch_SuppliedMobilePhone],
	SUM([Mismatch_SuppliedEmail]) AS [Mismatch_SuppliedEmail],
	SUM([Mismatch_SuppliedVehicle]) AS [Mismatch_SuppliedVehicle],
	SUM([Mismatch_SuppliedRegistration]) AS [Mismatch_SuppliedRegistration],
	SUM([Mismatch_SuppliedEventDate]) AS [Mismatch_SuppliedEventDate],
	SUM([Mismatch_EventDateOutOfDate]) AS [Mismatch_EventDateOutOfDate],
	SUM([Mismatch_EventNonSolicitation]) AS [Mismatch_EventNonSolicitation],
	SUM([Mismatch_PartyNonSolicitation]) AS [Mismatch_PartyNonSolicitation],
	SUM([Mismatch_UnmatchedModel]) AS [Mismatch_UnmatchedModel],
	SUM([Mismatch_UncodedDealer]) AS [Mismatch_UncodedDealer],
	SUM([Mismatch_EventAlreadySelected]) AS [Mismatch_EventAlreadySelected],
	SUM([Mismatch_NonLatestEvent]) AS [Mismatch_NonLatestEvent],
	SUM([Mismatch_InvalidOwnershipCycle]) AS [Mismatch_InvalidOwnershipCycle],
	SUM([Mismatch_RecontactPeriod]) AS [Mismatch_RecontactPeriod],
	SUM([Mismatch_InvalidVehicleRole]) AS [Mismatch_InvalidVehicleRole],
	SUM([Mismatch_CrossBorderAddress]) AS [Mismatch_CrossBorderAddress],
	SUM([Mismatch_CrossBorderDealer]) AS [Mismatch_CrossBorderDealer],
	SUM([Mismatch_ExclusionListMatch]) AS [Mismatch_ExclusionListMatch],
	SUM([Mismatch_InvalidEmailAddress]) AS [Mismatch_InvalidEmailAddress],
	SUM([Mismatch_BarredEmailAddress]) AS [Mismatch_BarredEmailAddress],
	SUM([Mismatch_BarredDomain]) AS [Mismatch_BarredDomain],
	--SUM([Mismatch_CaseID]) AS [Mismatch_CaseID],
	SUM([Mismatched_CaseCreation]) AS [Mismatched_CaseCreation],
	SUM([Mismatch_SampleRowProcessed]) AS [Mismatch_SampleRowProcessed],
	SUM([Mismatch_SampleRowProcessedDate]) AS [Mismatch_SampleRowProcessedDate],
	SUM([Mismatch_WrongEventType]) AS [Mismatch_WrongEventType],
	SUM([Mismatch_MissingStreet]) AS [Mismatch_MissingStreet],
	SUM([Mismatch_MissingPostcode]) AS [Mismatch_MissingPostcode],
	SUM([Mismatch_MissingEmail]) AS [Mismatch_MissingEmail],
	SUM([Mismatch_MissingTelephone]) AS [Mismatch_MissingTelephone],
	SUM([Mismatch_MissingStreetAndEmail]) AS [Mismatch_MissingStreetAndEmail],
	SUM([Mismatch_MissingTelephoneAndEmail]) AS [Mismatch_MissingTelephoneAndEmail],
	SUM([Mismatch_InvalidModel]) AS [Mismatch_InvalidModel],
	SUM([Mismatch_InvalidVariant]) AS [Mismatch_InvalidVariant],
	SUM([Mismatch_MissingMobilePhone]) AS [Mismatch_MissingMobilePhone],
	SUM([Mismatch_MissingMobilePhoneAndEmail]) AS [Mismatch_MissingMobilePhoneAndEmail],
	SUM([Mismatch_MissingPartyName]) AS [Mismatch_MissingPartyName],
	SUM([Mismatch_MissingLanguage]) AS [Mismatch_MissingLanguage],
	SUM([Mismatch_CaseIDPrevious]) AS [Mismatch_CaseIDPrevious],
	SUM([Mismatch_RelativeRecontactPeriod]) AS [Mismatch_RelativeRecontactPeriod],
	SUM([Mismatch_InvalidManufacturer]) AS [Mismatch_InvalidManufacturer],
	SUM([Mismatch_InternalDealer]) AS [Mismatch_InternalDealer],
	SUM([Mismatch_EventDateTooYoung]) AS [Mismatch_EventDateTooYoung],
	SUM([Mismatch_InvalidRoleType]) AS [Mismatch_InvalidRoleType],
	SUM([Mismatch_InvalidSaleType]) AS [Mismatch_InvalidSaleType],
	SUM([Mismatch_InvalidAFRLCode]) AS [Mismatch_InvalidAFRLCode],
	SUM([Mismatch_SuppliedAFRLCode]) AS [Mismatch_SuppliedAFRLCode],
	SUM([Mismatch_DealerExclusionListMatch]) AS [Mismatch_DealerExclusionListMatch],
	SUM([Mismatch_PhoneSuppression]) AS [Mismatch_PhoneSuppression],
	SUM([Mismatch_LostLeadDate]) AS [Mismatch_LostLeadDate],
	SUM([Mismatch_ContactPreferencesSuppression]) AS [Mismatch_ContactPreferencesSuppression],
	SUM([Mismatch_NotInQuota]) AS [Mismatch_NotInQuota],
	SUM([Mismatch_ContactPreferencesPartySuppress]) AS [Mismatch_ContactPreferencesPartySuppress],
	SUM([Mismatch_ContactPreferencesEmailSuppress]) AS [Mismatch_ContactPreferencesEmailSuppress],
	SUM([Mismatch_ContactPreferencesPhoneSuppress]) AS [Mismatch_ContactPreferencesPhoneSuppress],
	SUM([Mismatch_ContactPreferencesPostalSuppress]) AS [Mismatch_ContactPreferencesPostalSuppress],
	SUM([Mismatch_DealerPilotOutputFiltered]) AS [Mismatch_DealerPilotOutputFiltered],
	SUM([Mismatch_InvalidCRMSaleType]) AS [Mismatch_InvalidCRMSaleType],
	SUM([Mismatch_MissingLostLeadAgency]) AS [Mismatch_MissingLostLeadAgency],
	SUM([Mismatch_PDIFlagSet]) AS [Mismatch_PDIFlagSet],
	SUM([Mismatch_BodyshopEventDateOrig]) AS [Mismatch_BodyshopEventDateOrig],
	SUM([Mismatch_BodyshopEventDate]) AS [Mismatch_BodyshopEventDate],
	SUM([Mismatch_BodyshopDealerCode]) AS [Mismatch_BodyshopDealerCode],
	SUM([Mismatch_BodyshopDealerID]) AS [Mismatch_BodyshopDealerID],
	SUM([Mismatch_BodyshopDealerCodeOriginatorPartyID]) AS [Mismatch_BodyshopDealerCodeOriginatorPartyID],
	SUM([Mismatch_ContactPreferencesUnsubscribed]) AS [Mismatch_ContactPreferencesUnsubscribed],
	(SUM([Mismatch_SelectionOrganisationID]) - SUM(ISNULL([SelectionOrganisationIDNew],0))) AS [Mismatch_SelectionOrganisationIDExclNew],
	(SUM([Mismatch_SelectionPostalID]) - SUM(ISNULL([SelectionPostalIDNew],0))) AS [Mismatch_SelectionPostalIDExclNew],
	(SUM([Mismatch_SelectionEmailID]) - SUM(ISNULL([SelectionEmailIDNew],0))) AS [Mismatch_SelectionEmailIDExclNew],
	(SUM([Mismatch_SelectionPhoneID]) - SUM(ISNULL([SelectionPhoneIDNew],0))) AS [Mismatch_SelectionPhoneIDExclNew],
	(SUM([Mismatch_SelectionLandlineID]) - SUM(ISNULL([SelectionLandlineIDNew],0))) AS [Mismatch_SelectionLandlineIDExclNew],
	(SUM([Mismatch_SelectionMobileID]) - SUM(ISNULL([SelectionMobileIDNew],0))) AS [Mismatch_SelectionMobileIDExclNew],
	SUM([Mismatch_NonSelectableWarrantyEvent]) AS [Mismatch_NonSelectableWarrantyEvent],
	SUM([Mismatch_IAssistanceCentreOriginatorPartyID]) AS [Mismatch_IAssistanceCentreOriginatorPartyID],
	SUM([Mismatch_IAssistanceCentreCode]) AS [Mismatch_IAssistanceCentreCode],
	SUM([Mismatch_IAssistanceCentrePartyID]) AS [Mismatch_IAssistanceCentrePartyID],
	SUM([Mismatch_IAssistanceDate]) AS [Mismatch_IAssistanceDate],
	SUM([Mismatch_InvalidDateOfLastContact]) AS [Mismatch_InvalidDateOfLastContact]
	INTO #Summary
	FROM ParallelRun.Comparisons_SampleQualityAndSelectionLogging CSL
	GROUP BY [ComparisonLoadDate]

	DECLARE @colsUnpivot AS VARCHAR(MAX)
	DECLARE @query  AS VARCHAR(MAX)

	--SELECT *
	--FROM tempdb.sys.columns c
	--WHERE c.object_id = OBJECT_ID('tempdb..#Summary') 
	 
	SELECT @colsUnpivot 
	  = stuff((SELECT ','+quotename(C.name)
			   FROM tempdb.sys.columns c
			   WHERE c.object_id = OBJECT_ID('tempdb..#Summary') 
			   FOR XML PATH('')), 1, 1, '')

	SET @query 
	  = 'SELECT Field, Data 
	  FROM (SELECT * FROM #Summary) p
		 UNPIVOT
		 (
			Data
			FOR Field IN ('+ @colsunpivot +')
		 ) u'

	--PRINT @query;
	EXEC @query;




	-- Mismatch Checking
	;WITH CTE_Comparisons_SampleQualityAndSelectionLogging ([ComparisonLoadDate], [FileName], [PhysicalFileRow], [RemoteLoadedDate], [LocalLoadedDate], [Mismatch_LoadedDay], [RemoteAuditID], [LocalAuditID], [RemoteAuditItemID], [LocalAuditItemID], [Mismatch_ManufacturerID], [Mismatch_SampleSupplierPartyID], [Mismatch_MatchedODSPartyID], [Mismatch_MatchedODSPersonID], [Mismatch_LanguageID], [Mismatch_PartySuppression], [Mismatch_MatchedODSOrganisationID], [Mismatch_MatchedODSAddressID], [Mismatch_CountryID], [Mismatch_PostalSuppression], [Mismatch_AddressChecksum], [Mismatch_MatchedODSTelID], [Mismatch_MatchedODSPrivTelID], [Mismatch_MatchedODSBusTelID], [Mismatch_MatchedODSMobileTelID], [Mismatch_MatchedODSPrivMobileTelID], [Mismatch_MatchedODSEmailAddressID], [Mismatch_MatchedODSPrivEmailAddressID], [Mismatch_EmailSuppression], [Mismatch_VehicleParentAuditItemID], [Mismatch_MatchedODSVehicleID], [Mismatch_ODSRegistrationID], [Mismatch_MatchedODSModelID], [Mismatch_OwnershipCycle], [Mismatch_MatchedODSEventID], [Mismatch_ODSEventTypeID], [Mismatch_SaleDateOrig], [Mismatch_SaleDate], [Mismatch_ServiceDateOrig], [Mismatch_ServiceDate], [Mismatch_InvoiceDateOrig], [Mismatch_InvoiceDate], [Mismatch_WarrantyID], [Mismatch_SalesDealerCodeOriginatorPartyID], [Mismatch_SalesDealerCode], [Mismatch_SalesDealerID], [Mismatch_ServiceDealerCodeOriginatorPartyID], [Mismatch_ServiceDealerCode], [Mismatch_ServiceDealerID], [Mismatch_RoadsideNetworkOriginatorPartyID], [Mismatch_RoadsideNetworkCode], [Mismatch_RoadsideNetworkPartyID], [Mismatch_RoadsideDate], [Mismatch_CRCCentreOriginatorPartyID], [Mismatch_CRCCentreCode], [Mismatch_CRCCentrePartyID], [Mismatch_CRCDate], [Mismatch_Brand], [Mismatch_Market], [Mismatch_Questionnaire], [Mismatch_QuestionnaireRequirementID], [Mismatch_StartDays], [Mismatch_EndDays], [Mismatch_SuppliedName], [Mismatch_SuppliedAddress], [Mismatch_SuppliedPhoneNumber], [Mismatch_SuppliedMobilePhone], [Mismatch_SuppliedEmail], [Mismatch_SuppliedVehicle], [Mismatch_SuppliedRegistration], [Mismatch_SuppliedEventDate], [Mismatch_EventDateOutOfDate], [Mismatch_EventNonSolicitation], [Mismatch_PartyNonSolicitation], [Mismatch_UnmatchedModel], [Mismatch_UncodedDealer], [Mismatch_EventAlreadySelected], [Mismatch_NonLatestEvent], [Mismatch_InvalidOwnershipCycle], [Mismatch_RecontactPeriod], [Mismatch_InvalidVehicleRole], [Mismatch_CrossBorderAddress], [Mismatch_CrossBorderDealer], [Mismatch_ExclusionListMatch], [Mismatch_InvalidEmailAddress], [Mismatch_BarredEmailAddress], [Mismatch_BarredDomain], [Mismatch_CaseID], [Mismatched_CaseCreation], [Mismatch_SampleRowProcessed], [Mismatch_SampleRowProcessedDate], [Mismatch_WrongEventType], [Mismatch_MissingStreet], [Mismatch_MissingPostcode], [Mismatch_MissingEmail], [Mismatch_MissingTelephone], [Mismatch_MissingStreetAndEmail], [Mismatch_MissingTelephoneAndEmail], [Mismatch_InvalidModel], [Mismatch_InvalidVariant], [Mismatch_MissingMobilePhone], [Mismatch_MissingMobilePhoneAndEmail], [Mismatch_MissingPartyName], [Mismatch_MissingLanguage], [Mismatch_CaseIDPrevious], [Mismatch_RelativeRecontactPeriod], [Mismatch_InvalidManufacturer], [Mismatch_InternalDealer], [Mismatch_EventDateTooYoung], [Mismatch_InvalidRoleType], [Mismatch_InvalidSaleType], [Mismatch_InvalidAFRLCode], [Mismatch_SuppliedAFRLCode], [Mismatch_DealerExclusionListMatch], [Mismatch_PhoneSuppression], [Mismatch_LostLeadDate], [Mismatch_ContactPreferencesSuppression], [Mismatch_NotInQuota], [Mismatch_ContactPreferencesPartySuppress], [Mismatch_ContactPreferencesEmailSuppress], [Mismatch_ContactPreferencesPhoneSuppress], [Mismatch_ContactPreferencesPostalSuppress], [Mismatch_DealerPilotOutputFiltered], [Mismatch_InvalidCRMSaleType], [Mismatch_MissingLostLeadAgency], [Mismatch_PDIFlagSet], [Mismatch_BodyshopEventDateOrig], [Mismatch_BodyshopEventDate], [Mismatch_BodyshopDealerCode], [Mismatch_BodyshopDealerID], [Mismatch_BodyshopDealerCodeOriginatorPartyID], [Mismatch_ContactPreferencesUnsubscribed], [Mismatch_SelectionOrganisationID], [Mismatch_SelectionPostalID], [Mismatch_SelectionEmailID], [Mismatch_SelectionPhoneID], [Mismatch_SelectionLandlineID], [Mismatch_SelectionMobileID], [Mismatch_NonSelectableWarrantyEvent], [Mismatch_IAssistanceCentreOriginatorPartyID], [Mismatch_IAssistanceCentreCode], [Mismatch_IAssistanceCentrePartyID], [Mismatch_IAssistanceDate], [Mismatch_InvalidDateOfLastContact], [MatchedODSPersonIDNew], [MatchedODSOrganisationIDNew], [MatchedODSAddressIDNew], [MatchedODSTelIDNew], [MatchedODSPrivTelIDNew], [MatchedODSMobileTelIDNew], [MatchedODSEmailAddressIDNew], [MatchedODSPrivEmailAddressIDNew], [MatchedODSVehicleIDNew], [MatchedODSBusTelIDNew], [MatchedODSEventIDNew], [SelectionOrganisationIDNew], [SelectionPostalIDNew], [SelectionEmailIDNew], [SelectionPhoneIDNew], [SelectionLandlineIDNew], [SelectionMobileIDNew]) AS
	(	SELECT [ComparisonLoadDate], [FileName], [PhysicalFileRow], [RemoteLoadedDate], [LocalLoadedDate], [Mismatch_LoadedDay], [RemoteAuditID], [LocalAuditID], [RemoteAuditItemID], [LocalAuditItemID], [Mismatch_ManufacturerID], [Mismatch_SampleSupplierPartyID], [Mismatch_MatchedODSPartyID], [Mismatch_MatchedODSPersonID], [Mismatch_LanguageID], [Mismatch_PartySuppression], [Mismatch_MatchedODSOrganisationID], [Mismatch_MatchedODSAddressID], [Mismatch_CountryID], [Mismatch_PostalSuppression], [Mismatch_AddressChecksum], [Mismatch_MatchedODSTelID], [Mismatch_MatchedODSPrivTelID], [Mismatch_MatchedODSBusTelID], [Mismatch_MatchedODSMobileTelID], [Mismatch_MatchedODSPrivMobileTelID], [Mismatch_MatchedODSEmailAddressID], [Mismatch_MatchedODSPrivEmailAddressID], [Mismatch_EmailSuppression], [Mismatch_VehicleParentAuditItemID], [Mismatch_MatchedODSVehicleID], [Mismatch_ODSRegistrationID], [Mismatch_MatchedODSModelID], [Mismatch_OwnershipCycle], [Mismatch_MatchedODSEventID], [Mismatch_ODSEventTypeID], [Mismatch_SaleDateOrig], [Mismatch_SaleDate], [Mismatch_ServiceDateOrig], [Mismatch_ServiceDate], [Mismatch_InvoiceDateOrig], [Mismatch_InvoiceDate], [Mismatch_WarrantyID], [Mismatch_SalesDealerCodeOriginatorPartyID], [Mismatch_SalesDealerCode], [Mismatch_SalesDealerID], [Mismatch_ServiceDealerCodeOriginatorPartyID], [Mismatch_ServiceDealerCode], [Mismatch_ServiceDealerID], [Mismatch_RoadsideNetworkOriginatorPartyID], [Mismatch_RoadsideNetworkCode], [Mismatch_RoadsideNetworkPartyID], [Mismatch_RoadsideDate], [Mismatch_CRCCentreOriginatorPartyID], [Mismatch_CRCCentreCode], [Mismatch_CRCCentrePartyID], [Mismatch_CRCDate], [Mismatch_Brand], [Mismatch_Market], [Mismatch_Questionnaire], [Mismatch_QuestionnaireRequirementID], [Mismatch_StartDays], [Mismatch_EndDays], [Mismatch_SuppliedName], [Mismatch_SuppliedAddress], [Mismatch_SuppliedPhoneNumber], [Mismatch_SuppliedMobilePhone], [Mismatch_SuppliedEmail], [Mismatch_SuppliedVehicle], [Mismatch_SuppliedRegistration], [Mismatch_SuppliedEventDate], [Mismatch_EventDateOutOfDate], [Mismatch_EventNonSolicitation], [Mismatch_PartyNonSolicitation], [Mismatch_UnmatchedModel], [Mismatch_UncodedDealer], [Mismatch_EventAlreadySelected], [Mismatch_NonLatestEvent], [Mismatch_InvalidOwnershipCycle], [Mismatch_RecontactPeriod], [Mismatch_InvalidVehicleRole], [Mismatch_CrossBorderAddress], [Mismatch_CrossBorderDealer], [Mismatch_ExclusionListMatch], [Mismatch_InvalidEmailAddress], [Mismatch_BarredEmailAddress], [Mismatch_BarredDomain], [Mismatch_CaseID], [Mismatched_CaseCreation], [Mismatch_SampleRowProcessed], [Mismatch_SampleRowProcessedDate], [Mismatch_WrongEventType], [Mismatch_MissingStreet], [Mismatch_MissingPostcode], [Mismatch_MissingEmail], [Mismatch_MissingTelephone], [Mismatch_MissingStreetAndEmail], [Mismatch_MissingTelephoneAndEmail], [Mismatch_InvalidModel], [Mismatch_InvalidVariant], [Mismatch_MissingMobilePhone], [Mismatch_MissingMobilePhoneAndEmail], [Mismatch_MissingPartyName], [Mismatch_MissingLanguage], [Mismatch_CaseIDPrevious], [Mismatch_RelativeRecontactPeriod], [Mismatch_InvalidManufacturer], [Mismatch_InternalDealer], [Mismatch_EventDateTooYoung], [Mismatch_InvalidRoleType], [Mismatch_InvalidSaleType], [Mismatch_InvalidAFRLCode], [Mismatch_SuppliedAFRLCode], [Mismatch_DealerExclusionListMatch], [Mismatch_PhoneSuppression], [Mismatch_LostLeadDate], [Mismatch_ContactPreferencesSuppression], [Mismatch_NotInQuota], [Mismatch_ContactPreferencesPartySuppress], [Mismatch_ContactPreferencesEmailSuppress], [Mismatch_ContactPreferencesPhoneSuppress], [Mismatch_ContactPreferencesPostalSuppress], [Mismatch_DealerPilotOutputFiltered], [Mismatch_InvalidCRMSaleType], [Mismatch_MissingLostLeadAgency], [Mismatch_PDIFlagSet], [Mismatch_BodyshopEventDateOrig], [Mismatch_BodyshopEventDate], [Mismatch_BodyshopDealerCode], [Mismatch_BodyshopDealerID], [Mismatch_BodyshopDealerCodeOriginatorPartyID], [Mismatch_ContactPreferencesUnsubscribed], [Mismatch_SelectionOrganisationID], [Mismatch_SelectionPostalID], [Mismatch_SelectionEmailID], [Mismatch_SelectionPhoneID], [Mismatch_SelectionLandlineID], [Mismatch_SelectionMobileID], [Mismatch_NonSelectableWarrantyEvent], [Mismatch_IAssistanceCentreOriginatorPartyID], [Mismatch_IAssistanceCentreCode], [Mismatch_IAssistanceCentrePartyID], [Mismatch_IAssistanceDate], [Mismatch_InvalidDateOfLastContact], [MatchedODSPersonIDNew], [MatchedODSOrganisationIDNew], [MatchedODSAddressIDNew], [MatchedODSTelIDNew], [MatchedODSPrivTelIDNew], [MatchedODSMobileTelIDNew], [MatchedODSEmailAddressIDNew], [MatchedODSPrivEmailAddressIDNew], [MatchedODSVehicleIDNew], [MatchedODSBusTelIDNew], [MatchedODSEventIDNew], [SelectionOrganisationIDNew], [SelectionPostalIDNew], [SelectionEmailIDNew], [SelectionPhoneIDNew], [SelectionLandlineIDNew], [SelectionMobileIDNew]
		FROM ParallelRun.Comparisons_SampleQualityAndSelectionLogging CSL
		WHERE CSL.Mismatch_ManufacturerID = 1
		OR CSL.Mismatch_SampleSupplierPartyID = 1
		OR CSL.Mismatch_LanguageID = 1
		OR CSL.Mismatch_PartySuppression = 1
		OR CSL.Mismatch_CountryID = 1
		OR CSL.Mismatch_PostalSuppression = 1
		OR CSL.Mismatch_EmailSuppression = 1
		OR CSL.Mismatch_OwnershipCycle = 1
		OR CSL.Mismatch_ODSEventTypeID = 1
		OR CSL.Mismatch_SaleDateOrig = 1
		OR CSL.Mismatch_SaleDate = 1
		OR CSL.Mismatch_ServiceDateOrig = 1
		OR CSL.Mismatch_ServiceDate = 1
		OR CSL.Mismatch_InvoiceDateOrig = 1
		OR CSL.Mismatch_InvoiceDate = 1
		OR CSL.Mismatch_WarrantyID = 1
		OR CSL.Mismatch_SalesDealerCodeOriginatorPartyID = 1
		OR CSL.Mismatch_SalesDealerCode = 1
		OR CSL.Mismatch_SalesDealerID = 1
		OR CSL.Mismatch_ServiceDealerCodeOriginatorPartyID = 1
		OR CSL.Mismatch_ServiceDealerCode = 1
		OR CSL.Mismatch_ServiceDealerID = 1
		OR CSL.Mismatch_RoadsideNetworkOriginatorPartyID = 1
		OR CSL.Mismatch_RoadsideNetworkCode = 1
		OR CSL.Mismatch_RoadsideNetworkPartyID = 1
		OR CSL.Mismatch_RoadsideDate = 1
		OR CSL.Mismatch_CRCCentreOriginatorPartyID = 1
		OR CSL.Mismatch_CRCCentreCode = 1
		OR CSL.Mismatch_CRCCentrePartyID = 1
		OR CSL.Mismatch_CRCDate = 1
		OR CSL.Mismatch_Brand = 1
		OR CSL.Mismatch_Market = 1
		OR CSL.Mismatch_Questionnaire = 1
		OR CSL.Mismatch_QuestionnaireRequirementID = 1
		OR CSL.Mismatch_StartDays = 1
		OR CSL.Mismatch_EndDays = 1
		OR CSL.Mismatch_SuppliedName = 1
		OR CSL.Mismatch_SuppliedAddress = 1
		OR CSL.Mismatch_SuppliedPhoneNumber = 1
		OR CSL.Mismatch_SuppliedMobilePhone = 1
		OR CSL.Mismatch_SuppliedEmail = 1
		OR CSL.Mismatch_SuppliedVehicle = 1
		OR CSL.Mismatch_SuppliedRegistration = 1
		OR CSL.Mismatch_SuppliedEventDate = 1
		OR CSL.Mismatch_EventDateOutOfDate = 1
		OR CSL.Mismatch_EventNonSolicitation = 1
		OR CSL.Mismatch_PartyNonSolicitation = 1
		OR CSL.Mismatch_UnmatchedModel = 1
		OR CSL.Mismatch_UncodedDealer = 1
		OR CSL.Mismatch_EventAlreadySelected = 1
		OR CSL.Mismatch_NonLatestEvent = 1
		OR CSL.Mismatch_InvalidOwnershipCycle = 1
		OR CSL.Mismatch_RecontactPeriod = 1
		OR CSL.Mismatch_InvalidVehicleRole = 1
		OR CSL.Mismatch_CrossBorderAddress = 1
		OR CSL.Mismatch_CrossBorderDealer = 1
		OR CSL.Mismatch_ExclusionListMatch = 1
		OR CSL.Mismatch_InvalidEmailAddress = 1
		OR CSL.Mismatch_BarredEmailAddress = 1
		OR CSL.Mismatch_BarredDomain = 1
		OR CSL.Mismatched_CaseCreation = 1
		OR CSL.Mismatch_SampleRowProcessed = 1
		OR CSL.Mismatch_SampleRowProcessedDate = 1
		OR CSL.Mismatch_WrongEventType = 1
		OR CSL.Mismatch_MissingStreet = 1
		OR CSL.Mismatch_MissingPostcode = 1
		OR CSL.Mismatch_MissingEmail = 1
		OR CSL.Mismatch_MissingTelephone = 1
		OR CSL.Mismatch_MissingStreetAndEmail = 1
		OR CSL.Mismatch_MissingTelephoneAndEmail = 1
		OR CSL.Mismatch_InvalidModel = 1
		OR CSL.Mismatch_InvalidVariant = 1
		OR CSL.Mismatch_MissingMobilePhone = 1
		OR CSL.Mismatch_MissingMobilePhoneAndEmail = 1
		OR CSL.Mismatch_MissingPartyName = 1
		OR CSL.Mismatch_MissingLanguage = 1
		OR CSL.Mismatch_CaseIDPrevious = 1
		OR CSL.Mismatch_RelativeRecontactPeriod = 1
		OR CSL.Mismatch_InvalidManufacturer = 1
		OR CSL.Mismatch_InternalDealer = 1
		OR CSL.Mismatch_EventDateTooYoung = 1
		OR CSL.Mismatch_InvalidRoleType = 1
		OR CSL.Mismatch_InvalidSaleType = 1
		OR CSL.Mismatch_InvalidAFRLCode = 1
		OR CSL.Mismatch_SuppliedAFRLCode = 1
		OR CSL.Mismatch_DealerExclusionListMatch = 1
		OR CSL.Mismatch_PhoneSuppression = 1
		OR CSL.Mismatch_LostLeadDate = 1
		OR CSL.Mismatch_ContactPreferencesSuppression = 1
		OR CSL.Mismatch_NotInQuota = 1
		OR CSL.Mismatch_ContactPreferencesPartySuppress = 1
		OR CSL.Mismatch_ContactPreferencesEmailSuppress = 1
		OR CSL.Mismatch_ContactPreferencesPhoneSuppress = 1
		OR CSL.Mismatch_ContactPreferencesPostalSuppress = 1
		OR CSL.Mismatch_DealerPilotOutputFiltered = 1
		OR CSL.Mismatch_InvalidCRMSaleType = 1
		OR CSL.Mismatch_MissingLostLeadAgency = 1
		OR CSL.Mismatch_PDIFlagSet = 1
		OR CSL.Mismatch_BodyshopEventDateOrig = 1
		OR CSL.Mismatch_BodyshopEventDate = 1
		OR CSL.Mismatch_BodyshopDealerCode = 1
		OR CSL.Mismatch_BodyshopDealerID = 1
		OR CSL.Mismatch_BodyshopDealerCodeOriginatorPartyID = 1
		OR CSL.Mismatch_ContactPreferencesUnsubscribed = 1
		OR CSL.Mismatch_NonSelectableWarrantyEvent = 1
		OR CSL.Mismatch_IAssistanceCentreOriginatorPartyID = 1
		OR CSL.Mismatch_IAssistanceCentreCode = 1
		OR CSL.Mismatch_IAssistanceCentrePartyID = 1
		OR CSL.Mismatch_IAssistanceDate = 1
		OR CSL.Mismatch_InvalidDateOfLastContact = 1
	)
	INSERT INTO ParallelRun.MismatchChecking
	SELECT CAST(CSL.ComparisonLoadDate AS date) AS ComparisonLoadDate, 
	CSL.FileName, 
	CSL.PhysicalFileRow, 
	CSL.Mismatched_CaseCreation,
	PSL.CaseID AS [GfK CaseID],
	SL.CaseID AS [IPSOS CaseID],
	CAST(CSL.RemoteLoadedDate AS date) AS RemoteLoadedDate, 
	CAST(CSL.LocalLoadedDate AS date) AS LocalLoadedDate, 
	CSL.Mismatch_LoadedDay, 
	CSL.Mismatch_ManufacturerID, 
	CSL.Mismatch_SampleSupplierPartyID, 
	CSL.Mismatch_CountryID, 
	CSL.Mismatch_MatchedODSPartyID, 
	CSL.Mismatch_MatchedODSPersonID,
	PSL.MatchedODSPersonID AS [GfK MatchedODSPersonID], 
	SL.MatchedODSPersonID AS [IPSOS MatchedODSPersonID],
	CSL.MatchedODSPersonIDNew, 
	[$(SampleDB)].Party.udfGetFullName(TG.Title,PO.FirstName, PO.Initials, PO.MiddleName, PO.LastName, PO.SecondLastName) AS [GfK Name], 
	[$(SampleDB)].Party.udfGetFullName(TI.Title,PI.FirstName, PI.Initials, PI.MiddleName, PI.LastName, PI.SecondLastName) AS [IPSOS Name], 
	CSL.Mismatch_MatchedODSOrganisationID, 
	CSL.MatchedODSOrganisationIDNew,
	PSL.MatchedODSOrganisationID AS [GfK MatchedODSOrganisationID], 
	SL.MatchedODSOrganisationID AS [IPSOS MatchedODSOrganisationID],
	ISNULL(PO.OrganisationName,'') AS [GfK MatchedOrganisationName],
	ISNULL(OI.OrganisationName,'') AS [IPSOS MatchedOrganisationName],
	CSL.Mismatch_SelectionOrganisationID, 
	CSL.SelectionOrganisationIDNew,
	PSL.SelectionOrganisationID AS [GfK SelectionOrganisationID],
	SL.SelectionOrganisationID AS [IPSOS SelectionOrganisationID],
	ISNULL(OSG.OrganisationName,'') AS [GfK SelectedOrganisationName],
	ISNULL(OSI.OrganisationName,'') AS [IPSOS SelectedOrganisationName],
	CSL.Mismatch_MatchedODSAddressID, 
	CSL.MatchedODSAddressIDNew,
	PSL.MatchedODSAddressID AS [GfK MatchedODSAddressID],
	SL.MatchedODSAddressID AS [IPSOS MatchedODSAddressID],
	[$(SampleDB)].ContactMechanism.udfGetInlinePostalAddress(PSL.MatchedODSAddressID) AS [GfK Address],
	[$(SampleDB)].ContactMechanism.udfGetInlinePostalAddress(SL.MatchedODSAddressID) AS [IPSOS Address],
	CSL.Mismatch_AddressChecksum,
	CSL.Mismatch_SelectionPostalID,
	CSL.SelectionPostalIDNew, 
	CSL.Mismatch_MatchedODSEmailAddressID,
	CSL.MatchedODSEmailAddressIDNew, 
	PSL.MatchedODSEmailAddressID AS [GfK MatchedODSEmailAddressID],
	SL.MatchedODSEmailAddressID AS [IPSOS MatchedODSEmailAddressID],
	EAG.EmailAddress AS [GfK EmailAddress],
	EAI.EmailAddress AS [IPSOS EmailAddress],
	CSL.Mismatch_MatchedODSPrivEmailAddressID, 
	CSL.Mismatch_SelectionEmailID,
	CSL.SelectionEmailIDNew,
	PSL.SelectionEmailID AS [GfK SelectionEmailID], 
	SL.SelectionEmailID AS [IPSOS SelectionEmailID],
	EASG.EmailAddress AS [GfK SelectionEmailAddress],
	EASI.EmailAddress AS [IPSOS SelectionEmailAddress],
	CSL.Mismatch_MatchedODSTelID,
	CSL.MatchedODSTelIDNew, 
	CSL.Mismatch_MatchedODSPrivTelID,
	CSL.MatchedODSPrivTelIDNew, 
	CSL.Mismatch_MatchedODSBusTelID,
	CSL.MatchedODSBusTelIDNew, 
	CSL.Mismatch_SelectionPhoneID, 
	CSL.SelectionPhoneIDNew,
	CSL.Mismatch_SelectionLandlineID, 
	CSL.SelectionLandlineIDNew,
	CSL.Mismatch_MatchedODSMobileTelID, 
	CSL.MatchedODSMobileTelIDNew,
	CSL.Mismatch_MatchedODSPrivMobileTelID, 
	CSL.Mismatch_SelectionMobileID, 
	CSL.SelectionMobileIDNew,
	CSL.Mismatch_PartySuppression, 
	CSL.Mismatch_PhoneSuppression, 
	CSL.Mismatch_PostalSuppression, 
	CSL.Mismatch_EmailSuppression, 
	CSL.Mismatch_MatchedODSVehicleID, 
	CSL.MatchedODSVehicleIDNew,
	VG.VIN AS [GfK VIN],
	VI.VIN AS [IPSOS VIN],
	CSL.Mismatch_ODSRegistrationID, 
	CSL.Mismatch_MatchedODSModelID, 
	CSL.Mismatch_OwnershipCycle, 
	CSL.Mismatch_MatchedODSEventID, 
	CSL.MatchedODSEventIDNew,
	CSL.Mismatch_ODSEventTypeID, 
	CSL.Mismatch_SaleDate, 
	CSL.Mismatch_ServiceDate, 
	CSL.Mismatch_SalesDealerCode, 
	CSL.Mismatch_SalesDealerID, 
	PSL.SalesDealerID AS [GfK SalesDealerID],
	SL.SalesDealerID AS [IPSOS SalesDealerID],
	CSL.Mismatch_ServiceDealerCode, 
	CSL.Mismatch_ServiceDealerID, 
	PSL.ServiceDealerID AS [GfK ServiceDealerID],
	SL.ServiceDealerID AS [IPSOS ServiceDealerID],
	CSL.Mismatch_RoadsideNetworkCode, 
	CSL.Mismatch_RoadsideNetworkPartyID, 
	CSL.Mismatch_RoadsideDate, 
	CSL.Mismatch_CRCCentreCode, 
	CSL.Mismatch_CRCCentrePartyID, 
	CSL.Mismatch_CRCDate, 
	CSL.Mismatch_LostLeadDate, 
	CSL.Mismatch_Brand, 
	CSL.Mismatch_Market, 
	CSL.Mismatch_Questionnaire, 
	CSL.Mismatch_QuestionnaireRequirementID, 
	CSL.Mismatch_SampleRowProcessed, 
	CSL.Mismatch_SampleRowProcessedDate, 
	CSL.Mismatch_StartDays, 
	CSL.Mismatch_EndDays, 
	CSL.Mismatch_SuppliedName, 
	CSL.Mismatch_SuppliedAddress, 
	CSL.Mismatch_SuppliedPhoneNumber, 
	CSL.Mismatch_SuppliedMobilePhone, 
	CSL.Mismatch_SuppliedEmail, 
	CSL.Mismatch_SuppliedRegistration, 
	CSL.Mismatch_SuppliedEventDate, 
	CSL.Mismatch_EventDateOutOfDate, 
	CSL.Mismatch_EventNonSolicitation, 
	CSL.Mismatch_PartyNonSolicitation, 
	CSL.Mismatch_UnmatchedModel, 
	CSL.Mismatch_UncodedDealer, 
	CSL.Mismatch_EventAlreadySelected, 
	CSL.Mismatch_NonLatestEvent, 
	CSL.Mismatch_InvalidOwnershipCycle, 
	CSL.Mismatch_RecontactPeriod, 
	CSL.Mismatch_InvalidVehicleRole, 
	CSL.Mismatch_ExclusionListMatch, 
	CSL.Mismatch_InvalidEmailAddress, 
	CSL.Mismatch_BarredEmailAddress, 
	CSL.Mismatch_BarredDomain, 
	CSL.Mismatch_WrongEventType, 
	CSL.Mismatch_MissingStreet, 
	CSL.Mismatch_MissingPostcode, 
	CSL.Mismatch_MissingEmail, 
	CSL.Mismatch_MissingTelephone, 
	CSL.Mismatch_MissingStreetAndEmail, 
	CSL.Mismatch_MissingTelephoneAndEmail, 
	CSL.Mismatch_InvalidModel, 
	CSL.Mismatch_InvalidVariant, 
	CSL.Mismatch_MissingMobilePhone, 
	CSL.Mismatch_MissingMobilePhoneAndEmail, 
	CSL.Mismatch_MissingPartyName, 
	CSL.Mismatch_MissingLanguage,
	CSL.Mismatch_CaseIDPrevious,
	CSL.Mismatch_RelativeRecontactPeriod, 
	CSL.Mismatch_InvalidManufacturer, 
	CSL.Mismatch_InternalDealer, 
	CSL.Mismatch_EventDateTooYoung, 
	CSL.Mismatch_InvalidRoleType, 
	CSL.Mismatch_InvalidSaleType, 
	CSL.Mismatch_InvalidAFRLCode, 
	CSL.Mismatch_SuppliedAFRLCode, 
	CSL.Mismatch_DealerExclusionListMatch, 
	CSL.Mismatch_ContactPreferencesSuppression, 
	CSL.Mismatch_ContactPreferencesPartySuppress, 
	CSL.Mismatch_ContactPreferencesEmailSuppress, 
	CSL.Mismatch_ContactPreferencesPhoneSuppress, 
	CSL.Mismatch_ContactPreferencesPostalSuppress, 
	CSL.Mismatch_ContactPreferencesUnsubscribed, 
	CSL.Mismatch_InvalidCRMSaleType, 
	CSL.Mismatch_MissingLostLeadAgency, 
	CSL.Mismatch_InvalidDateOfLastContact
	FROM CTE_Comparisons_SampleQualityAndSelectionLogging CSL 
	INNER JOIN ParallelRun.SampleQualityAndSelectionLogging PSL ON CSL.RemoteAuditItemID = PSL.AuditItemID
	INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL ON  CSL.LocalAuditItemID = SL.AuditItemID
	LEFT JOIN ParallelRun.PersonAndOrganisation PO ON CSL.RemoteAuditItemID = PO.AuditItemID
	LEFT JOIN [$(SampleDB)].Party.Titles TG ON PO.TitleID = TG.TitleID
	LEFT JOIN [$(SampleDB)].Party.Organisations OSG ON PSL.SelectionOrganisationID = OSG.PartyID
	LEFT JOIN [$(SampleDB)].Party.Organisations OI ON SL.MatchedODSOrganisationID = OI.PartyID
	LEFT JOIN [$(SampleDB)].Party.Organisations OSI ON SL.SelectionOrganisationID = OSI.PartyID
	LEFT JOIN [$(SampleDB)].Party.People PI ON SL.MatchedODSPersonID = PI.PartyID
	LEFT JOIN [$(SampleDB)].Party.Titles TI ON PI.TitleID = TI.TitleID
	LEFT JOIN ParallelRun.EmailAddresses EAG ON PSL.AuditItemID = EAG.AuditItemID
	LEFT JOIN [$(SampleDB)].ContactMechanism.EmailAddresses EAI ON SL.MatchedODSEmailAddressID = EAI.ContactMechanismID
	LEFT JOIN [$(SampleDB)].ContactMechanism.EmailAddresses EASG ON PSL.SelectionEmailID = EASG.ContactMechanismID
	LEFT JOIN [$(SampleDB)].ContactMechanism.EmailAddresses EASI ON SL.SelectionEmailID = EASI.ContactMechanismID
	LEFT JOIN ParallelRun.Comparisons_PostalAddress PAG ON PSL.AuditItemID = PAG.RemoteAuditItemID
	LEFT JOIN [$(SampleDB)].ContactMechanism.PostalAddresses PAI ON SL.MatchedODSAddressID = PAI.ContactMechanismID
	LEFT JOIN ParallelRun.Vehicle VG ON PSL.AuditItemID = VG.AuditItemID
	LEFT JOIN [$(SampleDB)].Vehicle.Vehicles VI ON SL.MatchedODSVehicleID = VI.VehicleID
	ORDER BY CSL.FileName, CSL.PhysicalFileRow


	-- Mismatch Mini Dispo
	;WITH CTE_Comparisons_SampleQualityAndSelectionLogging ([ComparisonLoadDate], [FileName], [PhysicalFileRow], [RemoteLoadedDate], [LocalLoadedDate], [Mismatch_LoadedDay], [RemoteAuditID], [LocalAuditID], [RemoteAuditItemID], [LocalAuditItemID], [Mismatch_ManufacturerID], [Mismatch_SampleSupplierPartyID], [Mismatch_MatchedODSPartyID], [Mismatch_MatchedODSPersonID], [Mismatch_LanguageID], [Mismatch_PartySuppression], [Mismatch_MatchedODSOrganisationID], [Mismatch_MatchedODSAddressID], [Mismatch_CountryID], [Mismatch_PostalSuppression], [Mismatch_AddressChecksum], [Mismatch_MatchedODSTelID], [Mismatch_MatchedODSPrivTelID], [Mismatch_MatchedODSBusTelID], [Mismatch_MatchedODSMobileTelID], [Mismatch_MatchedODSPrivMobileTelID], [Mismatch_MatchedODSEmailAddressID], [Mismatch_MatchedODSPrivEmailAddressID], [Mismatch_EmailSuppression], [Mismatch_VehicleParentAuditItemID], [Mismatch_MatchedODSVehicleID], [Mismatch_ODSRegistrationID], [Mismatch_MatchedODSModelID], [Mismatch_OwnershipCycle], [Mismatch_MatchedODSEventID], [Mismatch_ODSEventTypeID], [Mismatch_SaleDateOrig], [Mismatch_SaleDate], [Mismatch_ServiceDateOrig], [Mismatch_ServiceDate], [Mismatch_InvoiceDateOrig], [Mismatch_InvoiceDate], [Mismatch_WarrantyID], [Mismatch_SalesDealerCodeOriginatorPartyID], [Mismatch_SalesDealerCode], [Mismatch_SalesDealerID], [Mismatch_ServiceDealerCodeOriginatorPartyID], [Mismatch_ServiceDealerCode], [Mismatch_ServiceDealerID], [Mismatch_RoadsideNetworkOriginatorPartyID], [Mismatch_RoadsideNetworkCode], [Mismatch_RoadsideNetworkPartyID], [Mismatch_RoadsideDate], [Mismatch_CRCCentreOriginatorPartyID], [Mismatch_CRCCentreCode], [Mismatch_CRCCentrePartyID], [Mismatch_CRCDate], [Mismatch_Brand], [Mismatch_Market], [Mismatch_Questionnaire], [Mismatch_QuestionnaireRequirementID], [Mismatch_StartDays], [Mismatch_EndDays], [Mismatch_SuppliedName], [Mismatch_SuppliedAddress], [Mismatch_SuppliedPhoneNumber], [Mismatch_SuppliedMobilePhone], [Mismatch_SuppliedEmail], [Mismatch_SuppliedVehicle], [Mismatch_SuppliedRegistration], [Mismatch_SuppliedEventDate], [Mismatch_EventDateOutOfDate], [Mismatch_EventNonSolicitation], [Mismatch_PartyNonSolicitation], [Mismatch_UnmatchedModel], [Mismatch_UncodedDealer], [Mismatch_EventAlreadySelected], [Mismatch_NonLatestEvent], [Mismatch_InvalidOwnershipCycle], [Mismatch_RecontactPeriod], [Mismatch_InvalidVehicleRole], [Mismatch_CrossBorderAddress], [Mismatch_CrossBorderDealer], [Mismatch_ExclusionListMatch], [Mismatch_InvalidEmailAddress], [Mismatch_BarredEmailAddress], [Mismatch_BarredDomain], [Mismatch_CaseID], [Mismatched_CaseCreation], [Mismatch_SampleRowProcessed], [Mismatch_SampleRowProcessedDate], [Mismatch_WrongEventType], [Mismatch_MissingStreet], [Mismatch_MissingPostcode], [Mismatch_MissingEmail], [Mismatch_MissingTelephone], [Mismatch_MissingStreetAndEmail], [Mismatch_MissingTelephoneAndEmail], [Mismatch_InvalidModel], [Mismatch_InvalidVariant], [Mismatch_MissingMobilePhone], [Mismatch_MissingMobilePhoneAndEmail], [Mismatch_MissingPartyName], [Mismatch_MissingLanguage], [Mismatch_CaseIDPrevious], [Mismatch_RelativeRecontactPeriod], [Mismatch_InvalidManufacturer], [Mismatch_InternalDealer], [Mismatch_EventDateTooYoung], [Mismatch_InvalidRoleType], [Mismatch_InvalidSaleType], [Mismatch_InvalidAFRLCode], [Mismatch_SuppliedAFRLCode], [Mismatch_DealerExclusionListMatch], [Mismatch_PhoneSuppression], [Mismatch_LostLeadDate], [Mismatch_ContactPreferencesSuppression], [Mismatch_NotInQuota], [Mismatch_ContactPreferencesPartySuppress], [Mismatch_ContactPreferencesEmailSuppress], [Mismatch_ContactPreferencesPhoneSuppress], [Mismatch_ContactPreferencesPostalSuppress], [Mismatch_DealerPilotOutputFiltered], [Mismatch_InvalidCRMSaleType], [Mismatch_MissingLostLeadAgency], [Mismatch_PDIFlagSet], [Mismatch_BodyshopEventDateOrig], [Mismatch_BodyshopEventDate], [Mismatch_BodyshopDealerCode], [Mismatch_BodyshopDealerID], [Mismatch_BodyshopDealerCodeOriginatorPartyID], [Mismatch_ContactPreferencesUnsubscribed], [Mismatch_SelectionOrganisationID], [Mismatch_SelectionPostalID], [Mismatch_SelectionEmailID], [Mismatch_SelectionPhoneID], [Mismatch_SelectionLandlineID], [Mismatch_SelectionMobileID], [Mismatch_NonSelectableWarrantyEvent], [Mismatch_IAssistanceCentreOriginatorPartyID], [Mismatch_IAssistanceCentreCode], [Mismatch_IAssistanceCentrePartyID], [Mismatch_IAssistanceDate], [Mismatch_InvalidDateOfLastContact], [MatchedODSPersonIDNew], [MatchedODSOrganisationIDNew], [MatchedODSAddressIDNew], [MatchedODSTelIDNew], [MatchedODSPrivTelIDNew], [MatchedODSMobileTelIDNew], [MatchedODSEmailAddressIDNew], [MatchedODSPrivEmailAddressIDNew], [MatchedODSVehicleIDNew], [MatchedODSBusTelIDNew], [MatchedODSEventIDNew], [SelectionOrganisationIDNew], [SelectionPostalIDNew], [SelectionEmailIDNew], [SelectionPhoneIDNew], [SelectionLandlineIDNew], [SelectionMobileIDNew]) AS
	(	SELECT [ComparisonLoadDate], [FileName], [PhysicalFileRow], [RemoteLoadedDate], [LocalLoadedDate], [Mismatch_LoadedDay], [RemoteAuditID], [LocalAuditID], [RemoteAuditItemID], [LocalAuditItemID], [Mismatch_ManufacturerID], [Mismatch_SampleSupplierPartyID], [Mismatch_MatchedODSPartyID], [Mismatch_MatchedODSPersonID], [Mismatch_LanguageID], [Mismatch_PartySuppression], [Mismatch_MatchedODSOrganisationID], [Mismatch_MatchedODSAddressID], [Mismatch_CountryID], [Mismatch_PostalSuppression], [Mismatch_AddressChecksum], [Mismatch_MatchedODSTelID], [Mismatch_MatchedODSPrivTelID], [Mismatch_MatchedODSBusTelID], [Mismatch_MatchedODSMobileTelID], [Mismatch_MatchedODSPrivMobileTelID], [Mismatch_MatchedODSEmailAddressID], [Mismatch_MatchedODSPrivEmailAddressID], [Mismatch_EmailSuppression], [Mismatch_VehicleParentAuditItemID], [Mismatch_MatchedODSVehicleID], [Mismatch_ODSRegistrationID], [Mismatch_MatchedODSModelID], [Mismatch_OwnershipCycle], [Mismatch_MatchedODSEventID], [Mismatch_ODSEventTypeID], [Mismatch_SaleDateOrig], [Mismatch_SaleDate], [Mismatch_ServiceDateOrig], [Mismatch_ServiceDate], [Mismatch_InvoiceDateOrig], [Mismatch_InvoiceDate], [Mismatch_WarrantyID], [Mismatch_SalesDealerCodeOriginatorPartyID], [Mismatch_SalesDealerCode], [Mismatch_SalesDealerID], [Mismatch_ServiceDealerCodeOriginatorPartyID], [Mismatch_ServiceDealerCode], [Mismatch_ServiceDealerID], [Mismatch_RoadsideNetworkOriginatorPartyID], [Mismatch_RoadsideNetworkCode], [Mismatch_RoadsideNetworkPartyID], [Mismatch_RoadsideDate], [Mismatch_CRCCentreOriginatorPartyID], [Mismatch_CRCCentreCode], [Mismatch_CRCCentrePartyID], [Mismatch_CRCDate], [Mismatch_Brand], [Mismatch_Market], [Mismatch_Questionnaire], [Mismatch_QuestionnaireRequirementID], [Mismatch_StartDays], [Mismatch_EndDays], [Mismatch_SuppliedName], [Mismatch_SuppliedAddress], [Mismatch_SuppliedPhoneNumber], [Mismatch_SuppliedMobilePhone], [Mismatch_SuppliedEmail], [Mismatch_SuppliedVehicle], [Mismatch_SuppliedRegistration], [Mismatch_SuppliedEventDate], [Mismatch_EventDateOutOfDate], [Mismatch_EventNonSolicitation], [Mismatch_PartyNonSolicitation], [Mismatch_UnmatchedModel], [Mismatch_UncodedDealer], [Mismatch_EventAlreadySelected], [Mismatch_NonLatestEvent], [Mismatch_InvalidOwnershipCycle], [Mismatch_RecontactPeriod], [Mismatch_InvalidVehicleRole], [Mismatch_CrossBorderAddress], [Mismatch_CrossBorderDealer], [Mismatch_ExclusionListMatch], [Mismatch_InvalidEmailAddress], [Mismatch_BarredEmailAddress], [Mismatch_BarredDomain], [Mismatch_CaseID], [Mismatched_CaseCreation], [Mismatch_SampleRowProcessed], [Mismatch_SampleRowProcessedDate], [Mismatch_WrongEventType], [Mismatch_MissingStreet], [Mismatch_MissingPostcode], [Mismatch_MissingEmail], [Mismatch_MissingTelephone], [Mismatch_MissingStreetAndEmail], [Mismatch_MissingTelephoneAndEmail], [Mismatch_InvalidModel], [Mismatch_InvalidVariant], [Mismatch_MissingMobilePhone], [Mismatch_MissingMobilePhoneAndEmail], [Mismatch_MissingPartyName], [Mismatch_MissingLanguage], [Mismatch_CaseIDPrevious], [Mismatch_RelativeRecontactPeriod], [Mismatch_InvalidManufacturer], [Mismatch_InternalDealer], [Mismatch_EventDateTooYoung], [Mismatch_InvalidRoleType], [Mismatch_InvalidSaleType], [Mismatch_InvalidAFRLCode], [Mismatch_SuppliedAFRLCode], [Mismatch_DealerExclusionListMatch], [Mismatch_PhoneSuppression], [Mismatch_LostLeadDate], [Mismatch_ContactPreferencesSuppression], [Mismatch_NotInQuota], [Mismatch_ContactPreferencesPartySuppress], [Mismatch_ContactPreferencesEmailSuppress], [Mismatch_ContactPreferencesPhoneSuppress], [Mismatch_ContactPreferencesPostalSuppress], [Mismatch_DealerPilotOutputFiltered], [Mismatch_InvalidCRMSaleType], [Mismatch_MissingLostLeadAgency], [Mismatch_PDIFlagSet], [Mismatch_BodyshopEventDateOrig], [Mismatch_BodyshopEventDate], [Mismatch_BodyshopDealerCode], [Mismatch_BodyshopDealerID], [Mismatch_BodyshopDealerCodeOriginatorPartyID], [Mismatch_ContactPreferencesUnsubscribed], [Mismatch_SelectionOrganisationID], [Mismatch_SelectionPostalID], [Mismatch_SelectionEmailID], [Mismatch_SelectionPhoneID], [Mismatch_SelectionLandlineID], [Mismatch_SelectionMobileID], [Mismatch_NonSelectableWarrantyEvent], [Mismatch_IAssistanceCentreOriginatorPartyID], [Mismatch_IAssistanceCentreCode], [Mismatch_IAssistanceCentrePartyID], [Mismatch_IAssistanceDate], [Mismatch_InvalidDateOfLastContact], [MatchedODSPersonIDNew], [MatchedODSOrganisationIDNew], [MatchedODSAddressIDNew], [MatchedODSTelIDNew], [MatchedODSPrivTelIDNew], [MatchedODSMobileTelIDNew], [MatchedODSEmailAddressIDNew], [MatchedODSPrivEmailAddressIDNew], [MatchedODSVehicleIDNew], [MatchedODSBusTelIDNew], [MatchedODSEventIDNew], [SelectionOrganisationIDNew], [SelectionPostalIDNew], [SelectionEmailIDNew], [SelectionPhoneIDNew], [SelectionLandlineIDNew], [SelectionMobileIDNew]
		FROM ParallelRun.Comparisons_SampleQualityAndSelectionLogging CSL
		WHERE CSL.Mismatch_ManufacturerID = 1
		OR CSL.Mismatch_SampleSupplierPartyID = 1
		OR CSL.Mismatch_LanguageID = 1
		OR CSL.Mismatch_PartySuppression = 1
		OR CSL.Mismatch_CountryID = 1
		OR CSL.Mismatch_PostalSuppression = 1
		OR CSL.Mismatch_EmailSuppression = 1
		OR CSL.Mismatch_OwnershipCycle = 1
		OR CSL.Mismatch_ODSEventTypeID = 1
		OR CSL.Mismatch_SaleDateOrig = 1
		OR CSL.Mismatch_SaleDate = 1
		OR CSL.Mismatch_ServiceDateOrig = 1
		OR CSL.Mismatch_ServiceDate = 1
		OR CSL.Mismatch_InvoiceDateOrig = 1
		OR CSL.Mismatch_InvoiceDate = 1
		OR CSL.Mismatch_WarrantyID = 1
		OR CSL.Mismatch_SalesDealerCodeOriginatorPartyID = 1
		OR CSL.Mismatch_SalesDealerCode = 1
		OR CSL.Mismatch_SalesDealerID = 1
		OR CSL.Mismatch_ServiceDealerCodeOriginatorPartyID = 1
		OR CSL.Mismatch_ServiceDealerCode = 1
		OR CSL.Mismatch_ServiceDealerID = 1
		OR CSL.Mismatch_RoadsideNetworkOriginatorPartyID = 1
		OR CSL.Mismatch_RoadsideNetworkCode = 1
		OR CSL.Mismatch_RoadsideNetworkPartyID = 1
		OR CSL.Mismatch_RoadsideDate = 1
		OR CSL.Mismatch_CRCCentreOriginatorPartyID = 1
		OR CSL.Mismatch_CRCCentreCode = 1
		OR CSL.Mismatch_CRCCentrePartyID = 1
		OR CSL.Mismatch_CRCDate = 1
		OR CSL.Mismatch_Brand = 1
		OR CSL.Mismatch_Market = 1
		OR CSL.Mismatch_Questionnaire = 1
		OR CSL.Mismatch_QuestionnaireRequirementID = 1
		OR CSL.Mismatch_StartDays = 1
		OR CSL.Mismatch_EndDays = 1
		OR CSL.Mismatch_SuppliedName = 1
		OR CSL.Mismatch_SuppliedAddress = 1
		OR CSL.Mismatch_SuppliedPhoneNumber = 1
		OR CSL.Mismatch_SuppliedMobilePhone = 1
		OR CSL.Mismatch_SuppliedEmail = 1
		OR CSL.Mismatch_SuppliedVehicle = 1
		OR CSL.Mismatch_SuppliedRegistration = 1
		OR CSL.Mismatch_SuppliedEventDate = 1
		OR CSL.Mismatch_EventDateOutOfDate = 1
		OR CSL.Mismatch_EventNonSolicitation = 1
		OR CSL.Mismatch_PartyNonSolicitation = 1
		OR CSL.Mismatch_UnmatchedModel = 1
		OR CSL.Mismatch_UncodedDealer = 1
		OR CSL.Mismatch_EventAlreadySelected = 1
		OR CSL.Mismatch_NonLatestEvent = 1
		OR CSL.Mismatch_InvalidOwnershipCycle = 1
		OR CSL.Mismatch_RecontactPeriod = 1
		OR CSL.Mismatch_InvalidVehicleRole = 1
		OR CSL.Mismatch_CrossBorderAddress = 1
		OR CSL.Mismatch_CrossBorderDealer = 1
		OR CSL.Mismatch_ExclusionListMatch = 1
		OR CSL.Mismatch_InvalidEmailAddress = 1
		OR CSL.Mismatch_BarredEmailAddress = 1
		OR CSL.Mismatch_BarredDomain = 1
		OR CSL.Mismatched_CaseCreation = 1
		OR CSL.Mismatch_SampleRowProcessed = 1
		OR CSL.Mismatch_SampleRowProcessedDate = 1
		OR CSL.Mismatch_WrongEventType = 1
		OR CSL.Mismatch_MissingStreet = 1
		OR CSL.Mismatch_MissingPostcode = 1
		OR CSL.Mismatch_MissingEmail = 1
		OR CSL.Mismatch_MissingTelephone = 1
		OR CSL.Mismatch_MissingStreetAndEmail = 1
		OR CSL.Mismatch_MissingTelephoneAndEmail = 1
		OR CSL.Mismatch_InvalidModel = 1
		OR CSL.Mismatch_InvalidVariant = 1
		OR CSL.Mismatch_MissingMobilePhone = 1
		OR CSL.Mismatch_MissingMobilePhoneAndEmail = 1
		OR CSL.Mismatch_MissingPartyName = 1
		OR CSL.Mismatch_MissingLanguage = 1
		OR CSL.Mismatch_CaseIDPrevious = 1
		OR CSL.Mismatch_RelativeRecontactPeriod = 1
		OR CSL.Mismatch_InvalidManufacturer = 1
		OR CSL.Mismatch_InternalDealer = 1
		OR CSL.Mismatch_EventDateTooYoung = 1
		OR CSL.Mismatch_InvalidRoleType = 1
		OR CSL.Mismatch_InvalidSaleType = 1
		OR CSL.Mismatch_InvalidAFRLCode = 1
		OR CSL.Mismatch_SuppliedAFRLCode = 1
		OR CSL.Mismatch_DealerExclusionListMatch = 1
		OR CSL.Mismatch_PhoneSuppression = 1
		OR CSL.Mismatch_LostLeadDate = 1
		OR CSL.Mismatch_ContactPreferencesSuppression = 1
		OR CSL.Mismatch_NotInQuota = 1
		OR CSL.Mismatch_ContactPreferencesPartySuppress = 1
		OR CSL.Mismatch_ContactPreferencesEmailSuppress = 1
		OR CSL.Mismatch_ContactPreferencesPhoneSuppress = 1
		OR CSL.Mismatch_ContactPreferencesPostalSuppress = 1
		OR CSL.Mismatch_DealerPilotOutputFiltered = 1
		OR CSL.Mismatch_InvalidCRMSaleType = 1
		OR CSL.Mismatch_MissingLostLeadAgency = 1
		OR CSL.Mismatch_PDIFlagSet = 1
		OR CSL.Mismatch_BodyshopEventDateOrig = 1
		OR CSL.Mismatch_BodyshopEventDate = 1
		OR CSL.Mismatch_BodyshopDealerCode = 1
		OR CSL.Mismatch_BodyshopDealerID = 1
		OR CSL.Mismatch_BodyshopDealerCodeOriginatorPartyID = 1
		OR CSL.Mismatch_ContactPreferencesUnsubscribed = 1
		OR CSL.Mismatch_NonSelectableWarrantyEvent = 1
		OR CSL.Mismatch_IAssistanceCentreOriginatorPartyID = 1
		OR CSL.Mismatch_IAssistanceCentreCode = 1
		OR CSL.Mismatch_IAssistanceCentrePartyID = 1
		OR CSL.Mismatch_IAssistanceDate = 1
		OR CSL.Mismatch_InvalidDateOfLastContact = 1
	)
	INSERT INTO ParallelRun.MismatchMiniDispo
	SELECT CAST(CSL.ComparisonLoadDate AS date) AS ComparisonLoadDate, CSL.FileName, CSL.PhysicalFileRow,
	'GfK' AS Source, 
	CD.Selection AS Selection,
	V.VIN, PSL.[AuditID], PSL.[AuditItemID], [ManufacturerID], [SampleSupplierPartyID], [MatchedODSPartyID], [PersonParentAuditItemID], [MatchedODSPersonID], PSL.[LanguageID], [PartySuppression], [OrganisationParentAuditItemID], [MatchedODSOrganisationID], [AddressParentAuditItemID], [MatchedODSAddressID], PSL.[CountryID], [PostalSuppression], [AddressChecksum], [MatchedODSTelID], [MatchedODSPrivTelID], [MatchedODSBusTelID], [MatchedODSMobileTelID], [MatchedODSPrivMobileTelID], [MatchedODSEmailAddressID], [MatchedODSPrivEmailAddressID], [EmailSuppression], [VehicleParentAuditItemID], [MatchedODSVehicleID], [ODSRegistrationID], [MatchedODSModelID], PSL.[OwnershipCycle], [MatchedODSEventID], [ODSEventTypeID], [SaleDateOrig], 
	CAST([SaleDate] as date) AS [SaleDate], [ServiceDateOrig], CAST([ServiceDate] AS date) AS [ServiceDate], [InvoiceDateOrig], [InvoiceDate], [WarrantyID], [SalesDealerCodeOriginatorPartyID], [SalesDealerCode], [SalesDealerID], [ServiceDealerCodeOriginatorPartyID], [ServiceDealerCode], [ServiceDealerID], [RoadsideNetworkOriginatorPartyID], PSL.[RoadsideNetworkCode], PSL.[RoadsideNetworkPartyID], 
	CAST([RoadsideDate] AS date) AS [RoadsideDate], [CRCCentreOriginatorPartyID], [CRCCentreCode], [CRCCentrePartyID], 
	CAST([CRCDate] AS date) AS [CRCDate], [Brand], [Market], PSL.[Questionnaire], PSL.[QuestionnaireRequirementID], [StartDays], [EndDays], [SuppliedName], [SuppliedAddress], [SuppliedPhoneNumber], [SuppliedMobilePhone], [SuppliedEmail], [SuppliedVehicle], [SuppliedRegistration], [SuppliedEventDate], [EventDateOutOfDate], [EventNonSolicitation], [PartyNonSolicitation], [UnmatchedModel], [UncodedDealer], [EventAlreadySelected], [NonLatestEvent], [InvalidOwnershipCycle], [RecontactPeriod], [InvalidVehicleRole], [CrossBorderAddress], [CrossBorderDealer], [ExclusionListMatch], [InvalidEmailAddress], [BarredEmailAddress], [BarredDomain], PSL.[CaseID], [SampleRowProcessed], 
	CAST([SampleRowProcessedDate] AS date) AS [SampleRowProcessedDate], [WrongEventType], [MissingStreet], [MissingPostcode], [MissingEmail], [MissingTelephone], [MissingStreetAndEmail], [MissingTelephoneAndEmail], [InvalidModel], [InvalidVariant], [MissingMobilePhone], [MissingMobilePhoneAndEmail], [MissingPartyName], [MissingLanguage], [CaseIDPrevious], [RelativeRecontactPeriod], [InvalidManufacturer], [InternalDealer], [EventDateTooYoung], [InvalidRoleType], [InvalidSaleType], [InvalidAFRLCode], [SuppliedAFRLCode], [DealerExclusionListMatch], [PhoneSuppression], 
	CAST([LostLeadDate] AS date) AS [LostLeadDate], [ContactPreferencesSuppression], [NotInQuota], [ContactPreferencesPartySuppress], [ContactPreferencesEmailSuppress], [ContactPreferencesPhoneSuppress], [ContactPreferencesPostalSuppress], [DealerPilotOutputFiltered], [InvalidCRMSaleType], [MissingLostLeadAgency], [PDIFlagSet], [BodyshopEventDateOrig], 
	CAST([BodyshopEventDate] AS date) AS [BodyshopEventDate], [BodyshopDealerCode], [BodyshopDealerID], [BodyshopDealerCodeOriginatorPartyID], [ContactPreferencesUnsubscribed], [SelectionOrganisationID], [SelectionPostalID], [SelectionEmailID], [SelectionPhoneID], [SelectionLandlineID], [SelectionMobileID], [NonSelectableWarrantyEvent], [IAssistanceCentreOriginatorPartyID], [IAssistanceCentreCode], [IAssistanceCentrePartyID], [IAssistanceDate], [InvalidDateOfLastContact]
	FROM CTE_Comparisons_SampleQualityAndSelectionLogging CSL
	LEFT JOIN ParallelRun.SampleQualityAndSelectionLogging PSL ON CSL.RemoteAuditItemID = PSL.AuditItemID
	LEFT JOIN ParallelRun.Vehicle V ON PSL.AuditItemID = V.AuditItemID
	LEFT JOIN ParallelRun.CaseDetails CD ON PSL.CaseID = CD.CaseID
	UNION
	SELECT CAST(CSL.ComparisonLoadDate AS date) AS ComparisonLoadDate, CSL.FileName, CSL.PhysicalFileRow,
	'IPSOS' AS Source, 
	CD.Selection AS Selection,
	V.VIN, SL.[AuditID], SL.[AuditItemID], [ManufacturerID], [SampleSupplierPartyID], [MatchedODSPartyID], [PersonParentAuditItemID], [MatchedODSPersonID], SL.[LanguageID], [PartySuppression], [OrganisationParentAuditItemID], [MatchedODSOrganisationID], [AddressParentAuditItemID], [MatchedODSAddressID], SL.[CountryID], [PostalSuppression], [AddressChecksum], [MatchedODSTelID], [MatchedODSPrivTelID], [MatchedODSBusTelID], [MatchedODSMobileTelID], [MatchedODSPrivMobileTelID], [MatchedODSEmailAddressID], [MatchedODSPrivEmailAddressID], [EmailSuppression], [VehicleParentAuditItemID], [MatchedODSVehicleID], [ODSRegistrationID], [MatchedODSModelID], SL.[OwnershipCycle], [MatchedODSEventID], [ODSEventTypeID], [SaleDateOrig], 
	CAST([SaleDate] as date) AS [SaleDate], [ServiceDateOrig], CAST([ServiceDate] AS date) AS [ServiceDate], [InvoiceDateOrig], [InvoiceDate], [WarrantyID], [SalesDealerCodeOriginatorPartyID], [SalesDealerCode], [SalesDealerID], [ServiceDealerCodeOriginatorPartyID], [ServiceDealerCode], [ServiceDealerID], [RoadsideNetworkOriginatorPartyID], SL.[RoadsideNetworkCode], SL.[RoadsideNetworkPartyID], 
	CAST([RoadsideDate] AS date) AS [RoadsideDate], [CRCCentreOriginatorPartyID], [CRCCentreCode], [CRCCentrePartyID], 
	CAST([CRCDate] AS date) AS [CRCDate], [Brand], [Market], SL.[Questionnaire], SL.[QuestionnaireRequirementID], [StartDays], [EndDays], [SuppliedName], [SuppliedAddress], [SuppliedPhoneNumber], [SuppliedMobilePhone], [SuppliedEmail], [SuppliedVehicle], [SuppliedRegistration], [SuppliedEventDate], [EventDateOutOfDate], [EventNonSolicitation], [PartyNonSolicitation], [UnmatchedModel], [UncodedDealer], [EventAlreadySelected], [NonLatestEvent], [InvalidOwnershipCycle], [RecontactPeriod], [InvalidVehicleRole], [CrossBorderAddress], [CrossBorderDealer], [ExclusionListMatch], [InvalidEmailAddress], [BarredEmailAddress], [BarredDomain], SL.[CaseID], [SampleRowProcessed], 
	CAST([SampleRowProcessedDate] AS date) AS [SampleRowProcessedDate], [WrongEventType], [MissingStreet], [MissingPostcode], [MissingEmail], [MissingTelephone], [MissingStreetAndEmail], [MissingTelephoneAndEmail], [InvalidModel], [InvalidVariant], [MissingMobilePhone], [MissingMobilePhoneAndEmail], [MissingPartyName], [MissingLanguage], [CaseIDPrevious], [RelativeRecontactPeriod], [InvalidManufacturer], [InternalDealer], [EventDateTooYoung], [InvalidRoleType], [InvalidSaleType], [InvalidAFRLCode], [SuppliedAFRLCode], [DealerExclusionListMatch], [PhoneSuppression], 
	CAST([LostLeadDate] AS date) AS [LostLeadDate], [ContactPreferencesSuppression], [NotInQuota], [ContactPreferencesPartySuppress], [ContactPreferencesEmailSuppress], [ContactPreferencesPhoneSuppress], [ContactPreferencesPostalSuppress], [DealerPilotOutputFiltered], [InvalidCRMSaleType], [MissingLostLeadAgency], [PDIFlagSet], [BodyshopEventDateOrig], 
	CAST([BodyshopEventDate] AS date) AS [BodyshopEventDate], [BodyshopDealerCode], [BodyshopDealerID], [BodyshopDealerCodeOriginatorPartyID], [ContactPreferencesUnsubscribed], [SelectionOrganisationID], [SelectionPostalID], [SelectionEmailID], [SelectionPhoneID], [SelectionLandlineID], [SelectionMobileID], [NonSelectableWarrantyEvent], [IAssistanceCentreOriginatorPartyID], [IAssistanceCentreCode], [IAssistanceCentrePartyID], [IAssistanceDate], [InvalidDateOfLastContact]
	FROM CTE_Comparisons_SampleQualityAndSelectionLogging CSL
	LEFT JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL ON CSL.LocalAuditItemID = SL.AuditItemID
	LEFT JOIN [$(SampleDB)].Vehicle.Vehicles V ON SL.MatchedODSVehicleID = V.VehicleID
	LEFT JOIN [$(SampleDB)].Meta.CaseDetails CD ON SL.CaseID = CD.CaseID



	-- Comparisons_PersonAndOrganisation
	--SELECT [ComparisonLoadDate],
	--SUM([Mismatch_FromDate]) AS [Mismatch_FromDate],
	--SUM([Mismatch_TitleID]) AS [Mismatch_TitleID],
	--SUM([Mismatch_Initials]) AS [Mismatch_Initials],
	--SUM([Mismatch_FirstName]) AS [Mismatch_FirstName],
	--SUM([Mismatch_MiddleName]) AS [Mismatch_MiddleName],
	--SUM([Mismatch_LastName]) AS [Mismatch_LastName],
	--SUM([Mismatch_SecondLastName]) AS [Mismatch_SecondLastName],
	--SUM([Mismatch_GenderID]) AS [Mismatch_GenderID],
	--SUM([Mismatch_BirthDate]) AS [Mismatch_BirthDate],
	--SUM([Mismatch_MonthAndYearOfBirth]) AS [Mismatch_MonthAndYearOfBirth],
	--SUM([Mismatch_PreferredMethodOfContact]) AS [Mismatch_PreferredMethodOfContact],
	--SUM([Mismatch_NameChecksum]) AS [Mismatch_NameChecksum],
	--SUM([Mismatch_OrganisationName]) AS [Mismatch_OrganisationName],
	--SUM([Mismatch_OrganisationNameChecksum]) AS [Mismatch_OrganisationNameChecksum]
	--FROM ParallelRun.Comparisons_PersonAndOrganisation
	--GROUP BY [ComparisonLoadDate]


	-- People
	INSERT INTO ParallelRun.MismatchPeople
	SELECT CAST(CSL.ComparisonLoadDate AS date) AS ComparisonLoadDate, CSL.FileName, CSL.PhysicalFileRow,
	PSL.MatchedODSPersonID AS [GfK MatchedODSPersonID], SL.MatchedODSPersonID AS [IPSOS MatchedODSPersonID], 
	[Mismatch_FromDate], CAST(PO.FromDate AS date) AS [GfK FromDate], CAST(P.FromDate AS date) AS [IPSOS FromDate], 
	[Mismatch_TitleID], PO.TitleID AS [GfK TitleID], T.Title AS [GfK Title], P.TitleID AS [IPSOS TitleID], T1.Title AS [IPSOS Title], 
	[Mismatch_Initials], PO.Initials AS [GfK Initials], P.Initials AS [IPSOS Initials], 
	[Mismatch_FirstName], PO.FirstName AS [GfK FirstName], P.FirstName AS [IPSOS FirstName], 
	[Mismatch_MiddleName], PO.MiddleName AS [GfK MiddleName], P.MiddleName AS [IPSOS MiddleName], 
	[Mismatch_LastName], PO.LastName AS [GfK LastName], P.LastName AS [IPSOS LastName], 
	[Mismatch_SecondLastName], PO.SecondLastName AS [GfK SecondLastName], P.SecondLastName AS [IPSOS SecondLastName],
	[Mismatch_GenderID], PO.GenderID AS [GfK GenderID], P.GenderID AS [IPSOS GenderID], 
	[Mismatch_BirthDate], CAST(PO.BirthDate AS date) AS [GfK BirthDate], CAST(P.BirthDate AS date) AS [IPSOS BirthDate], 
	[Mismatch_MonthAndYearOfBirth], PO.MonthAndYearOfBirth AS [GfK MonthAndYearOfBirth], P.MonthAndYearOfBirth AS [IPSOS MonthAndYearOfBirth], 
	[Mismatch_PreferredMethodOfContact], PO.PreferredMethodOfContact AS [GfK PreferredMethodOfContact], P.PreferredMethodOfContact AS [IPSOS PreferredMethodOfContact],
	[Mismatch_NameChecksum], PO.NameChecksum AS [GfK NameChecksum], P.NameChecksum AS [IPSOS NameChecksum]
	FROM ParallelRun.Comparisons_PersonAndOrganisation CSL
	LEFT JOIN ParallelRun.SampleQualityAndSelectionLogging PSL ON CSL.RemoteAuditItemID = PSL.AuditItemID
	LEFT JOIN ParallelRun.PersonAndOrganisation PO ON CSL.RemoteAuditItemID = PO.AuditItemID
	LEFT JOIN [$(SampleDB)].Party.Titles T ON PO.TitleID = T.TitleID
	LEFT JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL ON CSL.LocalAuditItemID = SL.AuditItemID
	LEFT JOIN [$(SampleDB)].Party.People P ON SL.MatchedODSPersonID = P.PartyID
	LEFT JOIN [$(SampleDB)].Party.Titles T1 ON P.TitleID = T1.TitleID
	WHERE ([Mismatch_FromDate] = 1
	OR [Mismatch_TitleID]  = 1 
	OR [Mismatch_Initials]  = 1 
	OR [Mismatch_FirstName]  = 1 
	OR [Mismatch_MiddleName]  = 1 
	OR [Mismatch_LastName]  = 1 
	OR [Mismatch_SecondLastName]  = 1 
	OR [Mismatch_GenderID]  = 1 
	OR [Mismatch_BirthDate]  = 1 
	OR [Mismatch_MonthAndYearOfBirth]  = 1 
	OR [Mismatch_PreferredMethodOfContact]  = 1 
	OR [Mismatch_NameChecksum]  = 1)
	ORDER BY CSL.FileName, CSL.PhysicalFileRow

	-- Organisations
	INSERT INTO ParallelRun.MismatchOrganisations
	SELECT CAST(CSL.ComparisonLoadDate AS date) AS ComparisonLoadDate, CSL.FileName, CSL.PhysicalFileRow,
	PSL.MatchedODSOrganisationID AS [GfK MatchedODSOrganisationID], SL.MatchedODSOrganisationID AS [IPSOS MatchedODSOrganisationID], 
	CSL.Mismatch_OrganisationName, PO.OrganisationName AS [GfK OrganisationName], O.OrganisationName AS [IPSOS OrganisationName], 
	CSL.Mismatch_OrganisationNameChecksum, PO.OrganisationNameChecksum AS [GfK OrganisationNameChecksum], O.OrganisationNameChecksum AS [IPSOS OrganisationNameChecksum]
	FROM ParallelRun.Comparisons_PersonAndOrganisation CSL
	LEFT JOIN ParallelRun.SampleQualityAndSelectionLogging PSL ON CSL.RemoteAuditItemID = PSL.AuditItemID
	LEFT JOIN ParallelRun.PersonAndOrganisation PO ON CSL.RemoteAuditItemID = PO.AuditItemID
	LEFT JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL ON CSL.LocalAuditItemID = SL.AuditItemID
	LEFT JOIN [$(SampleDB)].Party.Organisations O ON SL.MatchedODSOrganisationID = O.PartyID
	WHERE ([Mismatch_OrganisationName]  = 1 
	OR [Mismatch_OrganisationNameChecksum] = 1)
	ORDER BY CSL.FileName, CSL.PhysicalFileRow

	-- Comparisons_EmailAddresses
	SELECT 
	[ComparisonLoadDate],
	SUM([Mismatch_EmailAddress]) AS [Mismatch_EmailAddress],
	SUM([Mismatch_EmailAddressChecksum]) AS [Mismatch_EmailAddressChecksum],
	SUM([Mismatch_PrivEmailAddress]) AS [Mismatch_PrivEmailAddress],
	SUM([Mismatch_PrivEmailAddressChecksum]) AS [Mismatch_PrivEmailAddressChecksum]
	FROM ParallelRun.Comparisons_EmailAddresses
	GROUP BY [ComparisonLoadDate]

	-- Email Addresses
	INSERT INTO ParallelRun.MismatchEmailAddresses
	SELECT CAST(CSL.ComparisonLoadDate AS date) AS ComparisonLoadDate, CSL.FileName, CSL.PhysicalFileRow,
	PSL.MatchedODSEmailAddressID AS [GfK MatchedODSEmailAddressID], SL.MatchedODSEmailAddressID AS [IPSOS MatchedODSEmailAddressID], CSL.MatchedODSEmailAddressIDNew, 
	Mismatch_EmailAddress, EAG.EmailAddress AS [GfK EmailAddress], EAI.EmailAddress AS [IPSOS EmailAddress],
	Mismatch_EmailAddressChecksum, EAG.EmailAddressChecksum AS [GfK EmailAddressChecksum], EAI.EmailAddressChecksum AS [IPSOS EmailAddressChecksum],
	PSL.MatchedODSPrivEmailAddressID AS [GfK MatchedODSPrivEmailAddressID], SL.MatchedODSPrivEmailAddressID AS [IPSOS MatchedODSPrivEmailAddressID], CSL.MatchedODSPrivEmailAddressIDNew, 
	Mismatch_PrivEmailAddress, EAG.PrivEmailAddress AS [GfK PrivEmailAddress], PEAI.EmailAddress AS [IPSOS PrivEmailAddress],
	Mismatch_PrivEmailAddressChecksum, EAG.PrivEmailAddressChecksum AS [GfK PrivEmailAddressChecksum], PEAI.EmailAddressChecksum AS [IPSOS PrivEmailAddressChecksum]
	FROM ParallelRun.Comparisons_EmailAddresses CPA
	LEFT JOIN ParallelRun.Comparisons_SampleQualityAndSelectionLogging CSL ON CPA.LocalAuditItemID = CSL.LocalAuditItemID
	LEFT JOIN ParallelRun.SampleQualityAndSelectionLogging PSL ON CPA.RemoteAuditItemID = PSL.AuditItemID
	LEFT JOIN ParallelRun.EmailAddresses EAG ON CPA.RemoteAuditItemID = EAG.AuditItemID
	LEFT JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL ON CPA.LocalAuditItemID = SL.AuditItemID
	LEFT JOIN [$(SampleDB)].ContactMechanism.EmailAddresses EAI ON SL.MatchedODSAddressID = EAI.ContactMechanismID
	LEFT JOIN [$(SampleDB)].ContactMechanism.EmailAddresses PEAI ON SL.MatchedODSPrivEmailAddressID = PEAI.ContactMechanismID
	WHERE (Mismatch_EmailAddress = 1
	OR Mismatch_EmailAddressChecksum = 1
	OR Mismatch_PrivEmailAddress = 1
	OR Mismatch_PrivEmailAddressChecksum = 1)
	ORDER BY CPA.FileName, CPA.PhysicalFileRow


	-- Comparisons_PostalAddress
	--SELECT
	--[ComparisonLoadDate],
	--SUM([Mismatch_ContactMechanismID]) AS [Mismatch_ContactMechanismID],
	--SUM([Mismatch_BuildingName]) AS [Mismatch_BuildingName],
	--SUM([Mismatch_SubStreetNumber]) AS [Mismatch_SubStreetNumber],
	--SUM([Mismatch_SubStreet]) AS [Mismatch_SubStreet],
	--SUM([Mismatch_StreetNumber]) AS [Mismatch_StreetNumber],
	--SUM([Mismatch_Street]) AS [Mismatch_Street],
	--SUM([Mismatch_SubLocality]) AS [Mismatch_SubLocality],
	--SUM([Mismatch_Locality]) AS [Mismatch_Locality],
	--SUM([Mismatch_Town]) AS [Mismatch_Town],
	--SUM([Mismatch_Region]) AS [Mismatch_Region],
	--SUM([Mismatch_PostCode]) AS [Mismatch_PostCode],
	--SUM([Mismatch_CountryID]) AS [Mismatch_CountryID],
	--SUM([Mismatch_AddressChecksum]) AS [Mismatch_AddressChecksum]
	--FROM ParallelRun.Comparisons_PostalAddress
	--GROUP BY [ComparisonLoadDate]

	-- Postal Addresses
	INSERT INTO ParallelRun.MismatchPostalAddresses
	SELECT CAST(CSL.ComparisonLoadDate AS date) AS ComparisonLoadDate, CSL.FileName, CSL.PhysicalFileRow,
	Mismatch_ContactMechanismID, PA.ContactMechanismID AS [GfK ContactMechanismID], PA1.ContactMechanismID AS [IPSOS ContactMechanismID], CSL.MatchedODSAddressIDNew, 
	Mismatch_BuildingName, PA.BuildingName AS [GfK BuildingName], PA1.BuildingName AS [IPSOS BuildingName], 
	Mismatch_SubStreetNumber, PA.SubStreetNumber AS [GfK SubStreetNumber], PA1.SubStreetNumber AS [IPSOS SubStreetNumber], 
	Mismatch_SubStreet, PA.SubStreet AS [GfK SubStreet], PA1.SubStreet AS [IPSOS SubStreet], 
	Mismatch_StreetNumber, PA.StreetNumber AS [GfK StreetNumber], PA1.StreetNumber AS [IPSOS StreetNumber], 
	Mismatch_Street, PA.Street AS [GfK Street], PA1.Street AS [IPSOS Street], 
	Mismatch_SubLocality, PA.SubLocality AS [GfK SubLocality], PA1.SubLocality AS [IPSOS SubLocality], 
	Mismatch_Locality, PA.Locality AS [GfK Locality], PA1.Locality AS [IPSOS Locality], 
	Mismatch_Town, PA.Town AS [GfK Town], PA1.Town AS [IPSOS Town], 
	Mismatch_Region, PA.Region AS [GfK Region], PA1.Region AS [IPSOS Region], 
	Mismatch_PostCode, PA.PostCode AS [GfK PostCode], PA1.PostCode AS [IPSOS PostCode], 
	CPA.Mismatch_CountryID, PA.CountryID AS [GfK CountryID],  PA1.CountryID AS [IPSOS CountryID],
	CPA.Mismatch_AddressChecksum, PA.AddressChecksum AS [GfK AddressChecksum], PA1.AddressChecksum AS [IPSOS AddressChecksum]
	FROM ParallelRun.Comparisons_PostalAddress CPA
	LEFT JOIN ParallelRun.Comparisons_SampleQualityAndSelectionLogging CSL ON CPA.LocalAuditItemID = CSL.LocalAuditItemID
	LEFT JOIN ParallelRun.SampleQualityAndSelectionLogging PSL ON CPA.RemoteAuditItemID = PSL.AuditItemID
	LEFT JOIN ParallelRun.PostalAddress PA ON CPA.RemoteAuditItemID = PA.AuditItemID
	LEFT JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL ON CPA.LocalAuditItemID = SL.AuditItemID
	LEFT JOIN [$(SampleDB)].ContactMechanism.PostalAddresses PA1 ON SL.MatchedODSAddressID = PA1.ContactMechanismID
	WHERE (Mismatch_ContactMechanismID = 1
	OR Mismatch_BuildingName = 1
	OR Mismatch_SubStreetNumber = 1
	OR Mismatch_SubStreet = 1
	OR Mismatch_StreetNumber = 1
	OR Mismatch_Street = 1
	OR Mismatch_SubLocality = 1
	OR Mismatch_Locality = 1
	OR Mismatch_Town = 1
	OR Mismatch_Region = 1
	OR Mismatch_PostCode = 1
	OR CPA.Mismatch_CountryID = 1
	OR CPA.Mismatch_AddressChecksum = 1)
	ORDER BY CSL.FileName, CSL.PhysicalFileRow


	-- Comparisons_TelephoneNumbers
	--SELECT
	--[ComparisonLoadDate],
	--SUM([Mismatch_tn_ContactNumber]) AS [Mismatch_tn_ContactNumber],
	--SUM([Mismatch_tn_ContactNumberChecksum]) AS [Mismatch_tn_ContactNumberChecksum],
	--SUM([Mismatch_ptn_ContactNumber]) AS [Mismatch_ptn_ContactNumber],
	--SUM([Mismatch_ptn_ContactNumberChecksum]) AS [Mismatch_ptn_ContactNumberChecksum],
	--SUM([Mismatch_btn_ContactNumber]) AS [Mismatch_btn_ContactNumber],
	--SUM([Mismatch_btn_ContactNumberChecksum]) AS [Mismatch_btn_ContactNumberChecksum],
	--SUM([Mismatch_mtn_ContactNumber]) AS [Mismatch_mtn_ContactNumber],
	--SUM([Mismatch_mtn_ContactNumberChecksum]) AS [Mismatch_mtn_ContactNumberChecksum],
	--SUM([Mismatch_pmtn_ContactNumber]) AS [Mismatch_pmtn_ContactNumber],
	--SUM([Mismatch_pmtn_ContactNumberChecksum]) AS [Mismatch_pmtn_ContactNumberChecksum]
	--FROM ParallelRun.Comparisons_TelephoneNumbers
	--GROUP BY [ComparisonLoadDate]

	-- Telephone Numbers
	INSERT INTO ParallelRun.MismatchTelephoneNumbers
	SELECT CAST(CSL.ComparisonLoadDate AS date) AS ComparisonLoadDate, CSL.FileName, CSL.PhysicalFileRow,
	Mismatch_tn_ContactNumber, TNG.tn_ContactNumber AS [GfK tn_ContactNumber], TNI.ContactNumber AS [IPSOS tn_ContactNumber],
	Mismatch_tn_ContactNumberChecksum, TNG.tn_ContactNumberChecksum AS [GfK tn_ContactNumberChecksum], TNI.ContactNumberChecksum AS [IPSOS tn_ContactNumberChecksum],
	Mismatch_ptn_ContactNumber, TNG.ptn_ContactNumber AS [GfK ptn_ContactNumber], PTNI.ContactNumber AS [IPSOS ptn_ContactNumber],
	Mismatch_ptn_ContactNumberChecksum, TNG.ptn_ContactNumberChecksum AS [GfK ptn_ContactNumberChecksum], PTNI.ContactNumberChecksum AS [IPSOS ptn_ContactNumberChecksum],
	Mismatch_btn_ContactNumber, TNG.btn_ContactNumber AS [GfK btn_ContactNumber], BTNI.ContactNumber AS [IPSOS btn_ContactNumber],
	Mismatch_btn_ContactNumberChecksum, TNG.btn_ContactNumberChecksum AS [GfK btn_ContactNumberChecksum], BTNI.ContactNumberChecksum AS [IPSOS btn_ContactNumberChecksum],
	Mismatch_mtn_ContactNumber, TNG.mtn_ContactNumber AS [GfK mtn_ContactNumber], MTNI.ContactNumber AS [IPSOS mtn_ContactNumber],
	Mismatch_mtn_ContactNumberChecksum, TNG.mtn_ContactNumberChecksum AS [GfK mtn_ContactNumberChecksum], MTNI.ContactNumberChecksum AS [IPSOS mtn_ContactNumberChecksum],
	Mismatch_pmtn_ContactNumber, TNG.pmtn_ContactNumber AS [GfK pmtn_ContactNumber], PMTNI.ContactNumber AS [IPSOS pmtn_ContactNumber],
	Mismatch_pmtn_ContactNumberChecksum, TNG.pmtn_ContactNumberChecksum AS [GfK pmtn_ContactNumberChecksum], PMTNI.ContactNumberChecksum AS [IPSOS pmtn_ContactNumberChecksum]
	FROM ParallelRun.Comparisons_TelephoneNumbers CTN
	LEFT JOIN ParallelRun.Comparisons_SampleQualityAndSelectionLogging CSL ON CTN.LocalAuditItemID = CSL.LocalAuditItemID
	LEFT JOIN ParallelRun.SampleQualityAndSelectionLogging PSL ON CTN.RemoteAuditItemID = PSL.AuditItemID
	LEFT JOIN ParallelRun.TelephoneNumbers TNG ON CTN.RemoteAuditItemID = TNG.AuditItemID
	LEFT JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL ON CTN.LocalAuditItemID = SL.AuditItemID
	LEFT JOIN [$(SampleDB)].ContactMechanism.TelephoneNumbers TNI ON SL.MatchedODSTelID = TNI.ContactMechanismID
	LEFT JOIN [$(SampleDB)].ContactMechanism.TelephoneNumbers PTNI ON SL.MatchedODSPrivTelID = PTNI.ContactMechanismID
	LEFT JOIN [$(SampleDB)].ContactMechanism.TelephoneNumbers BTNI ON SL.MatchedODSBusTelID = BTNI.ContactMechanismID
	LEFT JOIN [$(SampleDB)].ContactMechanism.TelephoneNumbers MTNI ON SL.MatchedODSMobileTelID = MTNI.ContactMechanismID
	LEFT JOIN [$(SampleDB)].ContactMechanism.TelephoneNumbers PMTNI ON SL.MatchedODSPrivEmailAddressID = PMTNI.ContactMechanismID
	WHERE (Mismatch_tn_ContactNumber = 1
	 OR Mismatch_tn_ContactNumberChecksum = 1
	 OR Mismatch_ptn_ContactNumber = 1
	 OR Mismatch_ptn_ContactNumberChecksum = 1
	 OR Mismatch_btn_ContactNumber = 1
	 OR Mismatch_btn_ContactNumberChecksum = 1
	 OR Mismatch_mtn_ContactNumber = 1
	 OR Mismatch_mtn_ContactNumberChecksum = 1
	 OR Mismatch_pmtn_ContactNumber = 1
	 OR Mismatch_pmtn_ContactNumberChecksum = 1)
	ORDER BY CSL.FileName, CSL.PhysicalFileRow


	-- Comparisons_Vehicle
	--SELECT
	--[ComparisonLoadDate],
	--SUM([Mismatch_VehicleID]) AS [Mismatch_VehicleID],
	--SUM([Mismatch_ModelID]) AS [Mismatch_ModelID],
	--SUM([Mismatch_VIN]) AS [Mismatch_VIN],
	--SUM([Mismatch_VehicleIdentificationNumberUsable]) AS [Mismatch_VehicleIdentificationNumberUsable],
	--SUM([Mismatch_VINPrefix]) AS [Mismatch_VINPrefix],
	--SUM([Mismatch_ChassisNumber]) AS [Mismatch_ChassisNumber],
	--SUM([Mismatch_BuildDate]) AS [Mismatch_BuildDate],
	--SUM([Mismatch_BuildYear]) AS [Mismatch_BuildYear],
	--SUM([Mismatch_ThroughDate]) AS [Mismatch_ThroughDate],
	--SUM([Mismatch_ModelVariantID]) AS [Mismatch_ModelVariantID],
	--SUM([Mismatch_SVOTypeID]) AS [Mismatch_SVOTypeID],
	--SUM([Mismatch_FOBCode]) AS [Mismatch_FOBCode],
	--SUM([Mismatch_RegistrationID]) AS [Mismatch_RegistrationID],
	--SUM([Mismatch_RegistrationNumber]) AS [Mismatch_RegistrationNumber],
	--SUM([Mismatch_RegistrationDate]) AS [Mismatch_RegistrationDate],
	--SUM([Mismatch_Reg_ThroughDate]) AS [Mismatch_Reg_ThroughDate]
	--FROM ParallelRun.Comparisons_Vehicle
	--GROUP BY [ComparisonLoadDate]

	-- Vehicles
	INSERT INTO ParallelRun.MismatchVehicles
	SELECT CAST(CSL.ComparisonLoadDate AS date) AS ComparisonLoadDate, CSL.FileName, CSL.PhysicalFileRow,
	Mismatch_VehicleID, V.VehicleID AS [GfK VehicleID], V1.VehicleID AS [IPSOS VehicleID],
	Mismatch_ModelID, V.ModelID AS [GfK ModelID], V1.ModelID AS [IPSOS ModelID],
	Mismatch_VIN, V.VIN AS [GfK VIN], V1.VIN AS [IPSOS VIN],
	Mismatch_VehicleIdentificationNumberUsable, V.VehicleIdentificationNumberUsable AS [GfK VehicleIdentificationNumberUsable], V1.VehicleIdentificationNumberUsable AS [IPSOS VehicleIdentificationNumberUsable],
	Mismatch_VINPrefix, V.VINPrefix AS [GfK VINPrefix], V1.VINPrefix AS [IPSOS VINPrefix],
	Mismatch_ChassisNumber, V.ChassisNumber AS [GfK ChassisNumber], V1.ChassisNumber AS [IPSOS ChassisNumber],
	Mismatch_BuildDate, V.BuildDate AS [GfK BuildDate], V1.BuildDate AS [IPSOS BuildDate],
	Mismatch_BuildYear, V.BuildYear AS [GfK BuildYear], V1.BuildYear AS [IPSOS BuildYear],
	Mismatch_ThroughDate, V.ThroughDate AS [GfK ThroughDate], V1.ThroughDate AS [IPSOS ThroughDate],
	Mismatch_ModelVariantID, V.ModelVariantID AS [GfK ModelVariantID], V1.ModelVariantID AS [IPSOS ModelVariantID],
	Mismatch_SVOTypeID, V.SVOTypeID AS [GfK SVOTypeID], V1.SVOTypeID AS [IPSOS SVOTypeID],
	Mismatch_FOBCode, V.FOBCode AS [GfK FOBCode], V1.FOBCode AS [IPSOS FOBCode]
	FROM ParallelRun.Comparisons_Vehicle CSL
	LEFT JOIN ParallelRun.SampleQualityAndSelectionLogging PSL ON CSL.RemoteAuditItemID = PSL.AuditItemID
	LEFT JOIN ParallelRun.Vehicle V ON CSL.RemoteAuditItemID = V.AuditItemID
	LEFT JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL ON CSL.LocalAuditItemID = SL.AuditItemID
	LEFT JOIN [$(SampleDB)].Vehicle.Vehicles V1 ON SL.MatchedODSVehicleID = V1.VehicleID
	WHERE (Mismatch_VehicleID = 1
	OR Mismatch_ModelID = 1
	OR Mismatch_VIN = 1
	OR Mismatch_VehicleIdentificationNumberUsable = 1
	OR Mismatch_VINPrefix = 1
	OR Mismatch_ChassisNumber = 1
	OR Mismatch_BuildDate = 1
	OR Mismatch_BuildYear = 1
	OR Mismatch_ThroughDate = 1
	OR Mismatch_ModelVariantID = 1
	OR Mismatch_SVOTypeID = 1
	OR Mismatch_FOBCode = 1)
	ORDER BY CSL.FileName, CSL.PhysicalFileRow

	-- Registrations
	INSERT INTO ParallelRun.MismatchRegistrations
	SELECT CAST(CSL.ComparisonLoadDate AS date) AS ComparisonLoadDate, CSL.FileName, CSL.PhysicalFileRow,
	Mismatch_RegistrationID, V.RegistrationID AS [GfK RegistrationID], R.RegistrationID AS [IPSOS RegistrationID],
	Mismatch_RegistrationNumber, V.RegistrationNumber AS [GfK RegistrationNumber], R.RegistrationNumber AS [IPSOS RegistrationNumber],
	Mismatch_RegistrationDate, V.RegistrationDate AS [GfK RegistrationDate], R.RegistrationDate AS [IPSOS RegistrationDate],
	Mismatch_Reg_ThroughDate, V.Reg_ThroughDate AS [GfK ThroughDate], R.ThroughDate AS [IPSOS ThroughDate]
	FROM ParallelRun.Comparisons_Vehicle CV
	LEFT JOIN ParallelRun.Comparisons_SampleQualityAndSelectionLogging CSL ON CV.LocalAuditItemID = CSL.LocalAuditItemID
	LEFT JOIN ParallelRun.SampleQualityAndSelectionLogging PSL ON CV.RemoteAuditItemID = PSL.AuditItemID
	LEFT JOIN ParallelRun.Vehicle V ON CV.RemoteAuditItemID = V.AuditItemID
	LEFT JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL ON CV.LocalAuditItemID = SL.AuditItemID
	LEFT JOIN [$(SampleDB)].Vehicle.Registrations R ON SL.ODSRegistrationID = R.RegistrationID
	WHERE (Mismatch_RegistrationID = 1
	OR Mismatch_RegistrationNumber = 1
	OR Mismatch_RegistrationDate = 1
	OR Mismatch_Reg_ThroughDate = 1)
	ORDER BY CSL.FileName, CSL.PhysicalFileRow



	DELETE FROM ParallelRun.DailyFilesLoaded
	DELETE FROM ParallelRun.DailySelections


	INSERT INTO ParallelRun.DailyFilesLoaded ([RemoteAuditID], [RemoteFileName], [RemoteFileRowCount], [RemoteActionDate], [RemoteLoadSuccess], [RemoteFileLoadFailure])
	SELECT F.AuditID, F.FileName, F.FileRowCount, F.ActionDate, F.LoadSuccess, FFR.FileFailureReason
	FROM ParallelRun.Files F
	LEFT JOIN [$(AuditDB)].dbo.FileFailureReasons FFR ON F.FileLoadFailureID = FFR.FileFailureID
	WHERE F.FileRowCount <> 0
	AND F.FileTypeID = 1


	UPDATE DFL SET DFL.LocalAuditID = F.AuditID, DFL.LocalFileName = F.FileName, DFL.LocalFileRowCount = F.FileRowCount, DFL.LocalActionDate = F.ActionDate, DFL.LocalLoadSuccess = ICF.LoadSuccess, DFL.LocalFileLoadFailure = FFR.FileFailureReasonShort
	--SELECT F.AuditID, F.FileName, F.FileRowCount, F.ActionDate, ICF.LoadSuccess, FFR.FileFailureReasonShort AS FileLoadFailure
	FROM [$(AuditDB)].dbo.Files F
	JOIN [$(AuditDB)].dbo.IncomingFiles ICF ON F.AuditID = ICF.AuditID
	LEFT JOIN [$(AuditDB)].dbo.FileFailureReasons FFR ON ICF.FileLoadFailureID = FFR.FileFailureID
	JOIN ParallelRun.DailyFilesLoaded DFL ON F.FileName = DFL.RemoteFileName
	WHERE F.ActionDate >= @DateLastRun	-- V1.4
	AND F.FileRowCount <> 0
	AND F.FileTypeID = 1

	--UPDATE DFL SET DFL.LocalAuditID = F.AuditID, DFL.LocalFileName = F.FileName, DFL.LocalFileRowCount = F.FileRowCount, DFL.LocalActionDate = F.ActionDate, DFL.LocalLoadSuccess = ICF.LoadSuccess, DFL.LocalFileLoadFailure = FFR.FileFailureReasonShort
	----SELECT F.AuditID, F.FileName, F.FileRowCount, F.ActionDate, ICF.LoadSuccess, FFR.FileFailureReasonShort AS FileLoadFailure
	--FROM [$(AuditDB)].dbo.Files F
	--JOIN [$(AuditDB)].dbo.IncomingFiles ICF ON F.AuditID = ICF.AuditID
	--LEFT JOIN [$(AuditDB)].dbo.FileFailureReasons FFR ON ICF.FileLoadFailureID = FFR.FileFailureID
	--JOIN ParallelRun.DailyFilesLoaded DFL ON SUBSTRING(F.FileName,1,LEN(F.FileName)-4) = SUBSTRING(DFL.RemoteFileName,1,LEN(F.FileName)-4) 
	--WHERE F.ActionDate >= @DateLastRun	-- V1.4
	--AND F.FileRowCount <> 0
	--AND F.FileTypeID = 1
	--AND ICF.LoadSuccess = 1


	UPDATE DFL SET DFL.RemoteEvents = T1.Events
	FROM ParallelRun.DailyFilesLoaded DFL
	JOIN (SELECT DISTINCT COUNT(MatchedODSEventID) AS Events, AuditID 
	FROM ParallelRun.SampleQualityAndSelectionLogging
	WHERE LoadedDate >= @DateLastRun	-- V1.4
	GROUP BY AuditID) AS T1
	ON DFL.RemoteAuditID = T1.AuditID

	UPDATE DFL
	SET DFL.LocalEvents = T1.Events
	FROM ParallelRun.DailyFilesLoaded DFL
	JOIN (SELECT DISTINCT COUNT(MatchedODSEventID) AS Events, AuditID 
	FROM [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging
	WHERE LoadedDate >= @DateLastRun	-- V1.4
	GROUP BY AuditID) AS T1
	ON DFL.LocalAuditID = T1.AuditID

	--DROP TABLE #t1
	CREATE TABLE #t1 (EventID BIGINT, AuditID BIGINT, CaseID INT NULL)

	INSERT INTO #t1 (EventID ,AuditID)
	SELECT DISTINCT SL.MatchedODSEventID, F.AuditID 
	FROM ParallelRun.CaseDetails CD
	INNER JOIN ParallelRun.SampleQualityAndSelectionLogging SL ON CD.CaseID = SL.CaseID
	INNER JOIN ParallelRun.Files F ON SL.AuditID = F.AuditID
	WHERE CD.CreationDate >= F.ActionDate

	UPDATE #t1
	SET CaseID = cd.CaseID
	FROM ParallelRun.CaseDetails cd
	WHERE #t1.EventID = cd.EventID

	UPDATE DF
	SET RemoteCases = t3.Cases
	FROM ParallelRun.DailyFilesLoaded DF
	JOIN (SELECT COUNT(CaseID) AS Cases, AuditID
	FROM #t1
	GROUP BY AuditID) AS t3
	ON DF.RemoteAuditID = t3.AuditID


	--DROP TABLE #t2
	CREATE TABLE #t2 (EventID BIGINT, AuditID BIGINT, CaseID INT NULL)

	INSERT INTO #t2 (EventID ,AuditID)
	SELECT DISTINCT ae.EventID, f.AuditID 
	FROM [$(SampleDB)].Meta.CaseDetails CD
	JOIN [$(SampleDB)].Event.Cases c ON cd.CaseID = c.CaseID
	JOIN [$(AuditDB)].Audit.Events ae ON cd.EventID = ae.EventID
	JOIN [$(AuditDB)].dbo.AuditItems ai ON ae.AuditItemID = ai.AuditItemID
	JOIN [$(AuditDB)].dbo.Files f ON ai.AuditID = f.AuditID
	WHERE c.CreationDate >= f.ActionDate
	AND F.ActionDate >= @DateLastRun

	UPDATE #t2
	SET CaseID = cd.CaseID
	FROM [$(SampleDB)].Meta.CaseDetails cd
	WHERE #t2.EventID = cd.EventID

	UPDATE DF
	SET LocalCases = t3.Cases
	FROM ParallelRun.DailyFilesLoaded DF
	JOIN (SELECT COUNT(CaseID) AS Cases, AuditID
	FROM #t2
	GROUP BY AuditID) AS t3
	ON DF.LocalAuditID = t3.AuditID


	INSERT INTO ParallelRun.DailySelections(RemoteDateLastRun, RemoteRequirementID, RemoteRequirement, RemoteCaseCount, RemoteRejectionCount)
	SELECT S.DateLastRun, S.RequirementID, S.Requirement, S.RecordsSelected, S.RecordsRejected 
	FROM ParallelRun.Selections S


	UPDATE DS SET DS.LocalRequirementID = SR.RequirementID, DS.LocalRequirement = R.Requirement, DS.LocalDateLastRun = SR.DateLastRun, DS.LocalCaseCount = SR.RecordsSelected, DS.LocalRejectionCount = SR.RecordsRejected
	--SELECT SR.DateLastRun, R.RequirementID, R.Requirement, SR.RecordsSelected, SR.RecordsRejected 
	FROM [$(SampleDB)].Requirement.Requirements R
	JOIN [$(SampleDB)].Requirement.SelectionRequirements SR ON R.RequirementID = SR.RequirementID
	JOIN ParallelRun.DailySelections DS ON R.Requirement = DS.RemoteRequirement

	UPDATE DS SET DS.LocalRequirementID = SR.RequirementID, DS.LocalRequirement = R.Requirement, DS.LocalDateLastRun = SR.DateLastRun, DS.LocalCaseCount = SR.RecordsSelected, DS.LocalRejectionCount = SR.RecordsRejected
	--SELECT SR.DateLastRun, R.RequirementID, R.Requirement, SR.RecordsSelected, SR.RecordsRejected 
	FROM [$(SampleDB)].Requirement.Requirements R
	JOIN [$(SampleDB)].Requirement.SelectionRequirements SR ON R.RequirementID = SR.RequirementID
	JOIN ParallelRun.DailySelections DS ON SUBSTRING(R.Requirement, 1, (LEN(R.Requirement)-4)) = SUBSTRING(DS.RemoteRequirement, 1, (LEN(DS.RemoteRequirement)-4))
	WHERE LEN(R.Requirement) > 4

	-- FILE SUMMARY
	INSERT INTO ParallelRun.FileSummary
	SELECT COALESCE(F.RemoteFileName, F.LocalFileName) AS FileName, 
	CASE WHEN COALESCE(F.RemoteLoadSuccess, F.LocalLoadSuccess) = 1 THEN 'TRUE' ELSE 'FALSE' END AS [Sucess],
	F.RemoteFileRowCount AS [GfK FileRowCount],
	ISNULL(F.RemoteEvents,0) AS [GfK Events],
	ISNULL(F.RemoteCases,0) AS [GfK Cases],
	F.LocalFileRowCount AS [IPSOS FileRowCount],
	ISNULL(F.LocalEvents,0) AS [IPSOS Events],
	ISNULL(F.LocalCases,0) AS [IPSOS Cases],
	CASE WHEN ISNULL(F.RemoteEvents,0) = ISNULL(F.LocalEvents,0) THEN 'SAME' ELSE 'DIFF' END AS [Events],
	CASE WHEN ISNULL(F.RemoteCases,0) = ISNULL(F.LocalCases,0) THEN 'SAME' ELSE 'DIFF' END AS [Cases],
	ISNULL(F.LocalCases,0) - ISNULL(F.RemoteCases,0) AS [Difference]
	--CASE	WHEN ISNULL(F.LocalCases,0) = ISNULL(F.RemoteCases,0) THEN '-' 
	--		WHEN ISNULL(F.LocalCases,0) > ISNULL(F.RemoteCases,0) THEN '+' + CONVERT(VARCHAR,(F.LocalCases - F.RemoteCases))
	--		WHEN ISNULL(F.LocalCases,0) < ISNULL(F.RemoteCases,0) THEN CONVERT(VARCHAR,(F.LocalCases - F.RemoteCases))		END AS [Difference]
	FROM ParallelRun.DailyFilesLoaded F
	ORDER BY F.LocalFileName


	-- SELECTION SUMMARY
	INSERT INTO ParallelRun.SelectionSummary
	SELECT COALESCE(S.RemoteRequirement, S.LocalRequirement) AS [Requirement],
	ISNULL(S.RemoteCaseCount,0) AS [GfK Cases],
	ISNULL(S.LocalCaseCount,0) AS [IPSOS Cases],
	CASE WHEN ISNULL(S.RemoteCaseCount,0) = ISNULL(S.LocalCaseCount,0) THEN 'SAME' ELSE 'DIFF' END AS [Cases],
	ISNULL(S.LocalCaseCount,0) - ISNULL(S.RemoteCaseCount,0) AS [Difference]
	FROM ParallelRun.DailySelections S


	--DROP TABLE #LocalSelections
	SELECT DS.LocalRequirement, F.FileName, SL.PhysicalFileRow, SL.CaseID
	INTO #LocalSelections
	FROM ParallelRun.DailySelections DS
	INNER JOIN [$(SampleDB)].Requirement.SelectionCases SC ON DS.LocalRequirementID = SC.RequirementIDPartOf
	INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL ON CONVERT(INT, SC.CaseID) = CONVERT(INT, SL.CaseID)
	INNER JOIN [$(AuditDB)].dbo.Files F ON SL.AuditID = F.AuditID

	--DROP TABLE #RemoteSelections
	SELECT  
	DS.RemoteRequirement,
	PSL.FileName, 
	PSL.PhysicalFileRow, 
	PSL.CaseID
	INTO #RemoteSelections
	FROM ParallelRun.DailySelections DS
	INNER JOIN ParallelRun.Selections RS ON DS.RemoteRequirementID = RS.RequirementID
	INNER JOIN ParallelRun.SelectionCases RSC ON RS.RequirementID = RSC.RequirementID
	INNER JOIN ParallelRun.SampleQualityAndSelectionLogging PSL ON CONVERT(INT, RSC.CaseID) = CONVERT(INT, PSL.CaseID)

	--DROP TABLE #DistinctSelections
	SELECT DISTINCT LS.LocalRequirement AS Requirement, LS.FileName AS [FileName], LS.CaseID, 1 AS Cases
	INTO #DistinctSelections
	FROM #LocalSelections LS
	LEFT JOIN #RemoteSelections RS ON LS.FileName = RS.FileName
									AND LS.PhysicalFileRow = RS.PhysicalFileRow
	WHERE RS.RemoteRequirement IS NULL
	UNION
	SELECT DISTINCT RS.RemoteRequirement AS Requirement, RS.FileName AS [FileName], RS.CaseID, -1 AS Cases
	FROM #RemoteSelections RS
	LEFT JOIN #LocalSelections LS ON RS.FileName = LS.FileName
									AND RS.PhysicalFileRow = LS.PhysicalFileRow
	WHERE LS.LocalRequirement IS NULL

	-- CHECK
	--SELECT S.Requirement, SUM(S.Cases) AS Difference
	--FROM #DistinctSelections S
	--GROUP BY S.Requirement
	--ORDER BY S.Requirement

	--SELECT S.FileName, SUM(S.Cases) AS Difference
	--FROM #DistinctSelections S
	--GROUP BY S.FileName
	--ORDER BY S.FileName

	-- DROP TABLE #MismatchSelections
	SELECT LS.LocalRequirement AS Requirement, LS.FileName, LS.PhysicalFileRow
	INTO #MismatchSelections 
	FROM  #LocalSelections LS
	LEFT JOIN #RemoteSelections RS ON LS.FileName = RS.FileName
									AND LS.PhysicalFileRow = RS.PhysicalFileRow
	WHERE RS.RemoteRequirement IS NULL
	UNION
	SELECT RS.RemoteRequirement AS Requirement, RS.FileName AS FileName, RS.PhysicalFileRow
	FROM #RemoteSelections RS
	LEFT JOIN #LocalSelections LS ON RS.FileName = LS.FileName
									AND RS.PhysicalFileRow = LS.PhysicalFileRow
	WHERE LS.LocalRequirement IS NULL


	-- Mismatch Selections
	INSERT INTO ParallelRun.MismatchSelections
	SELECT MS.Requirement, MS.FileName, MS.PhysicalFileRow,
	'GfK' AS Source, 
	V.VIN, PSL.[AuditID], PSL.[AuditItemID], [ManufacturerID], [SampleSupplierPartyID], [MatchedODSPartyID], [PersonParentAuditItemID], [MatchedODSPersonID], PSL.[LanguageID], [PartySuppression], [OrganisationParentAuditItemID], [MatchedODSOrganisationID], [AddressParentAuditItemID], [MatchedODSAddressID], PSL.[CountryID], [PostalSuppression], [AddressChecksum], [MatchedODSTelID], [MatchedODSPrivTelID], [MatchedODSBusTelID], [MatchedODSMobileTelID], [MatchedODSPrivMobileTelID], [MatchedODSEmailAddressID], [MatchedODSPrivEmailAddressID], [EmailSuppression], [VehicleParentAuditItemID], [MatchedODSVehicleID], [ODSRegistrationID], [MatchedODSModelID], PSL.[OwnershipCycle], [MatchedODSEventID], [ODSEventTypeID], 
	[SaleDateOrig] AS [SaleDateOrig], 
	CAST([SaleDate] AS date) AS [SaleDate], 
	[ServiceDateOrig] AS [ServiceDateOrig], CAST([ServiceDate] AS date) AS [ServiceDate], [InvoiceDateOrig], [InvoiceDate], [WarrantyID], [SalesDealerCodeOriginatorPartyID], [SalesDealerCode], [SalesDealerID], [ServiceDealerCodeOriginatorPartyID], [ServiceDealerCode], [ServiceDealerID], [RoadsideNetworkOriginatorPartyID], PSL.[RoadsideNetworkCode], PSL.[RoadsideNetworkPartyID], 
	CAST([RoadsideDate] AS date) AS [RoadsideDate], [CRCCentreOriginatorPartyID], [CRCCentreCode], [CRCCentrePartyID], 
	CAST([CRCDate] AS date) AS [CRCDate], [Brand], [Market], PSL.[Questionnaire], PSL.[QuestionnaireRequirementID], [StartDays], [EndDays], [SuppliedName], [SuppliedAddress], [SuppliedPhoneNumber], [SuppliedMobilePhone], [SuppliedEmail], [SuppliedVehicle], [SuppliedRegistration], [SuppliedEventDate], [EventDateOutOfDate], [EventNonSolicitation], [PartyNonSolicitation], [UnmatchedModel], [UncodedDealer], [EventAlreadySelected], [NonLatestEvent], [InvalidOwnershipCycle], [RecontactPeriod], [InvalidVehicleRole], [CrossBorderAddress], [CrossBorderDealer], [ExclusionListMatch], [InvalidEmailAddress], [BarredEmailAddress], [BarredDomain], PSL.[CaseID], [SampleRowProcessed], 
	CAST([SampleRowProcessedDate] AS date) AS [SampleRowProcessedDate], [WrongEventType], [MissingStreet], [MissingPostcode], [MissingEmail], [MissingTelephone], [MissingStreetAndEmail], [MissingTelephoneAndEmail], [InvalidModel], [InvalidVariant], [MissingMobilePhone], [MissingMobilePhoneAndEmail], [MissingPartyName], [MissingLanguage], [CaseIDPrevious], [RelativeRecontactPeriod], [InvalidManufacturer], [InternalDealer], [EventDateTooYoung], [InvalidRoleType], [InvalidSaleType], [InvalidAFRLCode], [SuppliedAFRLCode], [DealerExclusionListMatch], [PhoneSuppression], 
	CAST([LostLeadDate] AS date) AS [LostLeadDate], [ContactPreferencesSuppression], [NotInQuota], [ContactPreferencesPartySuppress], [ContactPreferencesEmailSuppress], [ContactPreferencesPhoneSuppress], [ContactPreferencesPostalSuppress], [DealerPilotOutputFiltered], [InvalidCRMSaleType], [MissingLostLeadAgency], [PDIFlagSet], [BodyshopEventDateOrig], 
	CAST([BodyshopEventDate] AS date) AS [BodyshopEventDate], [BodyshopDealerCode], [BodyshopDealerID], [BodyshopDealerCodeOriginatorPartyID], [ContactPreferencesUnsubscribed], [SelectionOrganisationID], [SelectionPostalID], [SelectionEmailID], [SelectionPhoneID], [SelectionLandlineID], [SelectionMobileID], [NonSelectableWarrantyEvent], [IAssistanceCentreOriginatorPartyID], [IAssistanceCentreCode], [IAssistanceCentrePartyID], [IAssistanceDate], [InvalidDateOfLastContact]
	FROM #MismatchSelections MS
	INNER JOIN ParallelRun.SampleQualityAndSelectionLogging PSL ON MS.FileName = PSL.FileName
																					AND MS.PhysicalFileRow = PSL.PhysicalFileRow
	LEFT JOIN ParallelRun.Vehicle V ON PSL.AuditItemID = V.AuditItemID
	UNION
	SELECT MS.Requirement, MS.FileName, MS.PhysicalFileRow,
	'IPSOS' AS Source, 
	V.VIN, SL.[AuditID], SL.[AuditItemID], [ManufacturerID], [SampleSupplierPartyID], [MatchedODSPartyID], [PersonParentAuditItemID], [MatchedODSPersonID], SL.[LanguageID], [PartySuppression], [OrganisationParentAuditItemID], [MatchedODSOrganisationID], [AddressParentAuditItemID], [MatchedODSAddressID], SL.[CountryID], [PostalSuppression], [AddressChecksum], [MatchedODSTelID], [MatchedODSPrivTelID], [MatchedODSBusTelID], [MatchedODSMobileTelID], [MatchedODSPrivMobileTelID], [MatchedODSEmailAddressID], [MatchedODSPrivEmailAddressID], [EmailSuppression], [VehicleParentAuditItemID], [MatchedODSVehicleID], [ODSRegistrationID], [MatchedODSModelID], SL.[OwnershipCycle], [MatchedODSEventID], [ODSEventTypeID], 
	[SaleDateOrig] AS [SaleDateOrig], 
	CAST([SaleDate] AS date) AS [SaleDate], 
	[ServiceDateOrig] AS [ServiceDateOrig], CAST([ServiceDate] AS date) AS [ServiceDate], [InvoiceDateOrig], [InvoiceDate], [WarrantyID], [SalesDealerCodeOriginatorPartyID], [SalesDealerCode], [SalesDealerID], [ServiceDealerCodeOriginatorPartyID], [ServiceDealerCode], [ServiceDealerID], [RoadsideNetworkOriginatorPartyID], SL.[RoadsideNetworkCode], SL.[RoadsideNetworkPartyID], 
	CAST([RoadsideDate] AS date) AS [RoadsideDate], [CRCCentreOriginatorPartyID], [CRCCentreCode], [CRCCentrePartyID], 
	CAST([CRCDate] AS date) AS [CRCDate], [Brand], [Market], SL.[Questionnaire], SL.[QuestionnaireRequirementID], [StartDays], [EndDays], [SuppliedName], [SuppliedAddress], [SuppliedPhoneNumber], [SuppliedMobilePhone], [SuppliedEmail], [SuppliedVehicle], [SuppliedRegistration], [SuppliedEventDate], [EventDateOutOfDate], [EventNonSolicitation], [PartyNonSolicitation], [UnmatchedModel], [UncodedDealer], [EventAlreadySelected], [NonLatestEvent], [InvalidOwnershipCycle], [RecontactPeriod], [InvalidVehicleRole], [CrossBorderAddress], [CrossBorderDealer], [ExclusionListMatch], [InvalidEmailAddress], [BarredEmailAddress], [BarredDomain], SL.[CaseID], [SampleRowProcessed], 
	CAST([SampleRowProcessedDate] AS date) AS [SampleRowProcessedDate], [WrongEventType], [MissingStreet], [MissingPostcode], [MissingEmail], [MissingTelephone], [MissingStreetAndEmail], [MissingTelephoneAndEmail], [InvalidModel], [InvalidVariant], [MissingMobilePhone], [MissingMobilePhoneAndEmail], [MissingPartyName], [MissingLanguage], [CaseIDPrevious], [RelativeRecontactPeriod], [InvalidManufacturer], [InternalDealer], [EventDateTooYoung], [InvalidRoleType], [InvalidSaleType], [InvalidAFRLCode], [SuppliedAFRLCode], [DealerExclusionListMatch], [PhoneSuppression], 
	CAST([LostLeadDate] AS date) AS [LostLeadDate], [ContactPreferencesSuppression], [NotInQuota], [ContactPreferencesPartySuppress], [ContactPreferencesEmailSuppress], [ContactPreferencesPhoneSuppress], [ContactPreferencesPostalSuppress], [DealerPilotOutputFiltered], [InvalidCRMSaleType], [MissingLostLeadAgency], [PDIFlagSet], [BodyshopEventDateOrig], 
	CAST([BodyshopEventDate] AS date) AS [BodyshopEventDate], [BodyshopDealerCode], [BodyshopDealerID], [BodyshopDealerCodeOriginatorPartyID], [ContactPreferencesUnsubscribed], [SelectionOrganisationID], [SelectionPostalID], [SelectionEmailID], [SelectionPhoneID], [SelectionLandlineID], [SelectionMobileID], [NonSelectableWarrantyEvent], [IAssistanceCentreOriginatorPartyID], [IAssistanceCentreCode], [IAssistanceCentrePartyID], [IAssistanceDate], [InvalidDateOfLastContact]
	FROM #MismatchSelections MS
	INNER JOIN [$(AuditDB)].dbo.Files F ON MS.FileName = F.FileName
	LEFT JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL ON F.AuditID = SL.AuditID
																		AND MS.PhysicalFileRow = SL.PhysicalFileRow
	LEFT JOIN [$(SampleDB)].Vehicle.Vehicles V ON SL.MatchedODSVehicleID = V.VehicleID


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