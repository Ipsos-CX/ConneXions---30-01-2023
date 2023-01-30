CREATE TABLE [Audit].[AdditionalInfoSales] (
    [AuditItemID]				dbo.AuditItemID   NOT NULL
    , [EventID]					dbo.EventID			NOT NULL
    , [SalesOrderNumber]		dbo.AddressText		NULL
	, [SalesCustomerType]		dbo.AddressText		NULL
	, [SalesPaymentType]		dbo.AddressText		NULL
	, [Salesman]				dbo.AddressText		NULL
	, [ContractRelationship]	dbo.AddressText		NULL
	, [ContractCustomer]		dbo.AddressText		NULL
	, [SalesmanCode] 			dbo.AddressText		NULL
	, [InvoiceNumber]			dbo.AddressText		NULL
	, [InvoiceValue]			dbo.AddressText		NULL
	, [PrivateOwner]			dbo.AddressText		NULL
	, [OwningCompany]			dbo.AddressText		NULL
	, [UserChooserDriver]		dbo.AddressText		NULL
	, [EmployerCompany]			dbo.AddressText		NULL
	, [AdditionalCountry]		dbo.AddressText		NULL
	, [State]					dbo.AddressText		NULL
	, [VehiclePurchaseDate]     dbo.AddressText     NULL
	, [VehicleDeliveryDate]		dbo.AddressText		NULL
	, [TypeOfSaleOrig]			dbo.AddressText		NULL
	, [Approved]				dbo.Approved		NULL
	, LostLead_DateOfLeadCreation   dbo.AddressText		NULL
	, [ServiceAdvisorID]		dbo.AddressText		NULL
	, [ServiceAdvisorName]		dbo.AddressText		NULL
	, [TechnicianID]			dbo.AddressText		NULL
	, [TechnicianName]			dbo.AddressText		NULL
	, [VehicleSalePrice]		dbo.AddressText		NULL
	, [SalesAdvisorID]			dbo.AddressText		NULL
	, [SalesAdvisorName]		dbo.AddressText		NULL
	, [PDI_Flag]				VARCHAR(1)			NULL
	, ParentAuditItemID			dbo.AuditItemID		NULL
	, LostLead_CompleteSuppressionJLR		dbo.AddressText		NULL
	, LostLead_CompleteSuppressionRetailer	dbo.AddressText		NULL
	, LostLead_PermissionToEmailJLR			dbo.AddressText		NULL
	, LostLead_PermissionToEmailRetailer	dbo.AddressText		NULL
	, LostLead_PermissionToPhoneJLR			dbo.AddressText		NULL
	, LostLead_PermissionToPhoneRetailer	dbo.AddressText		NULL
	, LostLead_PermissionToPostJLR			dbo.AddressText		NULL
	, LostLead_PermissionToPostRetailer		dbo.AddressText		NULL
	, LostLead_PermissionToSMSJLR			dbo.AddressText		NULL
	, LostLead_PermissionToSMSRetailer		dbo.AddressText		NULL
	, LostLead_PermissionToSocialMediaJLR	dbo.AddressText		NULL
	, LostLead_PermissionToSocialMediaRetailer dbo.AddressText	NULL
	, LostLead_DateOfLastContact			dbo.AddressText		NULL
	, LostLead_ConvertedDateOfLastContact	datetime2			NULL
	, LostLead_MarketingPermission			dbo.AddressText		NULL
	, JLRSuppliedEventType					dbo.EventID			NULL
	, IAssistanceHelpdeskAdvisorName		dbo.AddressText		NULL	-- BUG 15056 - 2018-10-23
	, IAssistanceHelpdeskAdvisorID			dbo.AddressText		NULL	-- BUG 15056 - 2018-10-23
    , [RONumber] VARCHAR(100) NULL
	, LandRoverExperienceID VARCHAR (20) NULL -- TASK 879
	, [CommonSaleType]						dbo.AddressText		NULL --TASK 899
	, [TypeOfSaleID]						dbo.AddressText		NULL --TASK 899
	)

