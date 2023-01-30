
CREATE PROCEDURE [SampleReport].[uspPopulateReportTables]
@MarketRegion VARCHAR (200), @ReportType VARCHAR(200), @TimePeriod CHAR (20), @EchoFeed BIT=0, @DailyEcho BIT=0, @EchoFeed12mthRolling BIT=0
AS
SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY


/*
	Purpose:	Builds the reporting tables from the .Base table for the time period specified.
		
	Version			Date				Developer			Comment
	1.0				11/07/2013			Chris Ross			Created
	1.1				27/01/2014			Chris Ross			9751 -  Add in columns: SuppliedMobilePhone, MissingMobilePhone, MissingMobilePhoneAndEmail, 
																	CaseOutputType. And totals: EmailInvites, SMSInvites, PostalInvites, SampleEmailAddress, CaseEmailAddress
	1.2				03/04/2014			Eddie Thomas		9998 -  Populating new for the purposes of adding Global summary data
	1.3				03/06/2014			Ali Yuksel			10420 - Global Dealer Database dealer code added (DealerCodeGDD)
	1.4				13/10/2014			Eddie Thomas		Missing sample data when generating Echofeeds. endate should be date report ran, NOT last day of previous month.
	1.5				15/12/2014			Eddie Thomas		11047 - Add PreviousEventBounceBack and EventDateTooYoung
	
	1.6				29/01/2015			Peter Doyle			BUG 11207 - Force Echo reports to look at last year's data when reports are run in the 1st quarter of current year.
	1.7				26/02/2015			Chris Ross			BUG 11026 - Add in BusinessRegion column
	1.8				17/07/2015			Chris Ledger		BUG 11658 - Addition of Roadside (major change for regions)
	1.9				28/02/2016			Chris Ledger		BUG 12377 - Do not update global aggregate tables for Echo feeds 
	1.10			29/02/2016			Chris Ledger		BUG 12395 - Sample Reports Amendments 
	1.11			22/04/2016			Chris Ledger		Change Echo @StartYearDate to only show this year's data
	1.12			19/07/2016			Ben King			BUG 12853 - CRC sample reporting raw files
	1.12			18/10/2016			Chris Ross			BUG 13171 - Add in SubNationalTerritory column
	1.13			14/11/2016			Ben King			BUG 13312 - Add DedupeEqualToEvents to Table SampleReport.IndividualRows
	1.14			15/11/2016			Ben King			BUG 13314 - Add HardBounce, SoftBounce, Unsubscribes
	1.15			23/11/2016			Chris Ross			BUG	13344 - Add new in column DateOfLeadCreation to IndividualRows table
	1.16			23/11/2016			Ben King			BUG 13329 - Add HardBounce, SoftBounce, Unsubscribes, SuppliedPhoneNumber, SuppliedMobilePhone to Tab Summary_DealerRegion & Summary_DealerGroup in SampleReports.xls
	1.17			24/11/2016			Ben King			BUG	13358 - Add PrevHardBounce, PrevSoftBounce - to Echo files, individual tab & Summary_DealerRegion & Summary_DealerGroup in SampleReports.xls
	1.18			01/02/2017			Ben King			BUG 13546 - Add US Employee Fields to Echo reports
	1.19			23/03/2017			Ben King			BUG 13465 - Add FOBCode to Echo & SampleReports (individual Sheet)
	1.20			19/04/2017			Ben KIng			BUG 13817 - Add HardBounce & SoftBounce fields to Global Reports 
	1.21			25/04/2017			Chris Ross			BUG 13364 - Add in Customer Preference columns
	1.22		    17/05/2017			Ben King			BUG 13933 & 13884 - Add fields SVCRMSalesType, SVCRMInvalidSalesType, DealNumber, RepairOrderNumber, VistaCommonOrderNumber	
	1.23			24/05/2017			Ben King			BUG 13950 - Echo reporting change - employee reporting for generic roles
	1.24			30/05/2017			Ben King			BUG 13942 - Echo Sample Reporting on a Daily Basis
	1.25			20/06/2017          Ben King			BUG 14033 - Add Field RecordChanged to Echo output
	1.26			07/09/2017			Chris Ross			BUG 14122 - Add in PDIFlagSet column
	1.27			14/11/2017			Ben King			BUG 14379 - New Suppression Logic_for Sample Reporting Purposes
	1.28		    11/01/2018			Ben King			BUG 14488 - 90 day response capture into 2018
	1.29		    19/01/2018			Ben King			BUG 14487 - Sample Reporting _Other column
	1.30			14/03/2018			Ben King			BUG 14486 - Customer Preference Override Flag
	1.31			01/05/2018			Ben King			BUG 14669 - GDPR New Flag_ Sample Reporting
	1.32			05/10/2018			Ben King			BUG 15017 - Add ContactMechanismID's
	1.33			17/12/2018			Ben King			BUG 15125 - Add contact prefernces model fields.
	1.34			28/01/2019			Ben King			BUG 15227 - 12 month Static rolling extract report
	1.35			15/02/2019			Ben King			BUG add new exclusion flag InvalidDateOfLastContact to echo/sample reports
	1.36			15/02/2019			Ben King			BUG 15211 - add MatchedODSPrivEmailAddressID
	1.37			03/01/2020			Ben King			BUG 16864 - Add exclusion category flags
	1.38			01/04/2020			Chris Ledger		BUG 15372 - Fix hard coded database references and cases
	1.39			01/01/2021			Ben King			BUG 18093 - add 10digit code (plus other fields)
	1.40			10/06/2021			Ben King			TASK 474 - Japan Purchase - Mismatch between Dealer and VIN
	1.41			30/09/2022			Eddie Thomas		TASK 1017 - Add SubBrand
	1.42			05/10/2022			Eddie Thomas		TASK 926 - Add ModelCode
	1.43			14/10/2022			Eddie Thomas		TASK 1064 - Adding LeadVehSaleType & ModelVariant
*/


	-- TEST PARAMETERS
	--DECLARE @MarketRegion VARCHAR (200) = 'MENA'
	--DECLARE @ReportType VARCHAR(200) = 'Region'
	--DECLARE @TimePeriod CHAR(20) = 'YTD'
	--DECLARE @EchoFeed BIT = 0

	--V1.34 - SKIP BULK PROCESSING IF 12 MONTH REPORT RUN
