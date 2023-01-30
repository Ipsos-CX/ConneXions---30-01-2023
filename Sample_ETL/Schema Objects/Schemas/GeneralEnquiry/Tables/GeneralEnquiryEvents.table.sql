CREATE TABLE [GeneralEnquiry].[GeneralEnquiryEvents]
(
	[GeneralEnquiryID]				[int] IDENTITY(1,1) NOT NULL,

	[AuditID]						[dbo].[AuditID] NOT NULL,
	[AuditItemID]					[dbo].[AuditItemID] NULL,
	[PhysicalRowID]					[int] NOT NULL,

	[ODSEventID]					dbo.EventID NULL,
	[DateTransferredToVWT]			[datetime2](7) NULL,

	CRCCentreCode					dbo.Loadtext NULL,
	MarketCode						dbo.Loadtext NULL,
	BrandCode						dbo.Loadtext NULL,
	GeneralEnquiryDateOrig			dbo.Loadtext NULL,
	UniqueCustomerID				dbo.Loadtext NULL,
	VehicleRegNumber				dbo.Loadtext NULL,
	VIN								dbo.Loadtext NULL,
	VehicleModel					dbo.Loadtext NULL,
	CustomerTitle					dbo.Loadtext NULL,
	CustomerInitial					dbo.Loadtext NULL,
	CustomerFirstName				dbo.Loadtext NULL,
	CustomerLastName				dbo.Loadtext NULL,
	AddressLine1					dbo.Loadtext NULL,
	AddressLine2					dbo.Loadtext NULL,
	AddressLine3					dbo.Loadtext NULL,
	AddressLine4					dbo.Loadtext NULL,
	City							dbo.Loadtext NULL,
	County							dbo.Loadtext NULL,
	Country							dbo.Loadtext NULL,
	PostalCode						dbo.Loadtext NULL,
	PhoneMobile						dbo.Loadtext NULL,
	PhoneHome						dbo.Loadtext NULL,
	EmailAddress					dbo.Loadtext NULL,
	CompanyName						dbo.Loadtext NULL,
	RowID							dbo.Loadtext NULL,
	CommunicationType				dbo.Loadtext NULL,
	EmployeeResponsibleName			dbo.Loadtext NULL,
	GeneralEnquiryDate				[datetime2](7) NULL,
	CaseNumber						dbo.Loadtext NULL,
	PreferredLanguageID				int	NULL,
	SampleTriggeredSelectionReqID	int	NULL,
	COMPLETE_SUPPRESSION			dbo.Loadtext NULL,
	SUPPRESSION_EMAIL				dbo.Loadtext NULL,
	SUPPRESSION_PHONE				dbo.Loadtext NULL,
	SUPPRESSION_MAIL				dbo.Loadtext NULL,
	[RunDateofExtract]				[dbo].[LoadText] NULL,		--ET BUG 18240 Global CRC Cases			
	[ExtractFromDate]				[dbo].[LoadText] NULL,		--ET BUG 18240 Global CRC Cases
	[ExtractToDate]					[dbo].[LoadText] NULL,		--ET BUG 18240 Global CRC Cases
	[ContactId]						[dbo].[LoadText] NULL,		--ET BUG 18240 Global CRC Cases
	[AssetId]						[dbo].[LoadText] NULL,		--ET BUG 18240 Global CRC Cases
	[VehicleDerivative]				[dbo].[LoadText] NULL,		--ET BUG 18240 Global CRC Cases
	[VehicleMileage]				[dbo].[LoadText] NULL,		--ET BUG 18240 Global CRC Cases
	[VehicleMonthsinService]		[dbo].[LoadText] NULL,		--ET BUG 18240 Global CRC Cases
	[SRCreatedDate]					[dbo].[LoadText] NULL,		--ET BUG 18240 Global CRC Cases
	[Owner]							[dbo].[LoadText] NULL,		--ET BUG 18240 Global CRC Cases
	[ClosedBy]						[dbo].[LoadText] NULL,		--ET BUG 18240 Global CRC Cases
	[Type]							[dbo].[LoadText] NULL,		--ET BUG 18240 Global CRC Cases
	[PrimaryReasonCode]				[dbo].[LoadText] NULL,		--ET BUG 18240 Global CRC Cases
	[SecondaryReasonCode]			[dbo].[LoadText] NULL,		--ET BUG 18240 Global CRC Cases
	[ConcernAreaCode]				[dbo].[LoadText] NULL,		--ET BUG 18240 Global CRC Cases
	[SymptomCode]					[dbo].[LoadText] NULL,		--ET BUG 18240 Global CRC Cases
	[NoOfSelectedContacts]			[dbo].[LoadText] NULL,		--ET BUG 18240 Global CRC Cases
	[Rule1]							[dbo].[LoadText] NULL,		--ET BUG 18240 Global CRC Cases
	[Rule2]							[dbo].[LoadText] NULL,		--ET BUG 18240 Global CRC Cases
	[C05]							[dbo].[LoadText] NULL,		--ET BUG 18240 Global CRC Cases
	[C07]							[dbo].[LoadText] NULL,		--ET BUG 18240 Global CRC Cases
	[C15]							[dbo].[LoadText] NULL,		--ET BUG 18240 Global CRC Cases
	[T06]							[dbo].[LoadText] NULL,		--ET BUG 18240 Global CRC Cases
	[T08]							[dbo].[LoadText] NULL,		--ET BUG 18240 Global CRC Cases
	[T13]							[dbo].[LoadText] NULL,		--ET BUG 18240 Global CRC Cases
	[Rule5]							[dbo].[LoadText] NULL,		--ET BUG 18240 Global CRC Cases
	[Rule6]							[dbo].[LoadText] NULL,		--ET BUG 18240 Global CRC Cases
	[Rule7a]						[dbo].[LoadText] NULL,		--ET BUG 18240 Global CRC Cases
	[Rule7b]						[dbo].[LoadText] NULL,		--ET BUG 18240 Global CRC Cases
	[Rule8]							[dbo].[LoadText] NULL,		--ET BUG 18240 Global CRC Cases
	[ConvertedSRCreatedDate]		[datetime2](7) NULL			--ET BUG 18240 Global CRC Cases
)
