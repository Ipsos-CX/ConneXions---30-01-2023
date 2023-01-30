CREATE TABLE [Audit].[SelectionOutput] (
    [AuditID]               dbo.AuditID         NOT NULL,
    [AuditItemID]           dbo.AuditItemID         NOT NULL,
    [SelectionOutputTypeID] dbo.SelectionOutputTypeID           NOT NULL,
    [CaseID]                dbo.CaseID         NULL,
    [PartyID]               dbo.PartyID         NULL,
    [FullModel]        VARCHAR(50)			      NULL,
    [Model]            VARCHAR(50)			      NULL,
    [sType]            [dbo].[OrganisationName]   NULL,
    [CarReg]           [dbo].[RegistrationNumber] NULL,
    [RegistrationDate] DATETIME2 NULL,
    [VIN]				dbo.VIN NULL,
    [Title]            [dbo].[Title]              NULL,
    [Initial]          [dbo].[NameDetail]         NULL,
    [Surname]          [dbo].[NameDetail]         NULL,
    [Fullname]         [dbo].[AddressingText]     NULL,
    [DearName]         [dbo].[AddressingText]     NULL,
    [CoName]           [dbo].[OrganisationName]   NULL,
    [Add1]             [dbo].[AddressText]        NULL,
    [Add2]             [dbo].[AddressText]        NULL,
    [Add3]             [dbo].[AddressText]        NULL,
    [Add4]             [dbo].[AddressText]        NULL,
    [Add5]             [dbo].[AddressText]        NULL,
    [Add6]             [dbo].[AddressText]        NULL,
    [Add7]             [dbo].[AddressText]        NULL,
    [Add8]             [dbo].[Postcode]           NULL,
    [Add9]             [dbo].[AddressText]        NULL,
    [CTRY]             [dbo].[Country]            NULL,
    [EmailAddress]     [dbo].[EmailAddress]       NULL,
    [Dealer]           [dbo].[DealerName]         NULL,
    [sno]              [dbo].[VersionCode]        NULL,
    [ccode]            [dbo].[CountryID]          NULL,
    [modelcode]        BIGINT				      NULL,
    [lang]             [dbo].[LanguageID]         NULL,
    [manuf]            [dbo].[PartyID]            NULL,
    [gender]           [dbo].[GenderID]           NULL,
    [qver]             [dbo].[QuestionnaireVersion] NULL,
    [blank]            VARCHAR (150)                NULL,
    [etype]            [dbo].[EventTypeID]        NULL,
    [reminder]         INT                        NULL,
    [week]             INT                        NULL,
    [test]             INT                        NULL,
    [SampleFlag]       INT                        NULL,
	[SalesServiceFile] VARCHAR (1)                NULL,
    [LandPhone]            dbo.ContactNumber NULL,
    [WorkPhone]             dbo.ContactNumber NULL,
    [MobilePhone]           dbo.ContactNumber NULL,
    [DateOutput]	DATETIME2 NULL,
    [Expired]               DATETIME2 (7)                 NULL,
    [EmployeeCode]		[dbo].[NameDetail]         NULL,
    [EmployeeName]		[dbo].[NameDetail]         NULL,
    [URL]				VARCHAR(150)			   NULL,
    ITYPE				VARCHAR(5)					NULL,
    PilotCode			VARCHAR(10)					NULL,
    Queue					VARCHAR(10)						 NULL,
	AssignedMode			VARCHAR(10)						 NULL, 
	RequiresManualDial		VARCHAR(1)						 NULL, 
	CallRecordingsCount		VARCHAR(1)						 NULL, 
	TimeZone				INT								 NULL, 
	CallOutcome				VARCHAR(10)						 NULL,
	PhoneNumber				[dbo].[ContactNumber]			NULL,	 
	PhoneSource				VARCHAR(50)						 NULL, 
	[Language]				VARCHAR(10)						 NULL,
	ExpirationTime			DATETIME2 (7)					 NULL,  
	HomePhoneNumber			[dbo].[ContactNumber]			 NULL,
	WorkPhoneNumber			[dbo].[ContactNumber]			 NULL,
	MobilePhoneNumber		[dbo].[ContactNumber]			 NULL,
	Owner					[dbo].[NameDetail]				NULL,
	OwnerCode				[dbo].[NameDetail]				NULL,
	CRCCode					[dbo].[NameDetail]				NULL,
	MarketCode				[dbo].[NameDetail]				NULL,
	SampleYear				INT								NULL,
	VehicleMileage			VARCHAR(50)						 NULL,
	VehicleMonthsinService  VARCHAR(50)						 NULL,
	RowId					VARCHAR(50)						 NULL,
	SRNumber				VARCHAR(50)						 NULL,
	AdhocRequirementID		[dbo].[RequirementID]			NULL,
	ModelSummary			VARCHAR(50)			            NULL,
	IntervalPeriod			VARCHAR(10)						NULL,
	VistaContractOrderNumber	NVARCHAR(35)				NULL,
	DealNo						NVARCHAR(35)				NULL,
	RepairOrderNumber			NVARCHAR(35)				NULL,
	FOBCode						INT							NULL,
	UnknownLang					INT							NULL,
	SVOvehicle					VARCHAR(200)				NULL,
	BilingualFlag				BIT							NULL,
	DearNameBilingual			[dbo].[AddressingText]		NULL,
	langBilingual				[dbo].[LanguageID]			NULL,
	EmailSignatorTitleBilingual		NVARCHAR(500)			NULL,
	EmailContactTextBilingual		NVARCHAR(2000)			NULL,
	EmailCompanyDetailsBilingual	NVARCHAR(2000)			NULL,
	Brand							dbo.OrganisationName	NULL,
	CATIType						INT						NULL,
	CustomerIdentifier				dbo.CustomerIdentifier	NULL,
	EventDate						VARCHAR(8000)			NULL,
	FileDate						VARCHAR(30)				NULL,
	GDDDealerCode					NVARCHAR(20)			NULL,
	ManufacturerDealerCode			VARCHAR(210)			NULL,
	Market							dbo.Country				NULL,
	ModelVariant					VARCHAR(50)				NULL,
	ModelYear						INT						NULL,
	OutletPartyID					dbo.PartyID				NULL,
	OwnershipCycle					dbo.OwnershipCycle		NULL,
	Password						VARCHAR(20)				NULL,
	Questionnaire					dbo.Requirement			NULL,
	ReportingDealerPartyID			INT						NULL,
	Telephone						dbo.ContactNumber		NULL,
	VariantID						SMALLINT				NULL,
	CampaignID				NVARCHAR(100)					NULL,	-- 2018-06-12
	DealerCode				dbo.DealerCode					NULL,	-- 2018-06-12
    EmailSignator			NVARCHAR(500)					NULL,	-- 2018-06-12
    EmailSignatorTitle		NVARCHAR(500)					NULL,	-- 2018-06-12
    EmailContactText		NVARCHAR(2000)					NULL,	-- 2018-06-12
    EmailCompanyDetails		NVARCHAR(2000)					NULL,	-- 2018-06-12
	JLRCompanyname			NVARCHAR(2000)					NULL,	-- 2018-06-12
	RockarDealer			INT								NULL,	-- 2018-06-12
	SVODealer				INT								NULL,	-- 2018-06-12
	WorkTel					dbo.ContactNumber				NULL,	-- 2018-06-12
	SelectionDate			DATETIME2 (7)					NULL,	-- 2018-06-12
	PreferredLanguageID		INT								NULL,	-- 2018-06-12
	ClosedBy				NVARCHAR(500)					NULL,	-- 2018-06-12
	BrandCode				NVARCHAR(500)					NULL,	-- 2018-06-12
	CRCsurveyfile			VARCHAR(1)						NULL,	-- 2018-06-12
	NSCFlag					VARCHAR(1)						NULL,	-- 2018-06-12
	Approved					dbo.Approved				NULL,	-- 2018-06-12
	BreakdownAttendingResource	NVARCHAR(500)				NULL,	-- 2018-06-12
	BreakdownCaseId				NVARCHAR(500)				NULL,	-- 2018-06-12
	BreakdownCountry			[dbo].[Country]				NULL,	-- 2018-06-12
	BreakdownCountryID			INT							NULL,	-- 2018-06-12
	BreakdownDate				DATETIME2 (7)				NULL,	-- 2018-06-12
	CarHireProvider				NVARCHAR(500)				NULL,	-- 2018-06-12
	CarHireStartDate			DATETIME2 (7)				NULL,	-- 2018-06-12
	CarHireStartTime			DATETIME2 (7)				NULL,	-- 2018-06-12
	CarHireTicketNumber			NVARCHAR(500)				NULL,	-- 2018-06-12
	ConvertedCarHireStartTime	DATETIME2 (7)				NULL,	-- 2018-06-12
	DataSource					NVARCHAR(500)				NULL,	-- 2018-06-12
	HireGroupBranch				NVARCHAR(500)				NULL,	-- 2018-06-12
	HireJobNumber				NVARCHAR(500)				NULL,	-- 2018-06-12
	ReasonForHire				NVARCHAR(500)				NULL,	-- 2018-06-12
	RepairingDealer				NVARCHAR(500)				NULL,	-- 2018-06-12
	RepairingDealerCountry		NVARCHAR(500)				NULL,	-- 2018-06-12
	ReplacementVehicleMake		NVARCHAR(500)				NULL,	-- 2018-06-12
	ReplacementVehicleModel		NVARCHAR(500)				NULL,	-- 2018-06-12
	RoadsideAssistanceProvider	NVARCHAR(500)				NULL,	-- 2018-06-12
	VehicleOriginCountry		NVARCHAR(500)				NULL,	-- 2018-06-12
	CRMSalesmanName				NVARCHAR(500)				NULL,	-- 2018-06-12
	CRMSalesmanCode				NVARCHAR(500)				NULL,	-- 2018-06-12
	ServiceTechnicianID			NVARCHAR(500)				NULL,	-- 2018-06-12
	ServiceTechnicianName		NVARCHAR(500)				NULL,	-- 2018-06-12
	ServiceAdvisorName			NVARCHAR(500)				NULL,	-- 2018-06-12
	ServiceAdvisorID			NVARCHAR(500)				NULL,	-- 2018-06-12
	JLREventType				VARCHAR(50)					NULL,	-- 2018-09-26
	Agency						NVARCHAR(200)				NULL,	-- 2018-06-29						
	IAssistanceProvider			NVARCHAR(500)				NULL,	-- 2018-11-02
	IAssistanceCallID					NVARCHAR(500)		NULL,	-- 2018-11-02
	IAssistanceCallStartDate			NVARCHAR(500)		NULL,	-- 2018-11-02
	IAssistanceCallCloseDate			NVARCHAR(500)		NULL,	-- 2018-11-02
	IAssistanceHelpdeskAdvisorName		NVARCHAR(500)		NULL,	-- 2018-11-02
	IAssistanceHelpdeskAdvisorID		NVARCHAR(500)		NULL,	-- 2018-11-02
	IAssistanceCallMethod				NVARCHAR(500)		NULL,	-- 2018-11-02
	JLRPrivacyPolicy					NVARCHAR(500)		NULL,	-- 2018-11-02
	JLRPrivacyPolicyBilingual			NVARCHAR(500)		NULL,	-- 2018-11-02
	LostLead_DateOfLeadCreation					VARCHAR(50)					NULL,
	LostLead_CompleteSuppressionJLR				VARCHAR(50)					NULL,
	LostLead_CompleteSuppressionRetailer		VARCHAR(50)					NULL,
	LostLead_PermissionToEmailJLR				VARCHAR(50)					NULL,
	LostLead_PermissionToEmailRetailer			VARCHAR(50)					NULL,	
	LostLead_PermissionToPhoneJLR				VARCHAR(50)					NULL,			
	LostLead_PermissionToPhoneRetailer			VARCHAR(50)					NULL,
	LostLead_PermissionToPostJLR				VARCHAR(50)					NULL,
	LostLead_PermissionToPostRetailer			VARCHAR(50)					NULL,
	LostLead_PermissionToSMSJLR					VARCHAR(50)					NULL,
	LostLead_PermissionToSMSRetailer			VARCHAR(50)					NULL,
	LostLead_PermissionToSocialMediaJLR			VARCHAR(50)					NULL,
	LostLead_PermissionToSocialMediaRetailer	VARCHAR(50)					NULL,
	LostLead_DateOfLastContact					VARCHAR(50)					NULL,

	HotTopicCodes								VARCHAR(100)				NULL,		-- BUG 15079 - 21/11/2018
    DealerType									VARCHAR(50)					NULL,		-- Bug 15490 - 28/10/2019
-- Bug 16850 - 21/01/2020
	ServiceEventType							INT							NULL,		-- Bug 16891 - 28/01/2020
	EventID										BIGINT						NULL,		-- Task 535
	CDSID										NVARCHAR(100)				NULL,		-- Task 553
	EngineType									INT							NULL);		-- Task 558