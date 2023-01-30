CREATE VIEW Event.vwDA_AdditionalInfoSales

AS

SELECT
	CONVERT(BIGINT, 0) AS AuditItemID,
	EventID,
    SalesOrderNumber,
	SalesCustomerType,
	SalesPaymentType,
	Salesman,
	ContractRelationship,
	ContractCustomer,
	SalesmanCode,
	InvoiceNumber,
	InvoiceValue,
	PrivateOwner,
	OwningCompany,
	UserChooserDriver,
	EmployerCompany,
	AdditionalCountry,
	State,
	VehiclePurchaseDate,
	VehicleDeliveryDate,
	TypeOfSaleOrig,
	Approved,
	LostLead_DateOfLeadCreation AS LostLead_DateOfLeadCreationOrig,
	LostLead_DateOfLeadCreation,
	ServiceAdvisorID,		
	ServiceAdvisorName,	
	TechnicianID,			
	TechnicianName,		
	VehicleSalePrice,
	SalesAdvisorID,		
	SalesAdvisorName,	
	PDI_flag,
	ParentAuditItemID,
	LostLead_MarketingPermission,
	LostLead_CompleteSuppressionJLR,
	LostLead_CompleteSuppressionRetailer,
	LostLead_PermissionToEmailJLR,
	LostLead_PermissionToEmailRetailer,
	LostLead_PermissionToPhoneJLR,
	LostLead_PermissionToPhoneRetailer,
	LostLead_PermissionToPostJLR,
	LostLead_PermissionToPostRetailer,
	LostLead_PermissionToSMSJLR,
	LostLead_PermissionToSMSRetailer,
	LostLead_PermissionToSocialMediaJLR,
	LostLead_PermissionToSocialMediaRetailer,
	LostLead_DateOfLastContact,
	LostLead_ConvertedDateOfLastContact,
	JLRSuppliedEventType,
	IAssistanceHelpdeskAdvisorName,			-- BUG 15056 - 2018-10-23
	IAssistanceHelpdeskAdvisorID,				-- BUG 15056 - 2018-10-23
	RONumber,									-- BUG 16850 - 2020-01-13
	LandRoverExperienceID,                     -- TASK 879 - 07/06/2022
	CommonSaleType,                            -- TASK 899 - 22/06/2022
	TypeOfSaleID                               -- TASK 899 - 22/06/2022
FROM Event.AdditionalInfoSales

