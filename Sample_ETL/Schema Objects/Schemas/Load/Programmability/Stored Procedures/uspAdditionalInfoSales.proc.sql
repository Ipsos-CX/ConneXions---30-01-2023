CREATE PROCEDURE Load.uspAdditionalInfoSales

AS

/*
	Purpose:	Write additional sales info to the Sample database
				This data does not realted to connexions processes so is not modeled so dump it in a junk table.
	
				Version		Date			Developer			Comment
	LIVE		1.0			31/01/2014		Martin Riverol		Created
	LIVE		1.1			11/03/2015		Eddie Thomas		Additional fields added. Bug 11105 :Netherlands - Service Event Driven Setup
	LIVE		1.2			13/03/2015		Chris Ross			BUG 11273 - New columns (AddtionalCountry and State) added for VISTA loaders
	LIVE		1.3			03/02/2016		Chris Ross			BUG 12268 - Add in new column: Approved
	LIVE		1.4			19/08/2016		Chris Ross			BUG 12859 - Add in new column LostLead_DateOfLeadCreation
	LIVE		1.5			23/01/2017		Chris Ross			BUG 13646 - Add in ServiceAdvisorID, ServiceAdvisor, TechnicianID and TechnicianName columns
	LIVE		1.6			27/01/2017		Chris Ross			BUG 13510 - Add in VehicleSalePrice, SalesAdvisorID and SalesAdvisor columns
	LIVE		1.7			05/05/2017		Chris Ledger		BUG 13897 - Add in LostLead_DateOfLeadCreationOrig 
	LIVE		1.8			31/08/2017		Chris Ross			BUG 14122 - Add in PDI_Flag
	LIVE		1.9			20/03/2018		Chris Ross			BUG 14413 - Add in EventParentAuditItemID to identify the Lost Lead row used, where there are dupes.
	LIVE		1.10		01/08/2018		Eddie Thomas		BUG 14820 - Added new fields for Lost Leads
	LIVE		1.11		23/10/2018		Chris Ledger		BUG 15056 - Add in IAssistanceHelpdeskAdvisorName & IAssistanceHelpdeskAdvisorID
	LIVE		1.12		13/01/2020		Eddie Thomas		BUG 16850 - Added RONumber (WIPNumber Loyalty Logistix Loaders) 
	LIVE		1.13		07/06/2022		Ben King			TASK 880 - Land Rover Experience - Update Load from VWT package
	LIVE		1.14		22/06/2022		Ben King			TASK 899 - CXP Sales Loader change to use 3 additional fields
*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	INSERT INTO [$(SampleDB)].Event.vwDA_AdditionalInfoSales
	(
		AuditItemID
		, EventID
		, SalesOrderNumber
		, SalesCustomerType
		, SalesPaymentType
		, Salesman
		, ContractRelationship
		, ContractCustomer
		, SalesmanCode
		, InvoiceNumber					--1.1
        , InvoiceValue					--1.1
        , PrivateOwner					--1.1
        , OwningCompany					--1.1
        , UserChooserDriver				--1.1
        , EmployerCompany				--1.1
        , AdditionalCountry				--1.2
        , State							--1.2
        , VehiclePurchaseDate			--1.1
		, VehicleDeliveryDate			--1.1
		, TypeOfSaleOrig
		, Approved						--v1.3
		, LostLead_DateOfLeadCreationOrig  --v1.4
		, LostLead_DateOfLeadCreation	-- V1.7
		, ServiceAdvisorID				--1.5
		, ServiceAdvisorName			--1.5
		, TechnicianID					--1.5
		, TechnicianName				--1.5
		, VehicleSalePrice				-- v1.6
		, SalesAdvisorID				-- v1.6
		, SalesAdvisorName				-- v1.6
		, PDI_Flag						-- v1.8
		, ParentAuditItemID				-- v1.9
		, LostLead_MarketingPermission			-- v1.10
		, LostLead_CompleteSuppressionJLR		-- v1.10
		, LostLead_CompleteSuppressionRetailer	-- v1.10
		, LostLead_PermissionToEmailJLR			-- v1.10
		, LostLead_PermissionToEmailRetailer	-- v1.10
		, LostLead_PermissionToPhoneJLR			-- v1.10
		, LostLead_PermissionToPhoneRetailer	-- v1.10
		, LostLead_PermissionToPostJLR			-- v1.10
		, LostLead_PermissionToPostRetailer		-- v1.10
		, LostLead_PermissionToSMSJLR			-- v1.10
		, LostLead_PermissionToSMSRetailer		-- v1.10
		, LostLead_PermissionToSocialMediaJLR	-- v1.10
		, LostLead_PermissionToSocialMediaRetailer -- v1.10
		, LostLead_DateOfLastContact			-- v1.10
		, LostLead_ConvertedDateOfLastContact	-- v1.10
		, JLRSuppliedEventType					-- v1.10
		, IAssistanceHelpdeskAdvisorName		-- V1.11
		, IAssistanceHelpdeskAdvisorID			-- V1.11
		, RONumber								-- V1.12
		, LandRoverExperienceID					-- V1.13
		, CommonSaleType						-- V1.14
		, TypeOfSaleID							-- V1.14
)

		SELECT 
			AuditItemID
			, EventID
			, SalesOrderNumber
			, SalesCustomerType
			, SalesPaymentType
			, Salesman
			, ContractRelationship
			, ContractCustomer
			, SalesmanCode
			, InvoiceNumber				--1.1
			, InvoiceValue				--1.1
			, PrivateOwner				--1.1
			, OwningCompany				--1.1
			, UserChooserDriver			--1.1
			, EmployerCompany			--1.1
			, AdditionalCountry			--1.2
			, State						--1.2
			, VehiclePurchaseDate		--1.1
			, VehicleDeliveryDate		--1.1
			, TypeOfSaleOrig
			, Approved					--v1.3
			, LostLead_DateOfLeadCreationOrig	-- v1.4
			, LostLead_DateOfLeadCreation		-- V1.7
			, ServiceAdvisorID					--1.5
			, ServiceAdvisorName				--1.5
			, TechnicianID						--1.5
			, TechnicianName					--1.5
			, VehicleSalePrice				-- v1.6
			, SalesAdvisorID				-- v1.6
			, SalesAdvisorName				-- v1.6
			, PDI_Flag						-- v1.8
			, EventParentAuditItemID		-- v1.9
			, LostLead_MarketingPermission			-- v1.10
			, LostLead_CompleteSuppressionJLR		-- v1.10
			, LostLead_CompleteSuppressionRetailer	-- v1.10
			, LostLead_PermissionToEmailJLR			-- v1.10
			, LostLead_PermissionToEmailRetailer	-- v1.10
			, LostLead_PermissionToPhoneJLR			-- v1.10
			, LostLead_PermissionToPhoneRetailer	-- v1.10
			, LostLead_PermissionToPostJLR			-- v1.10
			, LostLead_PermissionToPostRetailer		-- v1.10
			, LostLead_PermissionToSMSJLR			-- v1.10
			, LostLead_PermissionToSMSRetailer		-- v1.10
			, LostLead_PermissionToSocialMediaJLR	-- v1.10
			, LostLead_PermissionToSocialMediaRetailer -- v1.10
			, LostLead_DateOfLastContact			-- v1.10
			, LostLead_ConvertedDateOfLastContact	-- v1.10
			, JLRSuppliedEventType					-- v1.10
			, IAssistanceHelpdeskAdvisorName		-- V1.11
			, IAssistanceHelpdeskAdvisorID			-- V1.11
			, RONumber								-- V1.12
			, LandRoverExperienceID					-- v1.13
			, CommonSaleType						-- V1.14
			, TypeOfSaleID							-- V1.14
		FROM Load.vwAdditionalInfoSales;

END TRY
BEGIN CATCH

	IF @@TRANCOUNT > 0
	BEGIN
		ROLLBACK TRAN
	END

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