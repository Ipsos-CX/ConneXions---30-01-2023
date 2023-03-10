CREATE VIEW [SelectionOutput].[vwSelectionCombinedAllOutput]
AS

/*
	Purpose:	Selects sample ouput in Selection Output Child - Combined Online File.dtsx
	
	Version		Date		Deveoloper				Comment
	1.1       08/07/2021   Ben King               TASK 494 - Seperate CATI Sample into 1 combined file
	1.2       2021-08-23   Ben King               TASK 567 - Setup SV-CRM Lost Leads Loader
	1.3       2021-08-23   Ben King               TASK 600 - 18342 - Legitimate Business Interest (LBI) Consent
	
*/

	SELECT DISTINCT 
		[ID],
		[SurveyTypeID],
		[ModelCode],
		[ModelDescription],
		[ModelYear],
		[ManufacturerID],
		[Manufacturer],
		[CarRegistration],
		[VIN],
		[ModelVariantCode],
		[ModelVariantDescription],
		[PartyID],
		[Title],
		[Initial],
		[LastName],
		[FullName],
		[DearName],
		[CompanyName],
		[Address1],
		[Address2],
		[Address3],
		[Address4],
		[Address5],
		[Address6],
		[Address7],
		[Address8],
		[Country],
		[CountryID],
		[EmailAddress],
		[HomeNumber],
		[WorkNumber],
		[MobileNumber],
		[CustomerUniqueID],
		[VersionCode],
		[LanguageID],
		[GenderID],
		[EventTypeID],
		[EventDate],
		[Password],
		[IType],
		[SelectionDate],
		[Week],
		[Expired],
		[CampaignID],
		[Test],
		[DealerPartyID],
		[ReportingDealerPartyID],
		[DealerName],
		[DealerCode],
		[GlobalDealerCode],
		[BusinessRegion],
		[OwnershipCycle],
		[EmailSignator],
		[EmailSignatorTitle],
		[EmailContactText],
		[EmailCompanyDetails],
		[JLRPrivacyPolicy],
		[JLRCompanyName],
		[UnknownLanguage],
		[BilingualFlag],
		[BilingualLanguageID],
		[DearNameBilingual],
		[EmailSignatorTitleBilingual],
		[EmailContactTextBilingual],
		[EmailCompanyDetailsBilingual],
		[JLRPrivacyPolicyBilingual],
		[EmployeeCode],
		[EmployeeName],
		[CRMSalesmanCode],
		[CRMSalesmanName],
		[RockarDealer],
		[SVOTypeID],
		[SVODealer],
		[VistaContractOrderNumber],
		[DealerNumber],
		[FOBCode],
		[HotTopicCodes],
		[ServiceTechnicianID],
		[ServiceTechnicianName],
		[ServiceAdvisorID],
		[ServiceAdvisorName],
		[RepairOrderNumber],
		[ServiceEventType],
		[Approved],
		[BreakdownDate],
		[BreakdownCountry],
		[BreakdownCountryID],
		[BreakdownCaseID],
		[CarHireStartDate],
		[ReasonForHire],
		[HireGroupBranch],
		[CarHireTicketNumber],
		[HireJobNumber],
		[RepairingDealer],
		[DataSource],
		[ReplacementVehicleMake],
		[ReplacementVehicleModel],
		[CarHireStartTime],
		[RepairingDealerCountry],
		[RoadsideAssistanceProvider],
		[BreakdownAttendingResource],
		[CarHireProvider],
		[VehicleOriginCountry],
		[CRCOwnerCode],		
		[CRCCode],
		[CRCMarketCode],
		[SampleYear],
		[VehicleMileage],
		[VehicleMonthsinService],
		[CRCRowID],
		[CRCSerialNumber],
		[NSCFlag],
		[JLREventType],
		[DealerType],
		[Queue],
		[Dealer10DigitCode],
		[EventID],
        [EngineType],
		[LeadVehSaleType],				-- V1.2
		[LeadOrigin],					-- V1.2
		[LegalGrounds],					-- V1.3
		[AnonymityQuestion]             -- V1.3
	FROM [SelectionOutput].[CombinedOnlineOutput]

	GO