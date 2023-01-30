CREATE PROCEDURE [ParallelRun].[uspOutputPackage_LoggingTable]
	@RefreshDate	DATETIME
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
	Purpose:	Outputs the logging table information for comparison
		
	Version		Date				Developer			Comment
	1.0			09/07/2019			Chris Ross			Created
	1.1			26/07/2019			Chris Ross			Add in all logging records which have a processed date after the refresh date
	1.2			15/01/2020			Chris Ledger		BUG 15372 - Fix Hard coded references to databases
*/


		;WITH CTE_AuditItems
		AS (
			SELECT ai.AuditItemID 
						FROM [$(AuditDB)].dbo.Files f 
						INNER JOIN [$(AuditDB)].dbo.AuditItems ai ON f.AuditID = ai.AuditID
						WHERE f.ActionDate >= @RefreshDate
					UNION 
						SELECT sq.AuditItemID
						FROM [$(SampleDB)].Event.Cases c
						INNER JOIN [$(WebsiteReporting)].[dbo].[SampleQualityAndSelectionLogging] sq ON sq.CaseID = c.CaseID
						WHERE c.CreationDate >= @RefreshDate
					UNION 
						SELECT sq.AuditItemID															-- v1.1
						FROM [$(WebsiteReporting)].[dbo].[SampleQualityAndSelectionLogging] sq 
						WHERE sq.SampleRowProcessedDate >=  @RefreshDate
			)
		SELECT f.FileName, [LoadedDate], sq.[AuditID], c.[AuditItemID], [PhysicalFileRow], [ManufacturerID], [SampleSupplierPartyID], [MatchedODSPartyID], [PersonParentAuditItemID], [MatchedODSPersonID], [LanguageID], [PartySuppression], [OrganisationParentAuditItemID], [MatchedODSOrganisationID], [AddressParentAuditItemID], [MatchedODSAddressID], [CountryID], [PostalSuppression], [AddressChecksum], [MatchedODSTelID], [MatchedODSPrivTelID], [MatchedODSBusTelID], [MatchedODSMobileTelID], [MatchedODSPrivMobileTelID], [MatchedODSEmailAddressID], [MatchedODSPrivEmailAddressID], [EmailSuppression], [VehicleParentAuditItemID], [MatchedODSVehicleID], [ODSRegistrationID], [MatchedODSModelID], [OwnershipCycle], [MatchedODSEventID], [ODSEventTypeID], [SaleDateOrig], [SaleDate], [ServiceDateOrig], [ServiceDate], [InvoiceDateOrig], [InvoiceDate], [WarrantyID], [SalesDealerCodeOriginatorPartyID], [SalesDealerCode], [SalesDealerID], [ServiceDealerCodeOriginatorPartyID], [ServiceDealerCode], [ServiceDealerID], [RoadsideNetworkOriginatorPartyID], [RoadsideNetworkCode], [RoadsideNetworkPartyID], [RoadsideDate], [CRCCentreOriginatorPartyID], [CRCCentreCode], [CRCCentrePartyID], [CRCDate], [Brand], [Market], [Questionnaire], [QuestionnaireRequirementID], [StartDays], [EndDays], [SuppliedName], [SuppliedAddress], [SuppliedPhoneNumber], [SuppliedMobilePhone], [SuppliedEmail], [SuppliedVehicle], [SuppliedRegistration], [SuppliedEventDate], [EventDateOutOfDate], [EventNonSolicitation], [PartyNonSolicitation], [UnmatchedModel], [UncodedDealer], [EventAlreadySelected], [NonLatestEvent], [InvalidOwnershipCycle], [RecontactPeriod], [InvalidVehicleRole], [CrossBorderAddress], [CrossBorderDealer], [ExclusionListMatch], [InvalidEmailAddress], [BarredEmailAddress], [BarredDomain], [CaseID], [SampleRowProcessed], [SampleRowProcessedDate], [WrongEventType], [MissingStreet], [MissingPostcode], [MissingEmail], [MissingTelephone], [MissingStreetAndEmail], [MissingTelephoneAndEmail], [InvalidModel], [InvalidVariant], [MissingMobilePhone], [MissingMobilePhoneAndEmail], [MissingPartyName], [MissingLanguage], [CaseIDPrevious], [RelativeRecontactPeriod], [InvalidManufacturer], [InternalDealer], [EventDateTooYoung], [InvalidRoleType], [InvalidSaleType], [InvalidAFRLCode], [SuppliedAFRLCode], [DealerExclusionListMatch], [PhoneSuppression], [LostLeadDate], [ContactPreferencesSuppression], [NotInQuota], [ContactPreferencesPartySuppress], [ContactPreferencesEmailSuppress], [ContactPreferencesPhoneSuppress], [ContactPreferencesPostalSuppress], [DealerPilotOutputFiltered], [InvalidCRMSaleType], [MissingLostLeadAgency], [PDIFlagSet], [BodyshopEventDateOrig], [BodyshopEventDate], [BodyshopDealerCode], [BodyshopDealerID], [BodyshopDealerCodeOriginatorPartyID], [ContactPreferencesUnsubscribed], [SelectionOrganisationID], [SelectionPostalID], [SelectionEmailID], [SelectionPhoneID], [SelectionLandlineID], [SelectionMobileID], [NonSelectableWarrantyEvent], [IAssistanceCentreOriginatorPartyID], [IAssistanceCentreCode], [IAssistanceCentrePartyID], [IAssistanceDate], [InvalidDateOfLastContact]
		FROM CTE_AuditItems c
		INNER JOIN [$(WebsiteReporting)].[dbo].[SampleQualityAndSelectionLogging] sq ON sq.AuditItemID = c.AuditItemID
		INNER JOIN [$(AuditDB)].dbo.Files f ON f.AuditID = sq.AuditID


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
