CREATE TABLE [China].[Service_WithResponses]
(
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[AuditID] [dbo].[AuditID] NULL,
	[AuditItemID] [dbo].[AuditItemID] NULL,
	[PhysicalRowID] [int] NULL,
	[Manufacturer] [dbo].[LoadText] NULL,
	[CountryCode] [dbo].[LoadText] NULL,
	[JLRSuppliedEventType] [dbo].[LoadText] NULL,
	[EventType] [dbo].[LoadText] NULL,
	[VehiclePurchaseDate] [dbo].[LoadText] NULL,
	[VehicleRegistrationDate] [dbo].[LoadText] NULL,
	[VehicleDeliveryDate] [dbo].[LoadText] NULL,
	[ServiceEventDate] [dbo].[LoadText] NULL,
	[DealerCode] [dbo].[LoadText] NULL,
	[CustomerUniqueID] [dbo].[LoadText] NULL,
	[CompanyName] [dbo].[LoadText] NULL,
	[Title] [dbo].[LoadText] NULL,
	[FirstName] [dbo].[LoadText] NULL,
	[SurnameField1] [dbo].[LoadText] NULL,
	[SurnameField2] [dbo].[LoadText] NULL,
	[Salutation] [dbo].[LoadText] NULL,
	[Address1] [dbo].[LoadText] NULL,
	[Address2] [dbo].[LoadText] NULL,
	[Address3] [dbo].[LoadText] NULL,
	[Address4] [dbo].[LoadText] NULL,
	[Address5] [dbo].[LoadText] NULL,
	[Address6] [dbo].[LoadText] NULL,
	[Address7] [dbo].[LoadText] NULL,
	[Address8] [dbo].[LoadText] NULL,
	[HomeTelephoneNumber] [dbo].[LoadText] NULL,
	[BusinessTelephoneNumber] [dbo].[LoadText] NULL,
	[MobileTelephoneNumber] [dbo].[LoadText] NULL,
	[ModelName] [dbo].[LoadText] NULL,
	[ModelYear] [dbo].[LoadText] NULL,
	[VIN] [dbo].[LoadText] NULL,
	[RegistrationNumber] [dbo].[LoadText] NULL,
	[EmailAddress1] [dbo].[LoadText] NULL,
	[EmailAddress2] [dbo].[LoadText] NULL,
	[PreferredLanguage] [dbo].[LoadText] NULL,
	[CompleteSuppression] [dbo].[LoadText] NULL,
	[SuppressionEmail] [dbo].[LoadText] NULL,
	[SuppressionPhone] [dbo].[LoadText] NULL,
	[SuppressionMail] [dbo].[LoadText] NULL,
	[InvoiceNumber] [dbo].[LoadText] NULL,
	[InvoiceValue] [dbo].[LoadText] NULL,
	[ServiceEmployeeCode] [dbo].[LoadText] NULL,
	[EmployeeName] [dbo].[LoadText] NULL,
	[OwnershipCycle] [dbo].[LoadText] NULL,
	[Gender] [dbo].[LoadText] NULL,
	[PrivateOwner] [dbo].[LoadText] NULL,
	[OwningCompany] [dbo].[LoadText] NULL,
	[UserChooserDriver] [dbo].[LoadText] NULL,
	[EmployerCompany] [dbo].[LoadText] NULL,
	[MonthAndYearOfBirth] [dbo].[LoadText] NULL,
	[PreferrredMethodOfContact] [dbo].[LoadText] NULL,
	[PermissionsForContact] [dbo].[LoadText] NULL,
	[ConvertedVehicleDeliveryDate] [datetime2](7) NULL,
	[ConvertedServiceEventDate] [datetime2](7) NULL,
	[ConvertedVehiclePurchaseDate] [datetime2](7) NULL,
	[ConvertedVehicleRegistrationDate] [datetime2](7) NULL,
	[ManufacturerPartyID] [int] NULL,
	[SampleSupplierPartyID] [int] NULL,
	[CountryID] [smallint] NULL,
	[EventTypeID] [smallint] NULL,
	[LanguageID] [smallint] NULL,
	[DealerCodeOriginatorPartyID] [int] NULL,
	[SetNameCapitalisation] [bit] NULL,
	[SampleTriggeredSelectionReqID]   INT NULL,
	[CustomerIdentifier] [dbo].[CustomerIdentifier] NULL,
	[CustomerIdentifierUsable] BIT NULL,
	
	-- Response data --
	[ResponseID]			[dbo].[LoadText] NULL,
	[InterviewerNumber]		[dbo].[LoadText] NULL,
	[ResponseDate]			[dbo].[LoadText] NULL,
	[Q1Response]			[dbo].[LoadText] NULL,
	[Q1Verbatim]			[dbo].[LoadText] NULL,
	[Q2Response]			[dbo].[LoadText] NULL,
	[Q3Response]			[dbo].[LoadText] NULL,
	[Q4Response]			[dbo].[LoadText] NULL,
	[Q5Response]			[dbo].[LoadText] NULL,
	[Q5aResponse]			[dbo].[LoadText] NULL,
	[Q6Response]			[dbo].[LoadText] NULL,
	[Q7Response]			[dbo].[LoadText] NULL,
	[Q8Response]			[dbo].[LoadText] NULL,
	[Q9Response]			[dbo].[LoadText] NULL,
	[Q9aResponse]			[dbo].[LoadText] NULL,
	[Q9aOptionResponse]		[dbo].[LoadText] NULL,
	[Q9aOption9verbatim]	[dbo].[LoadText] NULL,
	[Q10Response]			[dbo].[LoadText] NULL,
	[Q10aOptionResponse]	[dbo].[LoadText] NULL,
	[Q10Option9Verbatim]	[dbo].[LoadText] NULL,
	[Q11Response]			[dbo].[LoadText] NULL,
	[Q12Response]			[dbo].[LoadText] NULL,
	[Q13Response]			[dbo].[LoadText] NULL,
	[Q14Response]			[dbo].[LoadText] NULL,
	[Q14aResponse]			[dbo].[LoadText] NULL,
	[Q14bResponse]			[dbo].[LoadText] NULL,
	[Q15Response]			[dbo].[LoadText] NULL,
	[Q16Response]			[dbo].[LoadText] NULL,
	[Q17Response]			[dbo].[LoadText] NULL,
	[Q18Response]			[dbo].[LoadText] NULL,
	[AnonymousToRetailer]	[dbo].[LoadText] NULL,
	[AnonymousToManufacturer]	[dbo].[LoadText] NULL,
	[Q3Verbatim]			[dbo].[LoadText] NULL,
	[Q5Verbatim]			[dbo].[LoadText] NULL,	
	[Q6Verbatim]			[dbo].[LoadText] NULL,
	[Q7Verbatim]			[dbo].[LoadText] NULL,	
	[Q8Verbatim]			[dbo].[LoadText] NULL,
	[Q9Verbatim]			[dbo].[LoadText] NULL,
	[Q12Verbatim]			[dbo].[LoadText] NULL,
	[Q13Verbatim]			[dbo].[LoadText] NULL,
	[Q15Verbatim]			[dbo].[LoadText] NULL,
	[Q17Verbatim]			[dbo].[LoadText] NULL,
	
	--BUG 14099 China - New data map July 2017
	[Q2Verbatim]			[dbo].[LoadText] NULL,
	[Q5h]					[dbo].[LoadText] NULL,	
	[Q12]					[dbo].[LoadText] NULL,
	[Q14c]					[dbo].[LoadText] NULL,	
	[Q14cVerbatim]			[dbo].[LoadText] NULL,
	[Q19]					[dbo].[LoadText] NULL,
	[Q19Verbatim]			[dbo].[LoadText] NULL,
	[Q20]					[dbo].[LoadText] NULL,
	[Q20aVerbatim]			[dbo].[LoadText] NULL,
	[Q21]					[dbo].[LoadText] NULL,
	[Q21Verbatim]			[dbo].[LoadText] NULL,
	[Q22]					[dbo].[LoadText] NULL,
	[Q22Verbatim]			[dbo].[LoadText] NULL,
	[QCN1]					[dbo].[LoadText] NULL,
	[QCN2]					[dbo].[LoadText] NULL,
	--BUG 14099 China - New data map July 2017
		
	-- VWT transfer and logging information
	[DateTransferredToVWT] [datetime2](7) NULL,
	[CaseID]				INT  NULL,

	-- Not signed off - NOW NOT TO BE RELEASED -- [SurveyMethod]			[dbo].[LoadText] NULL

	[Q24]					[dbo].[LoadText] NULL,		-- BUG 15340 - 10-04-2019
	[Q9b]					[dbo].[LoadText] NULL,		-- BUG 15340 - 10-04-2019 
	[Q9anew1]				[dbo].[LoadText] NULL,		-- BUG 16750     
	[Q9anew2]				[dbo].[LoadText] NULL,		-- BUG 16750    
	[Q9anew3]				[dbo].[LoadText] NULL,		-- BUG 16750
	[Q9anew4]				[dbo].[LoadText] NULL,		-- BUG 16750
	[Q9anew5]				[dbo].[LoadText] NULL,		-- BUG 16750
	[Q9anew6]				[dbo].[LoadText] NULL,		-- BUG 16750
	[Q9anew7]				[dbo].[LoadText] NULL,		-- BUG 16750
	[Q9anew30]				[dbo].[LoadText] NULL,		-- BUG 16750
	[Q9anew9Verbatim]		[dbo].[LoadText] NULL		-- BUG 16750
)
