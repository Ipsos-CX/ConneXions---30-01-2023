
CREATE TABLE [Stage].[Combined_Roadside_Service](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[AuditID] [dbo].[AuditID] NULL,
	[PhysicalRowID] [int] NULL,
		
	[Manufacturer] [dbo].[LoadText] NULL,
	[CountryCode] dbo.LoadText NULL,
	[EventType] dbo.LoadText NULL,
	[VehiclePurchaseDate] dbo.Loadtext NULL,
	[VehicleRegistrationDate] dbo.Loadtext NULL,
	[VehicleDeliveryDate] dbo.Loadtext NULL,
	[ServiceEventDate] dbo.Loadtext NULL,
	[DealerCode] dbo.LoadText NULL,
	[CustomerUniqueId] dbo.LoadText NULL,
	[CompanyName] dbo.LoadText NULL,
	[Title] dbo.LoadText NULL,
	[Firstname] dbo.LoadText NULL,
	[SurnameField1] dbo.LoadText NULL,
	[SurnameField2] dbo.LoadText NULL,
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
	[Vin] dbo.LoadText NULL,
	[RegistrationNumber] dbo.LoadText NULL,
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
	[OwnershipCycle] dbo.LoadText NULL,
	[Gender] dbo.LoadText NULL,
	[PrivateOwner] dbo.LoadText NULL,
	[OwningCompany] dbo.LoadText NULL,
	[User/ChooserDriver] dbo.LoadText NULL,
	[EmployerCompany] dbo.LoadText NULL,
	[MonthAndYearOfBirth] dbo.LoadText NULL,
	[PreferredMethodsOfContact] dbo.LoadText NULL,
	[PermissionsForContact] dbo.LoadText NULL,

	[BreakdownDate] dbo.Loadtext NULL,
	[ConvertedBreakdownDate] [datetime2](7) NULL,

	[BreakdownCountry] dbo.LoadText NULL,
	[BreakdownCaseId] dbo.LoadText NULL,
	
	[CarHireStartDate] dbo.Loadtext NULL,
	[ConvertedCarHireStartDate] [datetime2](7)  NULL,
	
	[ReasonForHire] dbo.LoadText NULL,
	[HireGroupBranch] dbo.LoadText NULL,
	[CarHireTicketNumber] dbo.LoadText NULL,
	[HireJobNumber] dbo.LoadText NULL,
	[RepairingDealer] dbo.LoadText NULL,
	[DataSource] dbo.LoadText NULL,
	
	ReplacementVehicleMake dbo.LoadText NULL,
	ReplacementVehicleModel dbo.LoadText NULL,
	VehicleReplacementTime dbo.LoadText NULL,		-- 8967 - replaced in new sample file with CarHireStartTime

	CarHireStartTime			loadtext NULL,	-- 8976 - New fields
	ConvertedCarHireStartTime	time NULL,		-- 8976 - New fields
	RepairingDealerCountry		loadtext NULL,	-- 8976 - New fields
	RoadsideAssistanceProvider	loadtext NULL,	-- 8976 - New fields
	BreakdownAttendingResource	loadtext NULL,	-- 8976 - New fields
	CarHireProvider				loadtext NULL,	-- 8976 - New fields
	CountryCodeISOAlpha2		loadtext NULL,	-- 8976 - New fields
	BreakdownCountryISOAlpha2	loadtext NULL,	-- 8976 - New fields
	PreferredLanguageID				int	NULL,		-- 8976 - New fields
	SampleTriggeredSelectionReqID	int	NULL
	
);