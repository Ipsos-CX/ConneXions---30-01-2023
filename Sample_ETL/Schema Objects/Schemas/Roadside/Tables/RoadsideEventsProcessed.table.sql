CREATE TABLE [Roadside].[RoadsideEventsProcessed] (
	[RoadsideID] [int] NOT NULL,

	[AuditID] [dbo].[AuditID] NOT NULL,
	[VWTID] [dbo].[VWTID] NULL,
	[AuditItemID] [dbo].[AuditItemID] NULL,
	[PhysicalRowID] [int] NOT NULL,

	[Manufacturer] [dbo].[LoadText] NULL,
	[ManufacturerID] [dbo].[PartyID] NULL,
	
	[CountryCode] dbo.LoadText NULL,
	[CountryID] dbo.CountryID NULL,
	
	[EventType] dbo.LoadText NULL,
	[VehiclePurchaseDateOrig] dbo.Loadtext NULL,
	[VehicleRegistrationDateOrig] dbo.Loadtext NULL,
	[VehicleDeliveryDateOrig] dbo.Loadtext NULL,
	[ServiceEventDateOrig] dbo.Loadtext NULL,
	[DealerCode] dbo.LoadText NULL,
	[CustomerUniqueId] dbo.LoadText NULL,
	[CompanyName] dbo.LoadText NULL,

	[Title] dbo.Title NULL,
	[Firstname] dbo.NameDetail NULL,
	[SurnameField1] dbo.NameDetail NULL,
	[SurnameField2] dbo.NameDetail NULL,

	[Salutation] dbo.LoadText NULL,
	[Address1] dbo.LoadText NULL,
	[Address2] dbo.LoadText NULL,
	[Address3] dbo.LoadText NULL,
	[Address4] dbo.LoadText NULL,
	[Address5(City)] dbo.LoadText NULL,
	[Address6(County)] dbo.LoadText NULL,
	[Address7(Postcode/Zipcode)] dbo.LoadText NULL,
	[Address8(Country)] dbo.LoadText NULL,
	[HomeTelephoneNumber] dbo.LoadText NULL,
	[BusinessTelephoneNumber] dbo.LoadText NULL,
	[MobileTelephoneNumber] dbo.LoadText NULL,
	[ModelName] dbo.LoadText NULL,
	[ModelYear] dbo.LoadText NULL,

	[Vin] dbo.VIN NULL,
	[RegistrationNumber] dbo.RegistrationNumber NULL,

	[EmailAddress1] dbo.LoadText NULL,
	[EmailAddress2] dbo.LoadText NULL,
	[PreferredLanguage] dbo.LoadText NULL,
	[CompleteSuppression] dbo.LoadText NULL,
	[Suppression-Email] dbo.LoadText NULL,
	[Suppression-Phone] dbo.LoadText NULL,
	[Suppression-Mail] dbo.LoadText NULL,
	[InvoiceNumber] dbo.LoadText NULL,
	[InvoiceValue] dbo.LoadText NULL,
	[ServiceEmployeeCode] dbo.LoadText NULL,
	[EmployeeName] dbo.LoadText NULL,
	
	[OwnershipCycleOrig] dbo.LoadText NULL,
	[OwnershipCycle] dbo.OwnershipCycle NULL,
	
	[Gender] dbo.LoadText NULL,
	[PrivateOwner] dbo.LoadText NULL,
	[OwningCompany] dbo.LoadText NULL,
	[User/ChooserDriver] dbo.LoadText NULL,
	[EmployerCompany] dbo.LoadText NULL,
	[MonthAndYearOfBirth] dbo.LoadText NULL,
	[PreferredMethodsOfContact] dbo.LoadText NULL,
	[PermissionsForContact] dbo.LoadText NULL,

	[BreakdownDate] [datetime2](7) NULL,
	[BreakdownDateOrig] dbo.LoadText NULL,

	[BreakdownCountry] dbo.RoadsideNetworkCode NULL,
	[BreakdownCountryID] dbo.CountryID NULL,

	[BreakdownCaseId] dbo.LoadText NULL,

	[CarHireStartDate] [datetime2](7)  NULL,
	[CarHireStartDateOrig] dbo.Loadtext NULL,

	[ReasonForHire] dbo.LoadText NULL,
	[HireGroupBranch] dbo.LoadText NULL,
	[CarHireTicketNumber] dbo.LoadText NULL,
	[HireJobNumber] dbo.LoadText NULL,
	[RepairingDealer] dbo.LoadText NULL,
	[DataSource] dbo.LoadText NULL,

	ReplacementVehicleMake loadtext NULL,
	ReplacementVehicleModel loadtext NULL,
	VehicleReplacementTime time NULL,			-- 8967 - replaced in new sample file with CarHireStartTime

	CarHireStartTime			loadtext NULL,	-- 8976 - New fields
	ConvertedCarHireStartTime	time NULL,		-- 8976 - New fields
	RepairingDealerCountry		loadtext NULL,	-- 8976 - New fields
	RoadsideAssistanceProvider	loadtext NULL,	-- 8976 - New fields
	BreakdownAttendingResource	loadtext NULL,	-- 8976 - New fields
	CarHireProvider				loadtext NULL,	-- 8976 - New fields
	CountryCodeISOAlpha2		loadtext NULL,	-- 8976 - New fields
	BreakdownCountryISOAlpha2	loadtext NULL,	-- 8976 - New fields

	PreferredLanguageID			int	NULL,		-- 8976 - New fields
	PerformNormalVWTLoadFlag	varchar(1) NULL,-- 8967 - To indicate whether we do normal/full VWT load or original Roadside load processing

	[MatchedODSVehicleID] [dbo].[VehicleID] NULL,
	[MatchedODSPersonID] [dbo].[PartyID] NULL,
	[MatchedODSOrganisationID] [dbo].[PartyID] NULL,
	[MatchedODSEmailAddress1ID] [dbo].[ContactMechanismID] NULL,
	[MatchedODSEmailAddress2ID] [dbo].[ContactMechanismID] NULL,
	[DateTransferredToVWT] [datetime2](7) NULL,
	[MatchedODSMobileTelephoneNumberID] [dbo].[ContactMechanismID] NULL		-- BUG 14868 - New field
);