IF  @EchoFeed12mthRolling <> 1
  BEGIN

	------------------------------------------------------------------------------------------------------
	-- Clear down tables  (Do first to ensure tables empty if we quit out due being something being invalid)
	------------------------------------------------------------------------------------------------------

	TRUNCATE TABLE SampleReport.IndividualRows
	TRUNCATE TABLE SampleReport.SummaryDealerGroup
	TRUNCATE TABLE SampleReport.SummaryDealerRegion
	TRUNCATE TABLE SampleReport.SummaryFiles
	TRUNCATE TABLE SampleReport.SummaryHeader


	------------------------------------------------------------------------------------------------------
	-- Check whether Time Period active and set report variables
	------------------------------------------------------------------------------------------------------

	DECLARE @Brand	NVARCHAR(510), 
			@Questionnaire VARCHAR(255), 
			@ReportDate DATETIME,
			@TimePeriodDescription  VARCHAR(200),
			@ActiveFlag int
			

	SELECT  @TimePeriodDescription	= TimePeriodDescription, 
			@ActiveFlag				= ActiveFlag
	FROM SampleReport.TimePeriods 

	-- Quit out if this time period is not active
	IF ISNULL(@ActiveFlag, 0) = 0
	RETURN 0


	-- Set remaining param's 
	SELECT TOP 1 @Brand			= Brand FROM SampleReport.Base 
	--SELECT TOP 1 @Market		= Market FROM SampleReport.Base				--V1.8 Retrieve Market/Region from Parameter
	SELECT TOP 1 @Questionnaire	= Questionnaire FROM SampleReport.Base 
	SELECT TOP 1 @ReportDate	= ReportDate FROM SampleReport.Base 


	-- Quit out if there is no data
	IF @ReportDate IS NULL 
	RETURN 0




	------------------------------------------------------------------------------------------------------
	-- Set time start and end dates based on report date and time period
	------------------------------------------------------------------------------------------------------

	DECLARE @LastMonthDate	DATETIME,
			@StartMonthDate	DATETIME,
			@LastQuarterDate DATETIME,
			@StartQuarterDate DATETIME,
			@StartYearDate	DATETIME,
			@StartDate		DATETIME,
			@EndDate		DATETIME

	SELECT @LastMonthDate = DATEADD(dd, 0, DATEDIFF(dd, 0, DATEADD(m, -1, @ReportDate ))) -- Also remove time
	SELECT @LastQuarterDate = DATEADD(dd, 0, DATEDIFF(dd, 0, DATEADD(m, -3, @ReportDate ))) -- Also remove time

	SELECT @StartMonthDate = DATEADD(dd, 1, DATEADD(dd,-(DAY(@LastMonthDate)),@LastMonthDate)) --First day of the month
	SELECT @StartQuarterDate = DATEADD(dd, 1, DATEADD(dd,-(DAY(@LastQuarterDate)),@LastQuarterDate)) --First day of the quarter

	IF @EchoFeed = 1
		-- Echo reports used to need to show previous year's data (removed but leave in old code in case need to rerun) V1.17
		BEGIN
			SELECT  @LastMonthDate = DATEADD(dd, 0,DATEDIFF(dd, 0,DATEADD(m, -3, @ReportDate))); --V1.28 (Jan,Feb,March also refer to entire previous years data 
																					             --       when YTD run, April forward only pools current year)
		
			--SELECT @StartYearDate =DATEADD (YEAR, DATEDIFF(YEAR, 0, @ReportDate)-1, 0)
			SELECT @StartYearDate = CONVERT(DATETIME, CONVERT(VARCHAR(8), DATEPART(YEAR, @LastMonthDate)) + '0101') --First day of the year
		END
	ELSE
		BEGIN
			SELECT @StartYearDate = CONVERT(DATETIME, CONVERT(VARCHAR(8), DATEPART(YEAR, @LastMonthDate)) + '0101') --First day of the year
		END

	--SELECT @StartYearDate = convert(datetime, convert(varchar(8), DATEPART(YEAR, @LastMonthDate)) + '0101') --First day of the year


	IF (@EchoFeed = 1 OR @DailyEcho = 1)  --V1.4, V1.24
		SELECT @EndDate = DATEADD(DD, 0, DATEDIFF(dd, 0, @ReportDate) + 1)
	ELSE
		SELECT @EndDate = DATEADD(dd,-(DAY(DATEADD(mm,1,@LastMonthDate))-1),DATEADD(mm,1,@LastMonthDate)) --First Day of Next Month

	--SELECT @LastMonthDate , @StartMonthDate ,@LastQuarterDate , @StartQuarterDate , @StartYearDate, @EndDate

	IF @TimePeriod = 'MTH' 
		SET @StartDate = @StartMonthDate
	ELSE IF @TimePeriod = 'QTR'
	BEGIN
		IF (DATEPART(MONTH, @StartQuarterDate)) IN (1,4,7,10)
			SET @StartDate = @StartQuarterDate
		ELSE
			RETURN 0		--- <<<<<<< If Quarter time period requested but not valid then stop processing
	END
	ELSE IF @TimePeriod = 'YTD'
		SET @StartDate = @StartYearDate
	ELSE IF @TimePeriod = '24H'   --V1.24 - Base data will only contain last 24 hours data + records that have changed since Monday on DailyEcho run.
		SET @StartDate = @StartYearDate
	ELSE RETURN 0			--- <<<<<<< If unrecognised param then stop processing




	------------------------------------------------------------------------------------------------
	--
	-- Output to Main Individual Detail Table
	--
	------------------------------------------------------------------------------------------------
	INSERT INTO SampleReport.IndividualRows 
			(SuperNationalRegion, BusinessRegion, DealerMarket, SubNationalTerritory, SubNationalRegion, CombinedDealer, DealerName, DealerCode, DealerCodeGDD, FullName, OrganisationName, AnonymityDealer, AnonymityManufacturer, CaseCreationDate, CaseStatusType, CaseOutputType, SentFlag, SentDate, RespondedFlag, ClosureDate, DuplicateRowFlag, BouncebackFlag, UsableFlag, ManualRejectionFlag, FileName, FileActionDate, FileRowCount, LoadedDate, AuditID, AuditItemID, MatchedODSPartyID, MatchedODSPersonID, LanguageID, PartySuppression, MatchedODSOrganisationID, MatchedODSAddressID, CountryID, PostalSuppression, EmailSuppression, MatchedODSVehicleID, ODSRegistrationID, MatchedODSModelID, OwnershipCycle, MatchedODSEventID, ODSEventTypeID, WarrantyID, Brand, Market, Questionnaire, QuestionnaireRequirementID, SuppliedName, SuppliedAddress, SuppliedPhoneNumber, SuppliedMobilePhone, SuppliedEmail, SuppliedVehicle, SuppliedRegistration, SuppliedEventDate, EventDateOutOfDate, EventNonSolicitation, PartyNonSolicitation, UnmatchedModel, UncodedDealer, EventAlreadySelected, NonLatestEvent, InvalidOwnershipCycle, RecontactPeriod, RelativeRecontactPeriod, InvalidVehicleRole, CrossBorderAddress, CrossBorderDealer, ExclusionListMatch, InvalidEmailAddress, BarredEmailAddress, BarredDomain, CaseID, SampleRowProcessed, SampleRowProcessedDate, WrongEventType, MissingStreet, MissingPostcode, MissingEmail, MissingTelephone, MissingStreetAndEmail, MissingTelephoneAndEmail, MissingMobilePhone, MissingMobilePhoneAndEmail, MissingPartyName, MissingLanguage, InvalidModel, InvalidManufacturer, InternalDealer, RegistrationNumber, RegistrationDate, VIN, OutputFileModelDescription, EventDate, SampleEmailAddress, CaseEmailAddress, PreviousEventBounceBack, EventDateTooYoung, AFRLCode, DealerExclusionListMatch, PhoneSuppression, SalesType, InvalidAFRLCode, InvalidSalesType, AgentCodeFlag, DedupeEqualToEvents,HardBounce,SoftBounce,Unsubscribes, DateOfLeadCreation, PrevSoftBounce, PrevHardBounce,ServiceTechnicianID,ServiceTechnicianName,ServiceAdvisorName,ServiceAdvisorID,CRMSalesmanName,CRMSalesmanCode, FOBCode, ContactPreferencesSuppression, ContactPreferencesPartySuppress, ContactPreferencesEmailSuppress, ContactPreferencesPhoneSuppress, ContactPreferencesPostalSuppress, SVCRMSalesType, SVCRMInvalidSalesType, DealNumber, RepairOrderNumber, VistaCommonOrderNumber, SalesEmployeeCode, SalesEmployeeName, ServiceEmployeeCode, ServiceEmployeeName, RecordChanged, PDIFlagSet, OriginalPartySuppression, OriginalPostalSuppression, OriginalEmailSuppression, OriginalPhoneSuppression, OtherExclusion, OverrideFlag, GDPRflag, SelectionPostalID, SelectionEmailID, SelectionPhoneID, SelectionLandlineID, SelectionMobileID, SelectionEmail, SelectionPhone, SelectionLandline, SelectionMobile, ContactPreferencesModel,ContactPreferencesPersist, InvalidDateOfLastContact, MatchedODSPrivEmailAddressID, SamplePrivEmailAddress, EmailExcludeBarred,EmailExcludeGeneric, EmailExcludeInvalid, CompanyExcludeBodyShop, CompanyExcludeLeasing, CompanyExcludeFleet, CompanyExcludeBarredCo, OutletPartyID, Dealer10DigitCode, OutletFunction, RoadsideAssistanceProvider, CRC_Owner, ClosedBy, Owner, CountryIsoAlpha2, CRCMarketCode, InvalidDealerBrand, SubBrand, ModelCode, LeadVehSaleType, ModelVariant)  --V1.12 'AgentCodeFlag' added, V1.13 DedupeEqualToEvents added, V1.14 HardBounce,SoftBounce,Unsubscribes added, V1.15 - DateOfLeadCreation added, V1.17, V1.18, V1.19, V1.21, V1.22, V1.23, V1.25, v1.26, V1.27, V1.30, V1.31, V1.32, V1.33, V1.35, V1.36, V1.37, V1.39, V1.40, V1.41, V1.42, V1.43
	SELECT   SuperNationalRegion, BusinessRegion, DealerMarket, SubNationalTerritory, SubNationalRegion, CombinedDealer, DealerName, DealerCode, DealerCodeGDD, FullName, OrganisationName, AnonymityDealer, AnonymityManufacturer, CaseCreationDate, CaseStatusType, CaseOutputType, SentFlag, SentDate, RespondedFlag, ClosureDate, DuplicateRowFlag, BouncebackFlag, UsableFlag, ManualRejectionFlag, FileName, FileActionDate, FileRowCount, LoadedDate, AuditID, AuditItemID, MatchedODSPartyID, MatchedODSPersonID, LanguageID, PartySuppression, MatchedODSOrganisationID, MatchedODSAddressID, CountryID, PostalSuppression, EmailSuppression, MatchedODSVehicleID, ODSRegistrationID, MatchedODSModelID, OwnershipCycle, MatchedODSEventID, ODSEventTypeID, WarrantyID, Brand, Market, Questionnaire, QuestionnaireRequirementID, SuppliedName, SuppliedAddress, SuppliedPhoneNumber, SuppliedMobilePhone, SuppliedEmail, SuppliedVehicle, SuppliedRegistration, SuppliedEventDate, EventDateOutOfDate, EventNonSolicitation, PartyNonSolicitation, UnmatchedModel, UncodedDealer, EventAlreadySelected, NonLatestEvent, InvalidOwnershipCycle, RecontactPeriod, RelativeRecontactPeriod, InvalidVehicleRole, CrossBorderAddress, CrossBorderDealer, ExclusionListMatch, InvalidEmailAddress, BarredEmailAddress, BarredDomain, CaseID, SampleRowProcessed, SampleRowProcessedDate, WrongEventType, MissingStreet, MissingPostcode, MissingEmail, MissingTelephone, MissingStreetAndEmail, MissingTelephoneAndEmail, MissingMobilePhone, MissingMobilePhoneAndEmail, MissingPartyName, MissingLanguage, InvalidModel, InvalidManufacturer, InternalDealer, RegistrationNumber, RegistrationDate, VIN, OutputFileModelDescription, EventDate, SampleEmailAddress, CaseEmailAddress, PreviousEventBounceBack, EventDateTooYoung, AFRLCode, DealerExclusionListMatch, PhoneSuppression, SalesType, InvalidAFRLCode, InvalidSalesType, AgentCodeFlag, DedupeEqualToEvents,HardBounce,[SoftBounce],Unsubscribes, DateOfLeadCreation, PrevSoftBounce, PrevHardBounce,ServiceTechnicianID,ServiceTechnicianName,ServiceAdvisorName,ServiceAdvisorID,CRMSalesmanName,CRMSalesmanCode, FOBCode, ContactPreferencesSuppression, ContactPreferencesPartySuppress, ContactPreferencesEmailSuppress, ContactPreferencesPhoneSuppress, ContactPreferencesPostalSuppress, SVCRMSalesType, SVCRMInvalidSalesType, DealNumber, RepairOrderNumber, VistaCommonOrderNumber, SalesEmployeeCode, SalesEmployeeName, ServiceEmployeeCode, ServiceEmployeeName, RecordChanged, PDIFlagSet, OriginalPartySuppression, OriginalPostalSuppression, OriginalEmailSuppression, OriginalPhoneSuppression, OtherExclusion, OverrideFlag, GDPRflag, SelectionPostalID, SelectionEmailID, SelectionPhoneID, SelectionLandlineID, SelectionMobileID, SelectionEmail, SelectionPhone, SelectionLandline, SelectionMobile, ContactPreferencesModel,ContactPreferencesPersist, InvalidDateOfLastContact, MatchedODSPrivEmailAddressID, SamplePrivEmailAddress, EmailExcludeBarred,EmailExcludeGeneric, EmailExcludeInvalid, CompanyExcludeBodyShop, CompanyExcludeLeasing, CompanyExcludeFleet, CompanyExcludeBarredCo, OutletPartyID, Dealer10DigitCode, OutletFunction, RoadsideAssistanceProvider, CRC_Owner, ClosedBy, Owner, CountryIsoAlpha2, CRCMarketCode, InvalidDealerBrand, SubBrand, ModelCode, LeadVehSaleType, ModelVariant  --V1.12 'AgentCodeFlag' added, V1.13 DedupeEqualToEvents added, V1.14 HardBounce,SoftBounce,Unsubscribes added, V1.15 - DateOfLeadCreation added, V1.17, V1.18, V1.19, V1.21, V1.22, V1.23, V1.25, v1.26, V1.27, V1.30, V1.31, V1.32, V1.33, V1.35, V1.36, V1.37, V1.39, V1.40, V1.41, V1.42, V1.43
	FROM SampleReport.Base
	WHERE FileActionDate >= @StartDate AND FileActionDate < @EndDate 



	------------------------------------------------------------------------------------------------
	--
	--  BUILD DEALER SUMMARY TABLES
	--
	------------------------------------------------------------------------------------------------


	TRUNCATE TABLE SampleReport.SummaryDealerRegion 

	INSERT INTO SampleReport.SummaryDealerRegion
		 (      SuperNationalRegion, 
				BusinessRegion, 
				Market, 
				SubNationalTerritory,		-- v1.12
				SubNationalRegion, 
				DealerCode, 
				DealerCodeGDD, 
				DealerName, 
				RecordsLoaded, 
				SuppliedEmail, 
				UsableRecords, 
				InvitesSent, 
				Bouncebacks, 
				Responded, 
				EmailInvites, 
				SMSInvites, 
				PostalInvites,
				PhoneInvites,				-- V1.10
				
				SoftBounce,					-- V1.16
				HardBounce,					-- V1.16
				Unsubscribes,				-- V1.16
				SuppliedPhoneNumber,		-- V1.16
				SuppliedMobilePhone,		-- V1.16
				PrevSoftBounce,				-- V1.17
				PrevHardBounce,				-- V1.17
				
				OriginalPartySuppression,   -- V1.27
				OriginalPostalSuppression,	-- V1.27
				OriginalEmailSuppression,	-- V1.27
				OriginalPhoneSuppression	-- V1.27
				
				)
	SELECT	B.SuperNationalRegion ,
			B.BusinessRegion,					-- v1.7
			B.Market,
			B.SubNationalTerritory,				--v 1.12
			B.SubNationalRegion,
			B.DealerCode,
			B.DealerCodeGDD, 
			B.DealerName,	
			COUNT(*)						AS RecordsLoaded,
			SUM(ISNULL(B.SuppliedEmail, 0))	AS SuppliedEmail,
			SUM(ISNULL(B.UsableFlag, 0))		AS UsableRecords,
			SUM(ISNULL(B.SentFlag, 0))		AS InvitesSent,
			SUM(ISNULL(B.BouncebackFlag, 0))AS Bouncebacks,
			SUM(ISNULL(B.RespondedFlag, 0))	AS Responded,
			
			
			
			SUM(CASE WHEN B.CaseOutputType = 'Online' THEN 1 ELSE 0 END) AS EmailInvites,
			SUM(CASE WHEN B.CaseOutputType = 'SMS'    THEN 1 ELSE 0 END) AS SMSInvites,
			SUM(CASE WHEN B.CaseOutputType = 'Postal' THEN 1 ELSE 0 END) AS PostalInvites,
			SUM(CASE WHEN B.CaseOutputType = 'Phone' THEN 1 ELSE 0 END) AS PhoneInvites,		-- V1.10
			
			SUM(ISNULL(B.[SoftBounce], 0))	AS SoftBounce, -- V1.16
			SUM(ISNULL(B.HardBounce, 0))	AS HardBounce, -- V1.16
			SUM(ISNULL(B.Unsubscribes, 0))	AS Unsubscribes, -- V1.16
			SUM(ISNULL(B.SuppliedPhoneNumber, 0))	AS SuppliedPhoneNumber, -- V1.16
			SUM(ISNULL(B.SuppliedMobilePhone, 0))	AS SuppliedMobilePhone, -- V1.16
			SUM(ISNULL(B.PrevSoftBounce, 0))	AS PrevSoftBounce, -- V1.17
			SUM(ISNULL(B.PrevHardBounce, 0))	AS PrevHardBounce, -- V1.17
			
			SUM(ISNULL(B.OriginalPartySuppression, 0))	AS OriginalPartySuppression, -- V1.27
			SUM(ISNULL(B.OriginalPostalSuppression, 0)) AS OriginalPostalSuppression, -- V1.27
			SUM(ISNULL(B.OriginalEmailSuppression, 0))	AS OriginalEmailSuppression, -- V1.27
			SUM(ISNULL(B.OriginalPhoneSuppression, 0))	AS OriginalPhoneSuppression -- V1.27
			
			
			
			
	FROM SampleReport.Base B
	WHERE FileActionDate >= @StartDate AND FileActionDate < @EndDate 
	GROUP BY B.SuperNationalRegion ,
			B.BusinessRegion,			--v1.7
			B.Market,
			B.SubNationalTerritory,		
			B.SubNationalRegion,
			B.DealerCode, 
			B.DealerCodeGDD,
			B.DealerName

	--SELECT * FROM SampleReport.SummaryDealerRegion	



	------------------------------------------------------------------------------
	INSERT INTO SampleReport.SummaryDealerGroup
	SELECT	CombinedDealer ,
			DealerCode, 
			DealerCodeGDD, 
			DealerName,
			--SUM()		AS RecordsInFile,			
			COUNT(*)						AS RecordsLoaded,
			SUM(ISNULL(SuppliedEmail, 0))	AS SuppliedEmail,
			SUM(ISNULL(UsableFlag, 0))		AS UsableRecords,
			SUM(ISNULL(SentFlag, 0))		AS InvitesSent,
			SUM(ISNULL(BouncebackFlag, 0))	AS Bouncebacks,
			SUM(ISNULL(RespondedFlag, 0))	AS Responded ,
			SUM(CASE WHEN CaseOutputType = 'Online' THEN 1 ELSE 0 END) AS EmailInvites,
			SUM(CASE WHEN CaseOutputType = 'SMS'    THEN 1 ELSE 0 END) AS SMSInvites,
			SUM(CASE WHEN CaseOutputType = 'Postal' THEN 1 ELSE 0 END) AS PostalInvites,
			SUM(CASE WHEN CaseOutputType = 'Phone' THEN 1 ELSE 0 END) AS PhoneInvites,		-- V1.10
			
			SUM(ISNULL([SoftBounce], 0))	AS SoftBounce, -- V1.16
			SUM(ISNULL(HardBounce, 0))	AS HardBounce, -- V1.16
			SUM(ISNULL(Unsubscribes, 0))	AS Unsubscribes, -- V1.16
			SUM(ISNULL(SuppliedPhoneNumber, 0))	AS SuppliedPhoneNumber, -- V1.16
			SUM(ISNULL(SuppliedMobilePhone, 0))	AS SuppliedMobilePhone, -- V1.16
			SUM(ISNULL(PrevSoftBounce, 0))	AS PrevSoftBounce, -- V1.17
			SUM(ISNULL(PrevHardBounce, 0))	AS PrevHardBounce -- V1.17
			
	FROM SampleReport.Base
	WHERE FileActionDate >= @StartDate AND FileActionDate < @EndDate 
	GROUP BY CombinedDealer ,
			DealerCode, 
			DealerCodeGDD, 
			DealerName




	------------------------------------------------------------------------------------------------
	--
	--  UPDATE GLOBAL SAMPLE REPORT AGGREGATE TABLES 
	--
	------------------------------------------------------------------------------------------------
	
	DECLARE @UpdatedAt	DATETIME
	
	SET @ReportDate = @EndDate
	SET @UpdatedAt = getDate()


	----------------------------------------------------------------------
	-- Add the DealerRegion records into the aggregate table 
	----------------------------------------------------------------------
	
	IF (@EchoFeed <> 1 AND @DailyEcho <> 1)		-- V1.9 Do not update Global Reports in Echo Feed, V1.24
	BEGIN

		
		--- First check for and remove, any pre-existing records for this date/BMQ combination.
		IF EXISTS (
			SELECT TOP 1 ReportYear FROM SampleReport.GlobalReportDealerRegionAggregate
			WHERE ReportYear = Year(@ReportDate)
				AND ReportMonth = Month(@ReportDate)
				AND SummaryType = @TimePeriod
				AND Brand = @Brand
				AND Market = CASE @ReportType							-- V1.8 New Market Filter
					WHEN 'Market' THEN @MarketRegion ELSE Market END
				AND BusinessRegion = CASE @ReportType							-- V1.8 New Region Filter
					WHEN 'Region' THEN @MarketRegion ELSE BusinessRegion END
				AND Questionnaire = @Questionnaire 
				) 
		BEGIN 
			DELETE FROM SampleReport.GlobalReportDealerRegionAggregate	
			WHERE ReportYear = Year(@ReportDate)
				AND ReportMonth = Month(@ReportDate)
				AND SummaryType = @TimePeriod
				AND Brand = @Brand
				AND Market = CASE @ReportType							-- V1.8 New Market Filter
					WHEN 'Market' THEN @MarketRegion ELSE Market END
				AND BusinessRegion = CASE @ReportType							-- V1.8 New Region Filter
					WHEN 'Region' THEN @MarketRegion ELSE BusinessRegion END
				AND Questionnaire = @Questionnaire 	
		END 
		
		-- Now add the DealerRegion records into the aggregate table 
		INSERT INTO SampleReport.GlobalReportDealerRegionAggregate	(ReportYear, ReportMonth, SummaryType, Brand, Market, Questionnaire, UpdatedTime, SuperNationalRegion, BusinessRegion, SubNationalTerritory, SubNationalRegion, DealerCode, DealerCodeGDD, DealerName, RecordsLoaded, SuppliedEmail, UsableRecords, InvitesSent, Bouncebacks, Responded, EmailInvites, SMSInvites, PostalInvites, PhoneInvites, SoftBounce, HardBounce)
		
		SELECT	Year(@ReportDate),
				Month(@ReportDate),
				@TimePeriod,
				@Brand,
				--@Market,
				ISNULL(R.Market, '') AS Market,								-- V1.8 Use Market from Dealer Specific 
				@Questionnaire,
				@UpdatedAt,
				ISNULL(B.SuperNationalRegion, '') AS SuperNationalRegion,   -- Key field cannot be NULL
				ISNULL(B.BusinessRegion, '') AS BusinessRegion,				-- Key field cannot be NULL		-- v1.7
				ISNULL(R.SubNationalTerritory, '') AS SubNationalTerritory,	-- Key field cannot be NULL		-- v1.12
				ISNULL(R.SubNationalRegion, '') AS SubNationalRegion,		-- Key field cannot be NULL
				ISNULL(R.DealerCode, '') AS DealerCode,						-- Key field cannot be NULL
				ISNULL(R.DealerCodeGDD, '') AS DealerCodeGDD,				-- Key field cannot be NULL
				ISNULL(R.DealerName, '') AS DealerName,						-- Key field cannot be NULL  
				R.RecordsLoaded, 
				R.SuppliedEmail, 
				R.UsableRecords, 
				R.InvitesSent, 
				R.Bouncebacks, 
				R.Responded, 
				R.EmailInvites, 
				R.SMSInvites, 
				R.PostalInvites,
				R.PhoneInvites,				-- V1.10
				R.SoftBounce,				-- V1.20
				R.HardBounce				-- V1.20
		FROM SampleReport.SummaryDealerRegion R
		LEFT JOIN SampleReport.BMQSpecificInformation B 
					ON B.Brand = @brand
					AND B.Market = CASE @ReportType									-- V1.8 New Market Filter
						WHEN 'Market' THEN @MarketRegion ELSE R.Market END
					AND B.BusinessRegion = CASE @ReportType							-- V1.8 New Region Filter
						WHEN 'Region' THEN @MarketRegion ELSE R.BusinessRegion END
					AND B.Questionnaire = @Questionnaire
					
					
					
		------------------------------------------------------------------------------------------------
		-- Add the Global Summary sheet data  (Not dealer specific)
		------------------------------------------------------------------------------------------------

		--- First check for and remove, any pre-existing record for this date/BMQ combination.
		IF EXISTS (
			SELECT TOP 1 ReportYear FROM SampleReport.GlobalReportSummary
			WHERE ReportYear = Year(@ReportDate)
				AND ReportMonth = Month(@ReportDate)
				AND SummaryType = @TimePeriod
				AND Brand = @Brand
				AND Market = CASE @ReportType									-- V1.8 New Market Filter
					WHEN 'Market' THEN @MarketRegion ELSE Market END
				AND BusinessRegion = CASE @ReportType							-- V1.8 New Region Filter
					WHEN 'Region' THEN @MarketRegion ELSE BusinessRegion END
				AND Questionnaire = @Questionnaire
				) 
		BEGIN 
			DELETE FROM SampleReport.GlobalReportSummary
			WHERE ReportYear = Year(@ReportDate)
				AND ReportMonth = Month(@ReportDate)
				AND SummaryType = @TimePeriod
				AND Brand = @Brand
				AND Market = CASE @ReportType									-- V1.8 New Market Filter
					WHEN 'Market' THEN @MarketRegion ELSE Market END
				AND BusinessRegion = CASE @ReportType							-- V1.8 New Region Filter
					WHEN 'Region' THEN @MarketRegion ELSE BusinessRegion END
				AND Questionnaire = @Questionnaire 	
		END 

		-- Now add the Global Summary row  --------------
		;WITH CTE_Totals
		AS (	
				SELECT
					R.Market,									--V1.8 Group by Market
					SUM(R.RecordsLoaded)	AS RecordsLoaded, 
					SUM(R.SuppliedEmail)	AS SuppliedEmail, 
					SUM(R.UsableRecords)	AS UsableRecords, 
					SUM(R.InvitesSent)		AS InvitesSent, 
					SUM(R.Bouncebacks)		AS Bouncebacks, 
					SUM(R.Responded)		AS Responded, 
					SUM(R.EmailInvites)		AS EmailInvites, 
					SUM(R.SMSInvites)		AS SMSInvites, 
					SUM(R.PostalInvites)	AS PostalInvites,
					SUM(R.PhoneInvites)		AS PhoneInvites,		--V1.10
					SUM(R.SoftBounce)       AS SoftBounce,		    -- V1.20
				    SUM(R.HardBounce)       AS HardBounce			-- V1.20
				FROM SampleReport.SummaryDealerRegion R	
				GROUP BY R.Market								--V1.8 Group by Market
		)				
		INSERT INTO SampleReport.GlobalReportSummary  (ReportYear, ReportMonth, SummaryType, Brand, Market, Questionnaire, UpdatedTime, RecordsLoaded, SuppliedEmail, UsableRecords, InvitesSent, Bouncebacks, Responded, EmailInvites, SMSInvites, PostalInvites, PhoneInvites, SuperNationalRegion, BusinessRegion, FeedType, [10YrVehicleParc], SoftBounce, HardBounce)
		SELECT		Year(@ReportDate),
					Month(@ReportDate),
					@TimePeriod,
					@Brand,
					T.Market,									--V1.8
					@Questionnaire,
					@UpdatedAt,
					
					T.RecordsLoaded, 
					T.SuppliedEmail, 
					T.UsableRecords, 
					T.InvitesSent, 
					T.Bouncebacks, 
					T.Responded, 
					T.EmailInvites, 
					T.SMSInvites, 
					T.PostalInvites,
					T.PhoneInvites,				-- V1.10

					ISNULL(B.SuperNationalRegion, '')	AS SuperNationalRegion,
					ISNULL(B.BusinessRegion, '')		AS BusinessRegion,				--v1.7
					ISNULL(B.FeedType, '')				AS FeedType,
					ISNULL(B.[10YrVehicleParc], '')		AS [10YrVehicleParc],
					
					T.SoftBounce,				-- V1.20
				    T.HardBounce				-- V1.20
					
			FROM CTE_Totals T
			LEFT JOIN SampleReport.BMQSpecificInformation B 
						ON B.Brand = @Brand
						AND B.Market = T.Market											--V1.8 Join on Market
						AND B.Questionnaire = @Questionnaire

	END


	------------------------------------------------------------------------------------------------
	--
	--  BUILD FILE SUMMARY TABLE
	--
	------------------------------------------------------------------------------------------------

	IF (OBJECT_ID('tempdb..#FilesSummary') IS NOT NULL)
	BEGIN
		DROP TABLE #FilesSummary
	END

	CREATE TABLE #FilesSummary
		(
			Brand nvarchar(510),
			Market varchar (200) ,
			Region varchar(200),
			Questionnaire varchar(255),
			AuditID bigint ,
			[FileName] varchar(100),
			FileRowCount int ,
			ActionDate datetime2(7),
			RecordsLoaded int 
		)
			
	INSERT INTO #FilesSummary
	SELECT	B.Brand,
			B.Market,
			B.BusinessRegion,
			B.Questionnaire,
			B.AuditID,
			B.FileName ,
			B.FileRowCount,
			F.ActionDate  ,
			COUNT(*) AS RecordsLoaded
	FROM SampleReport.Base B
	INNER JOIN [$(AuditDB)].dbo.Files F ON F.AuditID = B.AuditID 
	WHERE F.ActionDate >= @StartDate AND F.ActionDate < @EndDate 
	GROUP BY B.Brand,
			B.Market,
			B.BusinessRegion,
			B.Questionnaire,
			B.AuditID,
			B.FileName ,
			B.FileRowCount,
			F.ActionDate  
	
	
	-- ADD REGION TO SampleFilesSchedule TABLE
	IF (OBJECT_ID('tempdb..#SampleFilesSchedule') IS NOT NULL)
	BEGIN
		DROP TABLE #SampleFilesSchedule
	END

	CREATE TABLE #SampleFilesSchedule
		(
			Brand nvarchar(510),
			Market varchar (200) ,
			Questionnaire varchar(255),
			[FileName] varchar(100),
			DueDate datetime2(7),
			Region varchar(200)
		)
		
	INSERT INTO #SampleFilesSchedule
	SELECT Brand, M.Market, Questionnaire, FileName, DueDate, R.Region
	FROM SampleReport.SampleFilesSchedule 
		INNER JOIN [$(SampleDB)].dbo.Markets M ON SampleReport.SampleFilesSchedule.Market = M.Market
		INNER JOIN [$(SampleDB)].dbo.Regions R ON M.RegionID = R.RegionID

	INSERT INTO SampleReport.SummaryFiles (Market, ScheduledFiles, ReceivedFiles, ActionDate, DueDate, FileRowCount, RecordsLoaded, DaysLate)
	
	SELECT  --COALESCE(FS.FileName, SFS.FileName) AS FileName,
			FS.Market,												-- V1.8 Add Market
			SFS.FileName  AS ScheduledFiles,
			FS.FileName   AS ReceivedFiles,
			FS.ActionDate, 
			SFS.DueDate,
			FS.FileRowCount, 
			FS.RecordsLoaded, 
			CASE WHEN FS.ActionDate IS NOT NULL AND SFS.DueDate IS NOT NULL 
				 THEN DATEDIFF(DAY, DueDate, ActionDate)
				 ELSE NULL END AS DaysLate
	FROM #FilesSummary FS
	FULL OUTER JOIN #SampleFilesSchedule SFS 
						ON SFS.Brand = FS.Brand 
						AND SFS.Market = FS.Market
						AND SFS.Questionnaire = FS.Questionnaire 
						AND SFS.FileName = FS.FileName 
	WHERE (SFS.Brand = @Brand 
		AND SFS.Market = CASE @ReportType							-- V1.8 New Market Filter
			WHEN 'Market' THEN @MarketRegion ELSE SFS.Market END
		AND SFS.Region = CASE @ReportType							-- V1.8 New Region Filter
			WHEN 'Region' THEN @MarketRegion ELSE SFS.Region END
		AND SFS.Questionnaire = @Questionnaire
		AND SFS.DueDate >= @StartDate AND SFS.DueDate < @EndDate 
			)
		OR SFS.FileName is NULL
		OR FS.FileName IS NOT NULL
	ORDER BY COALESCE(FS.ActionDate, SFS.DueDate)



	------------------------------------------------------------------------------------------------
	--
	--  BUILD REPORT HEADER TABLE
	--
	------------------------------------------------------------------------------------------------

	--DECLARE @ReceivedFiles int,
	--		@LateFiles	int,
	--		@RecordsReceived int

	--SELECT  @ReceivedFiles = COUNT(*) ,
	--		@LateFiles = SUM(CASE WHEN ISNULL(DaysLate, 1) > 0 THEN 1 ELSE 0 END)
	--FROM SampleReport.SummaryFiles
	--WHERE ReceivedFiles IS NOT NULL
			
	--SELECT @RecordsReceived = COUNT(*)
	--FROM SampleReport.IndividualRows 

	--V1.8 Change query used to build Summary Header to split by Market 
	INSERT INTO SampleReport.SummaryHeader (Brand, Market, Questionnaire, ReportDate, StartDate, EndDate, Receivedfiles, LateFiles)
	SELECT	@Brand AS Brand,
			SF.Market,
			@Questionnaire AS Questionnaire,
			@ReportDate  AS ReportDate,
			@StartDate AS StartDate,
			DATEADD(day, -1, @EndDate) AS EndDate,
			COUNT(*) AS ReceivedFiles,
			SUM(CASE WHEN ISNULL(DaysLate, 1) > 0 THEN 1 ELSE 0 END) AS LateFiles
	FROM SampleReport.SummaryFiles SF
	WHERE ReceivedFiles IS NOT NULL
	GROUP BY SF.Market

	UPDATE SH 
	SET SH.RecordsReceived = 
	(SELECT COUNT(*) FROM SampleReport.IndividualRows IR WHERE IR.Market = SH.Market)
	FROM SampleReport.SummaryHeader SH

