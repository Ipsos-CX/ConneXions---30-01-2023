CREATE TABLE [SampleReport].[IndividualRowsEvents](
	[SuperNationalRegion] [nvarchar](250) NULL,
	[BusinessRegion]  [nvarchar](250) NULL,
	[DealerMarket] [nvarchar](255) NULL,
	[SubNationalRegion] [nvarchar](255) NULL,
	[CombinedDealer] [nvarchar](255) NULL,
	[DealerName] [nvarchar](150) NULL,
	[DealerCode] [nvarchar](20) NULL,
	[DealerCodeGDD] [nvarchar](20) NULL,
	[FullName] [nvarchar](500) NULL,
	[OrganisationName] [nvarchar](510) NULL,
	[AnonymityDealer] [int] NULL,
	[AnonymityManufacturer] [int] NULL,
	[CaseCreationDate] [datetime2](7) NULL,
	[CaseStatusType] [varchar](100) NULL,
	[CaseOutputType] [varchar](100) NULL,
	[SentFlag] [int] NULL,
	[SentDate] [datetime2](7) NULL,
	[RespondedFlag] [int] NULL,
	[ClosureDate] [datetime2](7) NULL,
	[DuplicateRowFlag] [int] NULL,
	[BouncebackFlag] [int] NULL,
	[UsableFlag] [int] NULL,
	[ManualRejectionFlag] [int] NULL,
	[FileName] [varchar](100) NULL,
	[FileActionDate] datetime	NULL,
	[FileRowCount] [int] NULL,
	[LoadedDate] [datetime2](7) NOT NULL,
	[AuditID] [bigint] NOT NULL,
	[AuditItemID] [bigint] NOT NULL,
	[MatchedODSPartyID] [bigint] NOT NULL,
	[MatchedODSPersonID] [bigint] NOT NULL,
	[LanguageID] [bigint] NOT NULL,
	[PartySuppression] [bigint] NOT NULL,
	[MatchedODSOrganisationID] [bigint] NOT NULL,
	[MatchedODSAddressID] [bigint] NOT NULL,
	[CountryID] [bigint] NULL,
	[PostalSuppression] [int] NOT NULL,
	[EmailSuppression] [int] NOT NULL,
	[MatchedODSVehicleID] [bigint] NOT NULL,
	[ODSRegistrationID] [bigint] NULL,
	[MatchedODSModelID] [int] NULL,
	[OwnershipCycle] [int] NULL,
	[MatchedODSEventID] [bigint] NOT NULL,
	[ODSEventTypeID] [int] NULL,
	[WarrantyID] [bigint] NULL,
	[Brand] [nvarchar](510) NULL,
	[Market] [varchar](200) NULL,
	[Questionnaire] [varchar](255) NULL,
	[QuestionnaireRequirementID] [int] NULL,
	[SuppliedName] [int] NOT NULL,
	[SuppliedAddress] [int] NOT NULL,
	[SuppliedPhoneNumber] [int] NOT NULL,
	[SuppliedMobilePhone] [int] NOT NULL,	
	[SuppliedEmail] [int] NOT NULL,
	[SuppliedVehicle] [int] NOT NULL,
	[SuppliedRegistration] [int] NOT NULL,
	[SuppliedEventDate] [int] NOT NULL,
	[EventDateOutOfDate] [int] NOT NULL,
	[EventNonSolicitation] [int] NOT NULL,
	[PartyNonSolicitation] [int] NOT NULL,
	[UnmatchedModel] [int] NOT NULL,
	[UncodedDealer] [int] NOT NULL,
	[EventAlreadySelected] [int] NOT NULL,
	[NonLatestEvent] [int] NOT NULL,
	[InvalidOwnershipCycle] [int] NOT NULL,
	[RecontactPeriod] [int] NOT NULL,
	[RelativeRecontactPeriod] [int] NULL,
	[InvalidVehicleRole] [int] NOT NULL,
	[CrossBorderAddress] [int] NOT NULL,
	[CrossBorderDealer] [int] NOT NULL,
	[ExclusionListMatch] [int] NOT NULL,
	[InvalidEmailAddress] [int] NOT NULL,
	[BarredEmailAddress] [int] NOT NULL,
	[BarredDomain] [int] NOT NULL,
	[OtherReasonForNonSelection] [int] NULL,
	[CaseID] [int] NULL,
	[SampleRowProcessed] [int] NULL,
	[SampleRowProcessedDate] [datetime2](7) NULL,
	[WrongEventType] [int] NOT NULL,
	[MissingStreet] [int] NOT NULL,
	[MissingPostcode] [int] NOT NULL,
	[MissingEmail] [int] NOT NULL,
	[MissingTelephone] [int] NOT NULL,
	[MissingStreetAndEmail] [int] NOT NULL,
	[MissingTelephoneAndEmail] [int] NOT NULL,
	[MissingMobilePhone] [int] NOT NULL,
	[MissingMobilePhoneAndEmail] [int] NOT NULL,
	[MissingPartyName] [int] NOT NULL,
	[MissingLanguage] [int] NOT NULL,
	[InvalidModel] [int] NOT NULL,	
	[InvalidManufacturer] [int] NOT NULL,
	[InternalDealer] [int] NOT NULL,	
	[RegistrationNumber] [nvarchar](100) NULL,
	[RegistrationDate] [datetime2](7) NULL,
	[VIN] [nvarchar](50) NULL,
	[OutputFileModelDescription] [varchar](50) NULL, --BUG 18289
	[EventDate] [datetime2](7) NULL,
	[SampleEmailAddress] dbo.EmailAddress NULL,
	[CaseEmailAddress] dbo.EmailAddress NULL,
	[PreviousEventBounceBack]	[int] NOT NULL,
	[EventDateTooYoung] [int] NOT NULL,
	[AFRLCode] [nvarchar](50) NULL,
	[DealerExclusionListMatch] [int] NOT NULL,
	[PhoneSuppression] [int] NOT NULL,
	[SalesType] [nvarchar](50) NULL,
	[InvalidAFRLCode] [int] NOT NULL,
	[InvalidSalesType] [int] NOT NULL,
	[AgentCodeFlag] [int] NULL,
	[DataSource] [nvarchar](50) NULL,
	[HardBounce] [int] NULL,
	[SoftBounce] [int] NULL,
	[Unsubscribes] [int] NULL,
	[DateOfLeadCreation]  NVARCHAR(50) NULL,				-- BUG 13344
	[PrevSoftBounce]         [int] NULL,
    [PrevHardBounce]         [int] NULL,
    [ServiceTechnicianID]	  nvarchar(400) NULL,				
	[ServiceTechnicianName]	  nvarchar(400) NULL,				
	[ServiceAdvisorName]	  nvarchar(400)	NULL,	
	[ServiceAdvisorID] nvarchar(400)	NULL,					 
	[CRMSalesmanName] nvarchar(400) NULL,		
	[CRMSalesmanCode]     nvarchar(400) NULL,
	[SubNationalTerritory] [nvarchar](255) NULL,
	[FOBCode]	int NULL,
	[ContactPreferencesSuppression]		INT							NULL,
    [ContactPreferencesPartySuppress]	INT							NULL,
	[ContactPreferencesEmailSuppress]	INT							NULL,
	[ContactPreferencesPhoneSuppress]	INT							NULL,
	[ContactPreferencesPostalSuppress]	INT							NULL,
	[SVCRMSalesType]         nvarchar(40) NULL,         
    [SVCRMInvalidSalesType]  int NULL,
    [DealNumber]		 nvarchar(200) NULL,
    [RepairOrderNumber]	 nvarchar(200) NULL,
    [VistaCommonOrderNumber] nvarchar(35) NULL,
    [SalesEmployeeCode]      nvarchar(400) NULL,
    [SalesEmployeeName]      nvarchar(400) NULL,
	[ServiceEmployeeCode]    nvarchar(400) NULL,
	[ServiceEmployeeName]    nvarchar(400) NULL,
	[RecordChanged] int NULL,
	[PDIFlagSet]		int NULL,						-- 07-09-2017 - BUG 14122
		
	[OriginalPartySuppression] INT NULL,						 -- BUG 14379
	[OriginalPostalSuppression] INT NULL,						 -- BUG 14379	
	[OriginalEmailSuppression] INT NULL,						 -- BUG 14379	
	[OriginalPhoneSuppression] INT NULL,							 -- BUG 14379
	[OtherExclusion] INT NULL,									-- BUG 14487 
	[OverrideFlag] INT NULL,									-- BUG 14486
	[GDPRflag] INT NULL,										-- BUG 14669
	[SelectionPostalID] INT NULL,		 -- BUG 15017
	[SelectionEmailID] INT NULL,		 -- BUG 15017
	[SelectionPhoneID] INT NULL,		 -- BUG 15017
	[SelectionLandlineID] INT NULL,		 -- BUG 15017
	[SelectionMobileID] INT NULL,		 -- BUG 15017
	[SelectionEmail] nvarchar(510) NULL, -- BUG 15017
	[SelectionPhone] nvarchar(70) NULL,		 -- BUG 15017
	[SelectionLandline] nvarchar(70) NULL,	 -- BUG 15017
	[SelectionMobile] nvarchar(70) NULL,	 -- BUG 15017
	[ContactPreferencesModel] varchar(50) NULL, -- BUG 15125
	[ContactPreferencesPersist] INT NULL, -- BUG 15125
	[InvalidDateOfLastContact] INT NULL,  -- BUG 15126
	[MatchedODSPrivEmailAddressID] INT NULL,   -- BUG 15211
	[SamplePrivEmailAddress] dbo.EmailAddress NULL, -- BUG 15211
	[EmailExcludeBarred] INT NULL, --BUG 16864
	[EmailExcludeGeneric] INT NULL, --BUG 16864
	[CompanyExcludeBodyShop] INT NULL, --BUG 16864
	[CompanyExcludeLeasing] INT NULL, --BUG 16864
	[CompanyExcludeFleet] INT NULL, --BUG 16864
	[CompanyExcludeBarredCo] INT NULL, --BUG 16864
	[EmailExcludeInvalid] INT NULL, --BUG 16864
	[OutletPartyID] [int] NULL, -- BUG 18093
	[Dealer10DigitCode] [nvarchar](10) NULL, -- BUG 18093
	[OutletFunction] [nvarchar](25) NULL, -- BUG 18093
	[RoadsideAssistanceProvider] [nvarchar](4000) NULL, -- BUG 18093
	[CRC_Owner] [nvarchar](4000) NULL, -- BUG 18093
	[ClosedBy] [nvarchar](4000) NULL, -- BUG 18093
	[Owner] [nvarchar](4000) NULL, -- BUG 18093
	[CountryIsoAlpha2] [char](2) NULL, -- BUG 18093
	[CRCMarketCode] [nvarchar](4000) NULL, -- BUG 18093
	[InvalidDealerBrand] INT NULL, -- TASK 474
	[SubBrand] VARCHAR(50) NULL, -- TASK 1017 : HOB
	[ModelCode]			INT NULL, -- TASK 926
	[LeadVehSaleType]	NVARCHAR(20) NULL, -- TASK 1064
	[ModelVariant]		NVARCHAR(50) NULL -- TASK 1064
) ;

