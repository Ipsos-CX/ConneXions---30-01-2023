CREATE VIEW Load.vwAdditionalInfoSales

AS

-- GET ADDITIONAL SALES INFO SUPPLIED IN VISTA FILES THAT WE DON'T MODEL

	SELECT 
		V.AuditItemID
		, V.MatchedODSEventID AS EventID
		, V.SalesOrderNumber
		, V.SalesCustomerType
		, V.SalesPaymentType
		, V.Salesman
		, V.ContractRelationship
		, V.ContractCustomer
		, V.SalesmanCode
		, V.InvoiceNumber
        , V.InvoiceValue
        , V.PrivateOwner
        , V.OwningCompany
        , V.UserChooserDriver
        , V.EmployerCompany
        , V.AdditionalCountry
        , V.State
        , V.VehiclePurchaseDate
		, V.VehicleDeliveryDate
		, V.TypeOfSaleOrig
		, V.Approved
		, V.LostLead_DateOfLeadCreationOrig
		, V.LostLead_DateOfLeadCreation
		, V.ServiceAdvisorID		
		, V.ServiceAdvisorName		
		, V.TechnicianID		
		, V.TechnicianName		
		, V.VehicleSalePrice	
		, V.SalesAdvisorID		
		, V.SalesAdvisorName		
		, V.PDI_Flag								-- BUG 14122 - 31/08/2017
		, V.EventParentAuditItemID				-- BUG 14413 - 20/03/2018
		, V.LostLead_MarketingPermission			-- BUG 14820 - 01/08/2018
		, V.LostLead_CompleteSuppressionJLR		-- BUG 14820 - 01/08/2018
		, V.LostLead_CompleteSuppressionRetailer	-- BUG 14820 - 01/08/2018
		, V.LostLead_PermissionToEmailJLR			-- BUG 14820 - 01/08/2018
		, V.LostLead_PermissionToEmailRetailer	-- BUG 14820 - 01/08/2018
		, V.LostLead_PermissionToPhoneJLR			-- BUG 14820 - 01/08/2018
		, V.LostLead_PermissionToPhoneRetailer	-- BUG 14820 - 01/08/2018
		, V.LostLead_PermissionToPostJLR			-- BUG 14820 - 01/08/2018
		, V.LostLead_PermissionToPostRetailer		-- BUG 14820 - 01/08/2018
		, V.LostLead_PermissionToSMSJLR			-- BUG 14820 - 01/08/2018
		, V.LostLead_PermissionToSMSRetailer		-- BUG 14820 - 01/08/2018
		, V.LostLead_PermissionToSocialMediaJLR	-- BUG 14820 - 01/08/2018
		, V.LostLead_PermissionToSocialMediaRetailer -- BUG 14820 - 01/08/2018
		, V.LostLead_DateOfLastContact			-- BUG 14820 - 01/08/2018
		, V.LostLead_ConvertedDateOfLastContact	-- BUG 14820 - 01/08/2018
		, V.JLRSuppliedEventType					-- BUG 14820 - 01/08/2018
		, IE.IAssistanceHelpdeskAdvisorName			-- BUG 15056 - 23/10/2018
		, IE.IAssistanceHelpdeskAdvisorID			-- BUG 15056 - 23/10/2018
		, RONumber									-- BUG 16850 - 13/01/2020
		, LandRoverExperienceID                     -- TASK 879 - 07/06/2022
		, CommonSaleType                            -- TASK 899 - 22/06/2022
		, TypeOfSaleID                              -- TASK 899 - 22/06/2022
	FROM dbo.VWT V
	LEFT JOIN IAssistance.IAssistanceEvents IE ON V.AuditItemID = IE.AuditItemID	-- BUG 15056 - 23/10/2018
	WHERE ISNULL(V.MatchedODSEventID,0) <> 0		-- Fix to avoid overnight load falling over