--V1.34
END
ELSE
	BEGIN

		TRUNCATE TABLE SampleReport.IndividualRows;
		
		INSERT INTO SampleReport.IndividualRows 
				(SuperNationalRegion, BusinessRegion, DealerMarket, SubNationalTerritory, SubNationalRegion, CombinedDealer, DealerName, DealerCode, DealerCodeGDD, FullName, OrganisationName, AnonymityDealer, AnonymityManufacturer, CaseCreationDate, CaseStatusType, CaseOutputType, SentFlag, SentDate, RespondedFlag, ClosureDate, DuplicateRowFlag, BouncebackFlag, UsableFlag, ManualRejectionFlag, FileName, FileActionDate, FileRowCount, LoadedDate, AuditID, AuditItemID, MatchedODSPartyID, MatchedODSPersonID, LanguageID, PartySuppression, MatchedODSOrganisationID, MatchedODSAddressID, CountryID, PostalSuppression, EmailSuppression, MatchedODSVehicleID, ODSRegistrationID, MatchedODSModelID, OwnershipCycle, MatchedODSEventID, ODSEventTypeID, WarrantyID, Brand, Market, Questionnaire, QuestionnaireRequirementID, SuppliedName, SuppliedAddress, SuppliedPhoneNumber, SuppliedMobilePhone, SuppliedEmail, SuppliedVehicle, SuppliedRegistration, SuppliedEventDate, EventDateOutOfDate, EventNonSolicitation, PartyNonSolicitation, UnmatchedModel, UncodedDealer, EventAlreadySelected, NonLatestEvent, InvalidOwnershipCycle, RecontactPeriod, RelativeRecontactPeriod, InvalidVehicleRole, CrossBorderAddress, CrossBorderDealer, ExclusionListMatch, InvalidEmailAddress, BarredEmailAddress, BarredDomain, CaseID, SampleRowProcessed, SampleRowProcessedDate, WrongEventType, MissingStreet, MissingPostcode, MissingEmail, MissingTelephone, MissingStreetAndEmail, MissingTelephoneAndEmail, MissingMobilePhone, MissingMobilePhoneAndEmail, MissingPartyName, MissingLanguage, InvalidModel, InvalidManufacturer, InternalDealer, RegistrationNumber, RegistrationDate, VIN, OutputFileModelDescription, EventDate, SampleEmailAddress, CaseEmailAddress, PreviousEventBounceBack, EventDateTooYoung, AFRLCode, DealerExclusionListMatch, PhoneSuppression, SalesType, InvalidAFRLCode, InvalidSalesType, AgentCodeFlag, DedupeEqualToEvents,HardBounce,SoftBounce,Unsubscribes, DateOfLeadCreation, PrevSoftBounce, PrevHardBounce,ServiceTechnicianID,ServiceTechnicianName,ServiceAdvisorName,ServiceAdvisorID,CRMSalesmanName,CRMSalesmanCode, FOBCode, ContactPreferencesSuppression, ContactPreferencesPartySuppress, ContactPreferencesEmailSuppress, ContactPreferencesPhoneSuppress, ContactPreferencesPostalSuppress, SVCRMSalesType, SVCRMInvalidSalesType, DealNumber, RepairOrderNumber, VistaCommonOrderNumber, SalesEmployeeCode, SalesEmployeeName, ServiceEmployeeCode, ServiceEmployeeName, RecordChanged, PDIFlagSet, OriginalPartySuppression, OriginalPostalSuppression, OriginalEmailSuppression, OriginalPhoneSuppression, OtherExclusion, OverrideFlag, GDPRflag, SelectionPostalID, SelectionEmailID, SelectionPhoneID, SelectionLandlineID, SelectionMobileID, SelectionEmail, SelectionPhone, SelectionLandline, SelectionMobile, ContactPreferencesModel,ContactPreferencesPersist, InvalidDateOfLastContact, MatchedODSPrivEmailAddressID, SamplePrivEmailAddress, EmailExcludeBarred,EmailExcludeGeneric, EmailExcludeInvalid, CompanyExcludeBodyShop, CompanyExcludeLeasing, CompanyExcludeFleet, CompanyExcludeBarredCo, OutletPartyID, Dealer10DigitCode, OutletFunction, RoadsideAssistanceProvider, CRC_Owner, ClosedBy, Owner, CountryIsoAlpha2, CRCMarketCode, InvalidDealerBrand, SubBrand, ModelCode, LeadVehSaleType, ModelVariant)  --V1.12 'AgentCodeFlag' added, V1.13 DedupeEqualToEvents added, V1.14 HardBounce,SoftBounce,Unsubscribes added, V1.15 - DateOfLeadCreation added, V1.17, V1.18, V1.19, V1.21, V1.22, V1.23, V1.25, v1.26, V1.27, V1.30, V1.31, V1.32, V1.33, V1.37,V1.39, V1.40, V1.41, V1.42, V1.43
		SELECT   SuperNationalRegion, BusinessRegion, DealerMarket, SubNationalTerritory, SubNationalRegion, CombinedDealer, DealerName, DealerCode, DealerCodeGDD, FullName, OrganisationName, AnonymityDealer, AnonymityManufacturer, CaseCreationDate, CaseStatusType, CaseOutputType, SentFlag, SentDate, RespondedFlag, ClosureDate, DuplicateRowFlag, BouncebackFlag, UsableFlag, ManualRejectionFlag, FileName, FileActionDate, FileRowCount, LoadedDate, AuditID, AuditItemID, MatchedODSPartyID, MatchedODSPersonID, LanguageID, PartySuppression, MatchedODSOrganisationID, MatchedODSAddressID, CountryID, PostalSuppression, EmailSuppression, MatchedODSVehicleID, ODSRegistrationID, MatchedODSModelID, OwnershipCycle, MatchedODSEventID, ODSEventTypeID, WarrantyID, Brand, Market, Questionnaire, QuestionnaireRequirementID, SuppliedName, SuppliedAddress, SuppliedPhoneNumber, SuppliedMobilePhone, SuppliedEmail, SuppliedVehicle, SuppliedRegistration, SuppliedEventDate, EventDateOutOfDate, EventNonSolicitation, PartyNonSolicitation, UnmatchedModel, UncodedDealer, EventAlreadySelected, NonLatestEvent, InvalidOwnershipCycle, RecontactPeriod, RelativeRecontactPeriod, InvalidVehicleRole, CrossBorderAddress, CrossBorderDealer, ExclusionListMatch, InvalidEmailAddress, BarredEmailAddress, BarredDomain, CaseID, SampleRowProcessed, SampleRowProcessedDate, WrongEventType, MissingStreet, MissingPostcode, MissingEmail, MissingTelephone, MissingStreetAndEmail, MissingTelephoneAndEmail, MissingMobilePhone, MissingMobilePhoneAndEmail, MissingPartyName, MissingLanguage, InvalidModel, InvalidManufacturer, InternalDealer, RegistrationNumber, RegistrationDate, VIN, OutputFileModelDescription, EventDate, SampleEmailAddress, CaseEmailAddress, PreviousEventBounceBack, EventDateTooYoung, AFRLCode, DealerExclusionListMatch, PhoneSuppression, SalesType, InvalidAFRLCode, InvalidSalesType, AgentCodeFlag, DedupeEqualToEvents,HardBounce,[SoftBounce],Unsubscribes, DateOfLeadCreation, PrevSoftBounce, PrevHardBounce,ServiceTechnicianID,ServiceTechnicianName,ServiceAdvisorName,ServiceAdvisorID,CRMSalesmanName,CRMSalesmanCode, FOBCode, ContactPreferencesSuppression, ContactPreferencesPartySuppress, ContactPreferencesEmailSuppress, ContactPreferencesPhoneSuppress, ContactPreferencesPostalSuppress, SVCRMSalesType, SVCRMInvalidSalesType, DealNumber, RepairOrderNumber, VistaCommonOrderNumber, SalesEmployeeCode, SalesEmployeeName, ServiceEmployeeCode, ServiceEmployeeName, RecordChanged, PDIFlagSet, OriginalPartySuppression, OriginalPostalSuppression, OriginalEmailSuppression, OriginalPhoneSuppression, OtherExclusion, OverrideFlag, GDPRflag, SelectionPostalID, SelectionEmailID, SelectionPhoneID, SelectionLandlineID, SelectionMobileID, SelectionEmail, SelectionPhone, SelectionLandline, SelectionMobile, ContactPreferencesModel,ContactPreferencesPersist, InvalidDateOfLastContact, MatchedODSPrivEmailAddressID, SamplePrivEmailAddress, EmailExcludeBarred,EmailExcludeGeneric, EmailExcludeInvalid, CompanyExcludeBodyShop, CompanyExcludeLeasing, CompanyExcludeFleet, CompanyExcludeBarredCo, OutletPartyID, Dealer10DigitCode, OutletFunction, RoadsideAssistanceProvider, CRC_Owner, ClosedBy, Owner, CountryIsoAlpha2, CRCMarketCode, InvalidDealerBrand, SubBrand, ModelCode, LeadVehSaleType, ModelVariant   --V1.12 'AgentCodeFlag' added, V1.13 DedupeEqualToEvents added, V1.14 HardBounce,SoftBounce,Unsubscribes added, V1.15 - DateOfLeadCreation added, V1.17, V1.18, V1.19, V1.21, V1.22, V1.23, V1.25, v1.26, V1.27, V1.30, V1.31, V1.32, V1.33, V1.37, V1.39, V1.40, V1.41, V1.42, V1.43
		FROM SampleReport.Base
	END 


END TRY
BEGIN CATCH

	SELECT
		 @ErrorNumber = Error_Number()
		,@ErrorSeverity = Error_Severity()
		,@ErrorState = Error_State()
		,@ErrorLocation = Error_Procedure()
		,@ErrorLine = Error_Line()
		,@ErrorMessage = Error_Message()

	EXEC [$(ErrorDB)].dbo.uspLogDatabaseError
		 @ErrorNumber
		,@ErrorSeverity
		,@ErrorState
		,@ErrorLocation
		,@ErrorLine
		,@ErrorMessage
		
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH