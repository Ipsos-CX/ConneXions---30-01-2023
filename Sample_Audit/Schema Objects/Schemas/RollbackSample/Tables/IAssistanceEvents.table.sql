CREATE TABLE [RollbackSample].[IAssistanceEvents]
(
	[IAssistanceID] INT NOT NULL,

	[AuditID] dbo.AuditID NOT NULL,
	[VWTID] INT NULL,
	[AuditItemID] dbo.AuditItemID NULL,
	[PhysicalRowID] INT NOT NULL,
	[EventID] dbo.EventID NULL,

	[Manufacturer] dbo.LoadText NULL,
	[ManufacturerID] dbo.PartyID NULL,

	[CountryCode] dbo.LoadText NULL,			-- This is the Vehicle Origin Country
	[CountryID] dbo.CountryID NULL,				-- This is taken from the Address8 Country Code column

	[EventType] dbo.LoadText NULL,
	[VehiclePurchaseDateOrig] dbo.LoadText NULL,
	[VehicleRegistrationDateOrig] dbo.LoadText NULL,
	[VehicleDeliveryDateOrig] dbo.LoadText NULL,
	[ServiceEventDateOrig] dbo.LoadText NULL,
	[DealerCode] dbo.LoadText NULL,
	[CustomerUniqueID] dbo.LoadText NULL,
	[CompanyName] dbo.LoadText NULL,

	[Title] dbo.Title NULL,
	[FirstName] dbo.NameDetail NULL,
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

	[VIN] dbo.VIN NULL,
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

	[DataSource] dbo.LoadText NULL,
	[IAssistanceProvider] dbo.LoadText NULL,
	[IAssistanceCallID] dbo.LoadText NULL,
	[IAssistanceCallStartDate] [DATETIME2](7)  NULL,
	[IAssistanceCallStartDateOrig] dbo.LoadText NULL,
	[IAssistanceCallCloseDate] [DATETIME2](7)  NULL,
	[IAssistanceCallCloseDateOrig] dbo.LoadText NULL,
	[IAssistanceHelpdeskAdvisorName] dbo.LoadText NULL,
	[IAssistanceHelpdeskAdvisorID] dbo.LoadText NULL,
	[IAssistanceCallMethod] dbo.LoadText NULL,
	
	[CountryCodeISOAlpha2] dbo.LoadText NULL,
	[PreferredLanguageID] INT NULL,		
	[PerformNormalVWTLoadFlag] VARCHAR(1) NULL,
	
	[MatchedODSVehicleID] [dbo].[VehicleID] NULL,
	[MatchedODSPersonID] [dbo].[PartyID] NULL,
	[MatchedODSOrganisationID] [dbo].[PartyID] NULL,
	[MatchedODSEmailAddress1ID] [dbo].[ContactMechanismID] NULL,
	[MatchedODSEmailAddress2ID] [dbo].[ContactMechanismID] NULL,
	[MatchedODSMobileTelephoneNumberID] [dbo].[ContactMechanismID] NULL,
	[DateTransferredToVWT] [DATETIME2](7) NULL,
	[SampleTriggeredSelectionReqID] INT NULL
);

