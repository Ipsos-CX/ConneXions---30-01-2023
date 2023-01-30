CREATE PROCEDURE [Stage].[uspReportRecordsRemovedVWT]

AS
SET NOCOUNT ON

/*
	Purpose:	Mandatory checks before sample process
			
	Release			Version			Date			Developer			Comment
	LIVE			1.0				07/08/2019		Ben King			Creation BUG 15518
	LIVE			1.1				24/03/2020		Ben King			BUG 18014 - remove Manufacturer ID = 0
	LIVE			1.2				11/01/2022		Ben King			TASK 738 General Tidy up of solution
	LIVE			1.3				07/04/2022		Ben King			TASK 848 - Update uspReportRecordsRemovedVWT step to check for country ID
*/

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)


BEGIN TRY

	DECLARE @EmailRecipients nvarchar(250);

	--V1.2
	IF @@ServerName = '1005796-CXNSQLP'
		BEGIN
			SET @EmailRecipients = 'Andrew.Erskine@ipsos.com; Pia.Forslund@ipsos.com; ben.king@ipsos.com; Eddie.Thomas@ipsos.com; Chris.Ledger@ipsos.com; Dipak.Gohil@ipsos.com'
		END
	ELSE
		BEGIN
			SET @EmailRecipients = 'ben.king@ipsos.com;Chris.ledger@ipsos.com;Eddie.Thomas@ipsos.com'
		END	

	IF Exists( 
				--check for empty records loaded
				SELECT V.* 
				FROM dbo.VWT V
				WHERE LEN(ISNULL(CAST(V.[TypeOfSaleOrig] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[AFRLCode] AS NVARCHAR),'') + 
					--ISNULL(CAST(V.[SuppliedIndustryClassificationID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[SampleTriggeredSelectionReqID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[PartyMatchingMethodologyID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[PersonParentAuditItemID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[Title] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[Initials] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[FirstNameOrig] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[FirstName] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[MiddleName] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[LastNameOrig] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[LastName] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[SecondLastNameOrig] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[SecondLastName] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[BirthDate] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[CustomerIdentifier] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[Salutation] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[OrganisationParentAuditItemID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[OrganisationNameOrig] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[OrganisationName] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[AddressParentAuditItemID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[BuildingName] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[SubStreetAndNumberOrig] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[SubStreetOrig] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[SubStreetNumber] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[SubStreet] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[StreetAndNumberOrig] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[StreetOrig] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[StreetNumber] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[Street] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[SubLocality] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[Locality] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[Town] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[Region] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[Postcode] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[Country] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[AddressChecksum] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[MatchedODSTelID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[Tel] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[MatchedODSPrivTelID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[PrivTel] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[MatchedODSBusTelID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[BusTel] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[MatchedODSMobileTelID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[MobileTel] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[MatchedODSPrivMobileTelID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[PrivMobileTel] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[MatchedODSEmailAddressID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[EmailAddress] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[MatchedODSPrivEmailAddressID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[PrivEmailAddress] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[VehicleParentAuditItemID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[VehicleIdentificationNumber] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[ODSRegistrationID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[VehicleRegistrationNumber] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[RegistrationDateOrig] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[RegistrationDate] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[MatchedODSModelID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[ModelDescription] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[BodystyleDescription] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[EngineDescription] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[TransmissionDescription] AS NVARCHAR),'') + 
					--ISNULL(CAST(V.[Driverindicator] AS NVARCHAR),'') + 
					--ISNULL(CAST(V.[OwnerIndicator] AS NVARCHAR),'') + 
					--ISNULL(CAST(V.[ManagerIndicator] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[BuildDateOrig] AS NVARCHAR),'') + 
					--ISNULL(CAST(V.[BuildYear] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[SaleDateOrig] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[SaleDate] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[ServiceDateOrig] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[ServiceDate] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[RoadsideDateOrig] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[RoadsideDate] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[CRCDateOrig] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[CRCDate] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[LostLeadDateOrig] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[LostLeadDate] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[InvoiceDateOrig] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[InvoiceDate] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[IAssistanceDateOrig] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[IAssistanceDate] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[WarrantyID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[RoadsideID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[CRC_ID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[IAssistanceID] AS NVARCHAR),'') + 
					--ISNULL(CAST(V.[SalesDealerCodeOriginatorPartyID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[SalesDealerCode] AS NVARCHAR),'') + 
					--ISNULL(CAST(V.[ServiceDealerCode] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[Approved] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[RoadsideNetworkOriginatorPartyID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[RoadsideNetworkCode] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[CRCCentreOriginatorPartyID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[CRCCentreCode] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[IAssistanceCentreOriginatorPartyID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[IAssistanceCentreCode] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[SalesOrderNumber] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[SalesCustomerType] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[SalesPaymentType] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[Salesman] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[ContractRelationship] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[ContractCustomer] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[SalesmanCode] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[AdditionalCountry] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[State] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[LostLead_DateOfLeadCreationOrig] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[ServiceAdvisorID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[ServiceAdvisorName] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[TechnicianID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[TechnicianName] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[VehicleSalePrice] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[SalesAdvisorID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[SalesAdvisorName] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[PDI_Flag] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[VehiclePurchaseDate] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[VehicleDeliveryDate] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[JLRSuppliedEventType] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[InvoiceNumber] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[InvoiceValue] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[PrivateOwner] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[OwningCompany] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[UserChooserDriver] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[EmployerCompany] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[MonthAndYearOfBirth] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[PreferredMethodOfContact] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[EventParentAuditItemID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[LostLead_DateOfLeadCreation] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[BodyShopEventDateOrig] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[BodyShopEventDate] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[BodyshopDealerCode] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[BodyshopDealerID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[BodyshopDealerCodeOriginatorPartyID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[LostLead_MarketingPermission] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[LostLead_CompleteSuppressionJLR] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[LostLead_CompleteSuppressionRetailer] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[LostLead_PermissionToEmailJLR] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[LostLead_PermissionToEmailRetailer] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[LostLead_PermissionToPhoneJLR] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[LostLead_PermissionToPhoneRetailer] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[LostLead_PermissionToPostJLR] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[LostLead_PermissionToPostRetailer] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[LostLead_PermissionToSMSJLR] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[LostLead_PermissionToSMSRetailer] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[LostLead_PermissionToSocialMediaJLR] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[LostLead_PermissionToSocialMediaRetailer] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[LostLead_DateOfLastContact] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[LostLead_ConvertedDateOfLastContact] AS NVARCHAR),'')) = 0
			)			 
	BEGIN
				--Insert empty records into holding table
				INSERT INTO [Stage].[Removed_Empty_Records_VWT] ([AuditID], [FileName], [ActionDate], [PhysicalFileRow])
				SELECT V.[AuditID], F.[FileName], F.[ActionDate], V.[PhysicalFileRow]
				FROM dbo.VWT V
				INNER JOIN [$(AuditDB)].dbo.Files F ON V.AuditID = F.AuditID
				WHERE LEN(ISNULL(CAST(V.[TypeOfSaleOrig] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[AFRLCode] AS NVARCHAR),'') + 
					--ISNULL(CAST(V.[SuppliedIndustryClassificationID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[SampleTriggeredSelectionReqID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[PartyMatchingMethodologyID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[PersonParentAuditItemID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[Title] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[Initials] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[FirstNameOrig] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[FirstName] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[MiddleName] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[LastNameOrig] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[LastName] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[SecondLastNameOrig] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[SecondLastName] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[BirthDate] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[CustomerIdentifier] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[Salutation] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[OrganisationParentAuditItemID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[OrganisationNameOrig] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[OrganisationName] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[AddressParentAuditItemID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[BuildingName] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[SubStreetAndNumberOrig] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[SubStreetOrig] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[SubStreetNumber] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[SubStreet] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[StreetAndNumberOrig] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[StreetOrig] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[StreetNumber] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[Street] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[SubLocality] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[Locality] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[Town] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[Region] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[Postcode] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[Country] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[AddressChecksum] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[MatchedODSTelID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[Tel] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[MatchedODSPrivTelID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[PrivTel] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[MatchedODSBusTelID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[BusTel] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[MatchedODSMobileTelID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[MobileTel] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[MatchedODSPrivMobileTelID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[PrivMobileTel] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[MatchedODSEmailAddressID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[EmailAddress] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[MatchedODSPrivEmailAddressID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[PrivEmailAddress] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[VehicleParentAuditItemID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[VehicleIdentificationNumber] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[ODSRegistrationID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[VehicleRegistrationNumber] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[RegistrationDateOrig] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[RegistrationDate] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[MatchedODSModelID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[ModelDescription] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[BodystyleDescription] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[EngineDescription] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[TransmissionDescription] AS NVARCHAR),'') + 
					--ISNULL(CAST(V.[Driverindicator] AS NVARCHAR),'') + 
					--ISNULL(CAST(V.[OwnerIndicator] AS NVARCHAR),'') + 
					--ISNULL(CAST(V.[ManagerIndicator] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[BuildDateOrig] AS NVARCHAR),'') + 
					--ISNULL(CAST(V.[BuildYear] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[SaleDateOrig] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[SaleDate] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[ServiceDateOrig] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[ServiceDate] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[RoadsideDateOrig] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[RoadsideDate] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[CRCDateOrig] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[CRCDate] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[LostLeadDateOrig] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[LostLeadDate] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[InvoiceDateOrig] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[InvoiceDate] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[IAssistanceDateOrig] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[IAssistanceDate] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[WarrantyID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[RoadsideID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[CRC_ID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[IAssistanceID] AS NVARCHAR),'') + 
					--ISNULL(CAST(V.[SalesDealerCodeOriginatorPartyID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[SalesDealerCode] AS NVARCHAR),'') + 
					--ISNULL(CAST(V.[ServiceDealerCode] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[Approved] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[RoadsideNetworkOriginatorPartyID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[RoadsideNetworkCode] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[CRCCentreOriginatorPartyID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[CRCCentreCode] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[IAssistanceCentreOriginatorPartyID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[IAssistanceCentreCode] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[SalesOrderNumber] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[SalesCustomerType] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[SalesPaymentType] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[Salesman] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[ContractRelationship] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[ContractCustomer] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[SalesmanCode] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[AdditionalCountry] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[State] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[LostLead_DateOfLeadCreationOrig] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[ServiceAdvisorID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[ServiceAdvisorName] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[TechnicianID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[TechnicianName] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[VehicleSalePrice] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[SalesAdvisorID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[SalesAdvisorName] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[PDI_Flag] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[VehiclePurchaseDate] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[VehicleDeliveryDate] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[JLRSuppliedEventType] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[InvoiceNumber] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[InvoiceValue] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[PrivateOwner] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[OwningCompany] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[UserChooserDriver] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[EmployerCompany] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[MonthAndYearOfBirth] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[PreferredMethodOfContact] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[EventParentAuditItemID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[LostLead_DateOfLeadCreation] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[BodyShopEventDateOrig] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[BodyShopEventDate] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[BodyshopDealerCode] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[BodyshopDealerID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[BodyshopDealerCodeOriginatorPartyID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[LostLead_MarketingPermission] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[LostLead_CompleteSuppressionJLR] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[LostLead_CompleteSuppressionRetailer] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[LostLead_PermissionToEmailJLR] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[LostLead_PermissionToEmailRetailer] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[LostLead_PermissionToPhoneJLR] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[LostLead_PermissionToPhoneRetailer] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[LostLead_PermissionToPostJLR] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[LostLead_PermissionToPostRetailer] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[LostLead_PermissionToSMSJLR] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[LostLead_PermissionToSMSRetailer] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[LostLead_PermissionToSocialMediaJLR] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[LostLead_PermissionToSocialMediaRetailer] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[LostLead_DateOfLastContact] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[LostLead_ConvertedDateOfLastContact] AS NVARCHAR),'')) = 0

				--Remove empty records from VWT		
				DELETE V
				FROM dbo.VWT V
				WHERE LEN(ISNULL(CAST(V.[TypeOfSaleOrig] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[AFRLCode] AS NVARCHAR),'') + 
					--ISNULL(CAST(V.[SuppliedIndustryClassificationID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[SampleTriggeredSelectionReqID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[PartyMatchingMethodologyID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[PersonParentAuditItemID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[Title] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[Initials] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[FirstNameOrig] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[FirstName] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[MiddleName] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[LastNameOrig] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[LastName] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[SecondLastNameOrig] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[SecondLastName] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[BirthDate] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[CustomerIdentifier] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[Salutation] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[OrganisationParentAuditItemID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[OrganisationNameOrig] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[OrganisationName] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[AddressParentAuditItemID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[BuildingName] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[SubStreetAndNumberOrig] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[SubStreetOrig] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[SubStreetNumber] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[SubStreet] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[StreetAndNumberOrig] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[StreetOrig] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[StreetNumber] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[Street] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[SubLocality] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[Locality] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[Town] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[Region] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[Postcode] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[Country] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[AddressChecksum] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[MatchedODSTelID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[Tel] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[MatchedODSPrivTelID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[PrivTel] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[MatchedODSBusTelID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[BusTel] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[MatchedODSMobileTelID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[MobileTel] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[MatchedODSPrivMobileTelID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[PrivMobileTel] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[MatchedODSEmailAddressID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[EmailAddress] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[MatchedODSPrivEmailAddressID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[PrivEmailAddress] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[VehicleParentAuditItemID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[VehicleIdentificationNumber] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[ODSRegistrationID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[VehicleRegistrationNumber] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[RegistrationDateOrig] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[RegistrationDate] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[MatchedODSModelID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[ModelDescription] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[BodystyleDescription] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[EngineDescription] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[TransmissionDescription] AS NVARCHAR),'') + 
					--ISNULL(CAST(V.[Driverindicator] AS NVARCHAR),'') + 
					--ISNULL(CAST(V.[OwnerIndicator] AS NVARCHAR),'') + 
					--ISNULL(CAST(V.[ManagerIndicator] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[BuildDateOrig] AS NVARCHAR),'') + 
					--ISNULL(CAST(V.[BuildYear] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[SaleDateOrig] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[SaleDate] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[ServiceDateOrig] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[ServiceDate] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[RoadsideDateOrig] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[RoadsideDate] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[CRCDateOrig] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[CRCDate] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[LostLeadDateOrig] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[LostLeadDate] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[InvoiceDateOrig] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[InvoiceDate] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[IAssistanceDateOrig] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[IAssistanceDate] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[WarrantyID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[RoadsideID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[CRC_ID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[IAssistanceID] AS NVARCHAR),'') + 
					--ISNULL(CAST(V.[SalesDealerCodeOriginatorPartyID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[SalesDealerCode] AS NVARCHAR),'') + 
					--ISNULL(CAST(V.[ServiceDealerCode] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[Approved] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[RoadsideNetworkOriginatorPartyID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[RoadsideNetworkCode] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[CRCCentreOriginatorPartyID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[CRCCentreCode] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[IAssistanceCentreOriginatorPartyID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[IAssistanceCentreCode] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[SalesOrderNumber] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[SalesCustomerType] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[SalesPaymentType] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[Salesman] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[ContractRelationship] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[ContractCustomer] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[SalesmanCode] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[AdditionalCountry] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[State] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[LostLead_DateOfLeadCreationOrig] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[ServiceAdvisorID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[ServiceAdvisorName] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[TechnicianID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[TechnicianName] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[VehicleSalePrice] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[SalesAdvisorID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[SalesAdvisorName] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[PDI_Flag] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[VehiclePurchaseDate] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[VehicleDeliveryDate] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[JLRSuppliedEventType] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[InvoiceNumber] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[InvoiceValue] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[PrivateOwner] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[OwningCompany] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[UserChooserDriver] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[EmployerCompany] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[MonthAndYearOfBirth] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[PreferredMethodOfContact] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[EventParentAuditItemID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[LostLead_DateOfLeadCreation] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[BodyShopEventDateOrig] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[BodyShopEventDate] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[BodyshopDealerCode] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[BodyshopDealerID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[BodyshopDealerCodeOriginatorPartyID] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[LostLead_MarketingPermission] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[LostLead_CompleteSuppressionJLR] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[LostLead_CompleteSuppressionRetailer] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[LostLead_PermissionToEmailJLR] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[LostLead_PermissionToEmailRetailer] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[LostLead_PermissionToPhoneJLR] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[LostLead_PermissionToPhoneRetailer] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[LostLead_PermissionToPostJLR] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[LostLead_PermissionToPostRetailer] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[LostLead_PermissionToSMSJLR] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[LostLead_PermissionToSMSRetailer] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[LostLead_PermissionToSocialMediaJLR] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[LostLead_PermissionToSocialMediaRetailer] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[LostLead_DateOfLastContact] AS NVARCHAR),'') + 
					ISNULL(CAST(V.[LostLead_ConvertedDateOfLastContact] AS NVARCHAR),'')) = 0
		
		--Send Email of removed records
		DECLARE @html nvarchar(MAX);
		EXEC dbo.spQueryToHtmlTable @html = @html OUTPUT,  @query = N'SELECT AuditID AS [Audit ID], FileName AS [FileName], CONVERT(varchar(10), ActionDate, 120) AS [Loaded date], PhysicalFileRow AS [File row] FROM [Stage].[Removed_Empty_Records_VWT] WHERE [EmailSent] IS NULL', @orderBy = N'ORDER BY [Audit ID]';

		EXEC msdb.dbo.sp_send_dbmail
		   @profile_name = 'DBAProfile',
		   @recipients = @EmailRecipients, --V1.2
		   @subject = 'Empty records removed from VWT before Full Load',
		   @body = @html,
		   @body_format = 'HTML'

		UPDATE [Stage].[Removed_Empty_Records_VWT]
		SET    [EmailSent] = GETDATE()
		WHERE  [EmailSent] IS NULL

	END

	--V1.1
	IF Exists( 
				--check for empty records loaded
				SELECT V.* 
				FROM dbo.VWT V
				WHERE V.[ManufacturerID] = 0
			)			 
	BEGIN
				--Insert empty records into holding table
				INSERT INTO [Stage].[Removed_Empty_Records_VWT] ([AuditID], [FileName], [ActionDate], [PhysicalFileRow])
				SELECT V.[AuditID], F.[FileName], F.[ActionDate], V.[PhysicalFileRow]
				FROM dbo.VWT V
				INNER JOIN [$(AuditDB)].DBO.Files F ON V.AuditID = F.AuditID
				WHERE V.[ManufacturerID] = 0

				--Remove empty records from VWT		
				DELETE V
				FROM dbo.VWT V
				WHERE V.[ManufacturerID] = 0

		--Send Email of removed records
		EXEC dbo.spQueryToHtmlTable @html = @html OUTPUT,  @query = N'SELECT AuditID AS [Audit ID], FileName AS [FileName], CONVERT(varchar(10), ActionDate, 120) AS [Loaded date], PhysicalFileRow AS [File row] FROM [Stage].[Removed_Empty_Records_VWT] WHERE [EmailSent] IS NULL', @orderBy = N'ORDER BY [Audit ID]';

		EXEC msdb.dbo.sp_send_dbmail
		   @profile_name = 'DBAProfile',
		   @recipients = @EmailRecipients, --V1.2
		   @subject = 'Records removed from VWT before Full Load - Manufacturer ID set to 0',
		   @body = @html,
		   @body_format = 'HTML'

		UPDATE [Stage].[Removed_Empty_Records_VWT]
		SET    [EmailSent] = GETDATE()
		WHERE  [EmailSent] IS NULL

	END

	--V1.3
	IF Exists( 
				--check for empty records loaded
				SELECT V.* 
				FROM dbo.VWT V
				WHERE ISNULL(V.[CountryID],0) = 0
			)			 
	BEGIN
				--Insert empty records into holding table
				INSERT INTO [Stage].[Removed_Empty_Records_VWT] ([AuditID], [FileName], [ActionDate], [PhysicalFileRow])
				SELECT V.[AuditID], F.[FileName], F.[ActionDate], V.[PhysicalFileRow]
				FROM dbo.VWT V
				INNER JOIN [$(AuditDB)].DBO.Files F ON V.AuditID = F.AuditID
				WHERE ISNULL(V.[CountryID],0) = 0

				--Remove empty records from VWT		
				DELETE V
				FROM dbo.VWT V
				WHERE ISNULL(V.[CountryID],0) = 0

		--Send Email of removed records
		EXEC dbo.spQueryToHtmlTable @html = @html OUTPUT,  @query = N'SELECT AuditID AS [Audit ID], FileName AS [FileName], CONVERT(varchar(10), ActionDate, 120) AS [Loaded date], PhysicalFileRow AS [File row] FROM [Stage].[Removed_Empty_Records_VWT] WHERE [EmailSent] IS NULL', @orderBy = N'ORDER BY [Audit ID]';

		EXEC msdb.dbo.sp_send_dbmail
		   @profile_name = 'DBAProfile',
		   @recipients = @EmailRecipients, --V1.2
		   @subject = 'Records removed from VWT before Full Load - Country ID set to 0',
		   @body = @html,
		   @body_format = 'HTML'

		UPDATE [Stage].[Removed_Empty_Records_VWT]
		SET    [EmailSent] = GETDATE()
		WHERE  [EmailSent] IS NULL

	END

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