
CREATE PROCEDURE [SampleReport].[uspPopulateReportTablesDistinctEvents]
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
	Purpose:	Builds the reporting tables from the .Base table (of distinct events) for the time period specified.
				A modified copy of the sample report proc version uspPopulateReportTables
		
	Version			Date				Developer			Comment
	1.0				19/11/2013			Martin Riverol		Created
	1.1				27/01/2014			Chris Ross			9751 -  Add in columns: SuppliedMobilePhone, MissingMobilePhone, MissingMobilePhoneAndEmail, 
																	CaseOutputType. And totals: EmailInvites, SMSInvites, PostalInvites, SampleEmailAddress, CaseEmailAddress
	1.2				28/02/2014			Chris Ross			9751 - Additional columns requested for SummaryDealerRegionEventsUsable table
	1.3				27/03/2014			Ali Yuksel			9751 - 'OTHER' Reason for non usable flag fixed
	1.4				04/04/2014			Chris Ross			9998 - Add in transfer of Dealer Region data into Global Summary aggregate tables
	1.5				03/06/2014			Ali Yuksel			10420 - Global Dealer Database dealer code added (DealerCodeGDD)
	1.6				16/12/2014			Eddie Thomas		11047 - Add PreviousEventBounceBack and EventDateTooYoung flags
	1.7				26/02/2015			Chris Ross			BUG 11026 - Add in BusinessRegion column
	1.8				17/07/2015			Chris Ledger		BUG 11658 - Addition of Roadside (major change for regions)
	1.9				28/02/2016			Chris Ledger		BUG 12377 - Do not update global aggregate tables for Echo feeds 
	1.10			29/02/2016			Chris Ledger		BUG 12395 - Sample Reports Amendments 
	1.11			22/04/2016			Chris Ledger		Change Echo @StartYearDate to only show this year's data
	1.12			11/07/2016			Eddie Thomas		BUG 12811 - Monthly Response Report
	1.13            19/07/2016			Ben King			BUG 12853 - CRC sample reporting raw files
	1.14			18/10/2016			Chris Ross			BUG 13171 - Add in SubNationalTerritory column
	1.15			15/11/2016			Ben King			BUG 13314 - Add HardBounce, SoftBounce, Unsubscribes
	1.16			23/11/2016			Chris Ross			BUG	13344 - Add new in column DateOfLeadCreation to IndividualRowsEvents table
	1.17			23/11/2016			Ben King			BUG 13329 - Add HardBounce, SoftBounce, Unsubscribes, SuppliedPhoneNumber, SuppliedMobilePhone to Tab Summary_DealerRegion & Summary_DealerGroup in SampleReports.xls
	1.18			24/11/2016			Ben King			BUG	13358 - Add PrevHardBounce, PrevSoftBounce - to Echo files, individual tab & Summary_DealerRegion & Summary_DealerGroup in SampleReports.xls
	1.19			25/11/2016			Ben King			BUG 13358 - Add EventDrivenPrevSoftBounce, EventDrivenPrevHardBounce, EventDrivenSoftBounce, EventDrivenHardBounce, EventDrivenUnsubscribes to SummaryDealerRegionEventsUsable
	1.20			01/02/2017			Ben King			BUG 13546 - Add US Employee Fields to Echo reports
	1.21			23/03/2017			Ben King			BUG 13465 - Add FOBCode to Echo & SampleReports (individual Sheet)
	1.22			19/04/2017			Ben KIng			BUG 13817 - Add HardBounce & SoftBounce fields to Global Reports
	1.23			25/04/2017			Chris Ross			BUG 13364 - Add in Customer Preference columns
	1.24		    17/05/2017			Ben King			BUG 13933 & 13884 - Add fields SVCRMSalesType, SVCRMInvalidSalesType, DealNumber, RepairOrderNumber, VistaCommonOrderNumber	
	1.25			24/05/2017			Ben King			BUG 13950 - Echo reporting change - employee reporting for generic roles
	1.26			30/05/2017			Ben King			BUG 13942 - Echo Sample Reporting on a Daily Basis
	1.27			20/06/2017          Ben King			BUG 14033 - Add Field RecordChanged to Echo output
	1.28			16/08/2017			Ben King			BUG 14177 - InvalidOwnershipCycle fix in Dealer sheet
	1.29			07/09/2017			Chris Ross			BUG 14122 - Add in PDIFlagSet and EventDrivenPDIFlagSet columns
														+	BUG 13364 - Add in EventDrivenContactPreferencesSuppression columns
	1.30			14/11/2017			Ben King			BUG 14379 - New Suppression Logic_for Sample Reporting Purposes
	1.31		    11/01/2018			Ben King			BUG 14488 - 90 day response capture into 2018
	1.32		    19/01/2018			Ben King			BUG 14487 - Sample Reporting _Other column
	1.33			14/03/2018			Ben King			BUG 14486 - Customer Preference Override Flag
	1.34			01/05/2018			Ben King			BUG 14669 - GDPR New Flag_ Sample Reporting
	1.35			05/10/2018			Ben King			BUG 15017 - Add ContactMechanismID's
	1.36			17/12/2018			Ben King			BUG 15125 - Add contact prefernces model fields.
	1.37			28/01/2019			Ben King			BUG 15227 - 12 month Static rolling extract report
	1.38			05/02/2019			Ben King			BUG 15211 - add EventDrivenNoSuppliedEmail
	1.39			15/02/2019			Ben King			BUG add new exclusion flag InvalidDateOfLastContact to echo/sample reports
	1.40			15/02/2019			Ben King			BUG 15211 - add MatchedODSPrivEmailAddressID
	1.41			03/01/2020			Ben King			BUG 16864 - Add exclusion category flags
	1.42			01/04/2020			Chris Ledger		BUG 15372 - Fix hard coded database references and cases
	1.43			01/01/2021			Ben King			BUG 18093 - add 10digit code (plus other fields)
	1.44			10/06/2021			Ben King			TASK 474 - Japan Purchase - Mismatch between Dealer and VIN
	1.45			30/09/2022			Eddie Thomas		TASK 1017 - SubBrand
	1.46			05/10/2022			Eddie Thomas		TASK 926 - Add ModelCode
	1.47			14/10/2022			Eddie Thomas		TASK 1064 - Adding LeadVehSaleType & ModelVariant
*/


	-- TEST PARAMETERS
	--DECLARE @MarketRegion VARCHAR (200) = 'MENA'
	--DECLARE @ReportType VARCHAR(200) = 'Region'
	--DECLARE @TimePeriod CHAR(20) = 'YTD'
	--DECLARE @EchoFeed BIT = 0

--V1.37 IF 12 MONTH REPORT RUN, SKIP BULK PROCESSING
IF  @EchoFeed12mthRolling <> 1
  BEGIN

	------------------------------------------------------------------------------------------------------
	-- Clear down tables  (Do first to ensure tables empty if we quit out due being something being invalid)
	------------------------------------------------------------------------------------------------------

	TRUNCATE TABLE SampleReport.IndividualRowsEvents
	TRUNCATE TABLE SampleReport.SummaryDealerGroupEvents
	TRUNCATE TABLE SampleReport.SummaryDealerRegionEvents
	TRUNCATE TABLE SampleReport.SummaryFilesEvents
	TRUNCATE TABLE SampleReport.SummaryHeaderEvents
	TRUNCATE TABLE SampleReport.SummaryDealerRegionEventsUsable

	------------------------------------------------------------------------------------------------------
	-- Check whether Time Period active and set report variables
	------------------------------------------------------------------------------------------------------

	DECLARE @Brand	NVARCHAR(510), 
			@Questionnaire VARCHAR(255), 
			@ReportDate DATETIME,
			@TimePeriodDescription  VARCHAR(200),
			@ActiveFag int
			

	SELECT  @TimePeriodDescription	= TimePeriodDescription, 
			@ActiveFag				= ActiveFlag
	FROM SampleReport.TimePeriods 

	-- Quit out if this time period is not active
	IF ISNULL(@ActiveFag, 0) = 0
	RETURN 0


	-- Set remaining param's 
	SELECT TOP 1 @Brand			= Brand FROM SampleReport.Base 
	--SELECT TOP 1 @Market		= Market FROM SampleReport.Base			--V1.8 Retrieve Market/Region from Parameter
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

	IF @EchoFeed = 1										-- V1.10 ADD IN ECHO FEED
		-- Echo reports used to need to show previous year's data (removed but leave in old code in case need to rerun) V1.17
		BEGIN
			SELECT  @LastMonthDate = DATEADD(dd, 0,DATEDIFF(dd, 0,DATEADD(m, -3, @ReportDate))); --V1.31 (Jan,Feb,March also refer to entire previous years data 
																					             --       when YTD run, April forward only pools current year)
			--SELECT @StartYearDate =DATEADD (YEAR, DATEDIFF(YEAR, 0, @ReportDate)-1, 0)
			SELECT @StartYearDate = CONVERT(DATETIME, CONVERT(VARCHAR(8), DATEPART(YEAR, @LastMonthDate)) + '0101') --First day of the year
		END
	ELSE
		BEGIN
			SELECT @StartYearDate = CONVERT(DATETIME, CONVERT(VARCHAR(8), DATEPART(YEAR, @LastMonthDate)) + '0101') --First day of the year
		END

	--SELECT @StartYearDate = convert(datetime, convert(varchar(8), DATEPART(YEAR, @LastMonthDate)) + '0101') --First day of the year


	IF (@EchoFeed = 1 OR @DailyEcho = 1)  --V1.4, V1.26
		SELECT @EndDate = DATEADD(DD, 0, DATEDIFF(dd, 0, @ReportDate) + 1)
	ELSE
		SELECT @EndDate = DATEADD(dd,-(DAY(DATEADD(mm,1,@LastMonthDate))-1),DATEADD(mm,1,@LastMonthDate)) --First Day of Next Month
	
	--select @LastMonthDate , @StartMonthDate ,@LastQuarterDate , @StartQuarterDate , @StartYearDate, @EndDate

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
	ELSE IF @TimePeriod = '24H'   --V1.26 - Base data will only contain last 24 hours data + records that have changed since Monday on DailyEcho run.
		SET @StartDate = @StartYearDate
	ELSE RETURN 0			--- <<<<<<< If unrecognised param then stop processing




	------------------------------------------------------------------------------------------------
	--
	-- OUTPUT TO MAIN INDIVIDUAL DETAIL TABLE
	--
	------------------------------------------------------------------------------------------------

	INSERT INTO SampleReport.IndividualRowsEvents 
			(SuperNationalRegion, BusinessRegion, DealerMarket, SubNationalTerritory, SubNationalRegion, CombinedDealer, DealerName, DealerCode, DealerCodeGDD, FullName, OrganisationName, AnonymityDealer, AnonymityManufacturer, CaseCreationDate, CaseStatusType, CaseOutputType, SentFlag, SentDate, RespondedFlag, ClosureDate, DuplicateRowFlag, BouncebackFlag, UsableFlag, ManualRejectionFlag, FileName, FileActionDate, FileRowCount, LoadedDate, AuditID, AuditItemID, MatchedODSPartyID, MatchedODSPersonID, LanguageID, PartySuppression, MatchedODSOrganisationID, MatchedODSAddressID, CountryID, PostalSuppression, EmailSuppression, MatchedODSVehicleID, ODSRegistrationID, MatchedODSModelID, OwnershipCycle, MatchedODSEventID, ODSEventTypeID, WarrantyID, Brand, Market, Questionnaire, QuestionnaireRequirementID, SuppliedName, SuppliedAddress, SuppliedPhoneNumber, SuppliedMobilePhone, SuppliedEmail, SuppliedVehicle, SuppliedRegistration, SuppliedEventDate, EventDateOutOfDate, EventNonSolicitation, PartyNonSolicitation, UnmatchedModel, UncodedDealer, EventAlreadySelected, NonLatestEvent, InvalidOwnershipCycle, RecontactPeriod, RelativeRecontactPeriod, InvalidVehicleRole, CrossBorderAddress, CrossBorderDealer, ExclusionListMatch, InvalidEmailAddress, BarredEmailAddress, BarredDomain, CaseID, SampleRowProcessed, SampleRowProcessedDate, WrongEventType, MissingStreet, MissingPostcode, MissingEmail, MissingTelephone, MissingStreetAndEmail, MissingTelephoneAndEmail, MissingMobilePhone, MissingMobilePhoneAndEmail, MissingPartyName, MissingLanguage, InvalidModel, InvalidManufacturer, InternalDealer, RegistrationNumber, RegistrationDate, VIN, OutputFileModelDescription, EventDate, SampleEmailAddress, CaseEmailAddress, PreviousEventBounceBack, EventDateTooYoung, AFRLCode, DealerExclusionListMatch, PhoneSuppression, SalesType, InvalidAFRLCode, InvalidSalesType, AgentCodeFlag,DataSource,HardBounce,SoftBounce,Unsubscribes, DateOfLeadCreation, PrevSoftBounce, PrevHardBounce,ServiceTechnicianID,ServiceTechnicianName,ServiceAdvisorName,ServiceAdvisorID,CRMSalesmanName,CRMSalesmanCode, FOBCode, ContactPreferencesSuppression, ContactPreferencesPartySuppress, ContactPreferencesEmailSuppress, ContactPreferencesPhoneSuppress, ContactPreferencesPostalSuppress, SVCRMSalesType, SVCRMInvalidSalesType, DealNumber, RepairOrderNumber, VistaCommonOrderNumber, SalesEmployeeCode, SalesEmployeeName, ServiceEmployeeCode, ServiceEmployeeName, RecordChanged, PDIFlagSet,OriginalPartySuppression, OriginalPostalSuppression, OriginalEmailSuppression, OriginalPhoneSuppression, OtherExclusion, OverrideFlag, GDPRflag, SelectionPostalID, SelectionEmailID, SelectionPhoneID, SelectionLandlineID, SelectionMobileID, SelectionEmail, SelectionPhone, SelectionLandline, SelectionMobile, ContactPreferencesModel,ContactPreferencesPersist, InvalidDateOfLastContact, MatchedODSPrivEmailAddressID, SamplePrivEmailAddress, EmailExcludeBarred,EmailExcludeGeneric, EmailExcludeInvalid, CompanyExcludeBodyShop, CompanyExcludeLeasing, CompanyExcludeFleet, CompanyExcludeBarredCo, OutletPartyID, Dealer10DigitCode, OutletFunction, RoadsideAssistanceProvider, CRC_Owner, ClosedBy, Owner, CountryIsoAlpha2, CRCMarketCode, InvalidDealerBrand, SubBrand, ModelCode, LeadVehSaleType, ModelVariant) -- V1.12 -'AgentCodeFlag' added, V1.15, V1.16 - DateOfLeadCreation added, V1.18, V1.20, V1.21, v1.23, V1.24, V1.25, V1.27 , v1.29, V1.30, V1.32, V1.33, V1.34, V1.35, V1.36, V1.39, V1.40, V1.41, V1.43, V1.44, V1.45, V1.46, V1.47
	SELECT   SuperNationalRegion, BusinessRegion, DealerMarket, SubNationalTerritory, SubNationalRegion, CombinedDealer, DealerName, DealerCode, DealerCodeGDD, FullName, OrganisationName, AnonymityDealer, AnonymityManufacturer, CaseCreationDate, CaseStatusType, CaseOutputType, SentFlag, SentDate, RespondedFlag, ClosureDate, DuplicateRowFlag, BouncebackFlag, UsableFlag, ManualRejectionFlag, FileName, FileActionDate, FileRowCount, LoadedDate, AuditID, AuditItemID, MatchedODSPartyID, MatchedODSPersonID, LanguageID, PartySuppression, MatchedODSOrganisationID, MatchedODSAddressID, CountryID, PostalSuppression, EmailSuppression, MatchedODSVehicleID, ODSRegistrationID, MatchedODSModelID, OwnershipCycle, MatchedODSEventID, ODSEventTypeID, WarrantyID, Brand, Market, Questionnaire, QuestionnaireRequirementID, SuppliedName, SuppliedAddress, SuppliedPhoneNumber, SuppliedMobilePhone, SuppliedEmail, SuppliedVehicle, SuppliedRegistration, SuppliedEventDate, EventDateOutOfDate, EventNonSolicitation, PartyNonSolicitation, UnmatchedModel, UncodedDealer, EventAlreadySelected, NonLatestEvent, InvalidOwnershipCycle, RecontactPeriod, RelativeRecontactPeriod, InvalidVehicleRole, CrossBorderAddress, CrossBorderDealer, ExclusionListMatch, InvalidEmailAddress, BarredEmailAddress, BarredDomain, CaseID, SampleRowProcessed, SampleRowProcessedDate, WrongEventType, MissingStreet, MissingPostcode, MissingEmail, MissingTelephone, MissingStreetAndEmail, MissingTelephoneAndEmail, MissingMobilePhone, MissingMobilePhoneAndEmail, MissingPartyName, MissingLanguage, InvalidModel, InvalidManufacturer, InternalDealer, RegistrationNumber, RegistrationDate, VIN, OutputFileModelDescription, EventDate, SampleEmailAddress, CaseEmailAddress, PreviousEventBounceBack, EventDateTooYoung, AFRLCode, DealerExclusionListMatch, PhoneSuppression, SalesType, InvalidAFRLCode, InvalidSalesType, AgentCodeFlag,DataSource,HardBounce,[SoftBounce],Unsubscribes, DateOfLeadCreation, PrevSoftBounce, PrevHardBounce,ServiceTechnicianID,ServiceTechnicianName,ServiceAdvisorName,ServiceAdvisorID,CRMSalesmanName,CRMSalesmanCode, FOBCode, ContactPreferencesSuppression, ContactPreferencesPartySuppress, ContactPreferencesEmailSuppress, ContactPreferencesPhoneSuppress, ContactPreferencesPostalSuppress, SVCRMSalesType, SVCRMInvalidSalesType, DealNumber, RepairOrderNumber, VistaCommonOrderNumber, SalesEmployeeCode, SalesEmployeeName, ServiceEmployeeCode, ServiceEmployeeName, RecordChanged, PDIFlagSet,OriginalPartySuppression, OriginalPostalSuppression, OriginalEmailSuppression, OriginalPhoneSuppression, OtherExclusion, OverrideFlag, GDPRflag, SelectionPostalID, SelectionEmailID, SelectionPhoneID, SelectionLandlineID, SelectionMobileID, SelectionEmail, SelectionPhone, SelectionLandline, SelectionMobile, ContactPreferencesModel,ContactPreferencesPersist, InvalidDateOfLastContact, MatchedODSPrivEmailAddressID, SamplePrivEmailAddress, EmailExcludeBarred,EmailExcludeGeneric, EmailExcludeInvalid, CompanyExcludeBodyShop, CompanyExcludeLeasing, CompanyExcludeFleet, CompanyExcludeBarredCo, OutletPartyID, Dealer10DigitCode, OutletFunction, RoadsideAssistanceProvider, CRC_Owner, ClosedBy, Owner, CountryIsoAlpha2, CRCMarketCode, InvalidDealerBrand, SubBrand, ModelCode, LeadVehSaleType, ModelVariant  -- V1.12 -'AgentCodeFlag' added, V1.15, V1.16 - DateOfLeadCreation added, V1.18, V1.20, V1.21, v1.23, V1.24, V1.25, V1.27 , v1.29, V1.30, V1.32, V1.33, V1.34, V1.35, V1.36, V1.39, V1.40, V1.41, V1.43, V1.44, V1.45, V1.46, V1.47
	FROM SampleReport.Base
	WHERE FileActionDate >= @StartDate AND FileActionDate < @EndDate 



	------------------------------------------------------------------------------------------------
	--
	--  BUILD DEALER SUMMARY TABLES
	--
	------------------------------------------------------------------------------------------------


	TRUNCATE TABLE SampleReport.SummaryDealerRegionEvents

	INSERT INTO SampleReport.SummaryDealerRegionEvents	
		(
			SuperNationalRegion, 
			BusinessRegion, 
			Market, 
			SubNationalTerritory,				-- v1.14
			SubNationalRegion, 
			DealerCode, 
			DealerCodeGDD, 
			DealerName, 
			EventsLoaded, 
			SuppliedEmail, 
			UsableEvents, 
			InvitesSent, 
			Bouncebacks, 
			Responded, 
			EmailInvites, 
			SMSInvites, 
			PostalInvites,
			PhoneInvites,						-- V1.10
			SoftBounce,					-- V1.17
			HardBounce,					-- V1.17
			Unsubscribes,				-- V1.17
			SuppliedPhoneNumber,		-- V1.17
			SuppliedMobilePhone,		-- V1.17
			PrevSoftBounce,				-- V1.18
			PrevHardBounce,				-- V1.18
			
			OriginalPartySuppression,   -- V1.30
			OriginalPostalSuppression,	-- V1.30
			OriginalEmailSuppression,	-- V1.30
			OriginalPhoneSuppression	-- V1.30
		)
		SELECT	B.SuperNationalRegion ,
				B.BusinessRegion,				-- v1.7
				B.Market,
				B.SubNationalTerritory,			-- v1.14
				B.SubNationalRegion,
				B.DealerCode, 
				B.DealerCodeGDD, 
				B.DealerName,	
				COUNT(*) AS EventsLoaded,
				SUM(ISNULL(B.SuppliedEmail, 0))	AS SuppliedEmail,
				SUM(ISNULL(B.UsableFlag, 0)) AS UsableEvents,
				SUM(ISNULL(B.SentFlag, 0)) AS InvitesSent,
				SUM(ISNULL(B.BouncebackFlag, 0)) AS Bouncebacks,
				SUM(ISNULL(B.RespondedFlag, 0))	AS Responded ,
				
				SUM(CASE WHEN B.CaseOutputType = 'Online' THEN 1 ELSE 0 END) AS EmailInvites,
				SUM(CASE WHEN B.CaseOutputType = 'SMS'    THEN 1 ELSE 0 END) AS SMSInvites,
				SUM(CASE WHEN B.CaseOutputType = 'Postal' THEN 1 ELSE 0 END) AS PostalInvites,
				SUM(CASE WHEN B.CaseOutputType = 'Phone' THEN 1 ELSE 0 END) AS PhoneInvites,			-- V1.10
				
				SUM(ISNULL(B.[SoftBounce], 0))	AS SoftBounce, -- V1.17
				SUM(ISNULL(B.HardBounce, 0))	AS HardBounce, -- V1.17
				SUM(ISNULL(B.Unsubscribes, 0))	AS Unsubscribes, -- V1.17
				SUM(ISNULL(B.SuppliedPhoneNumber, 0))	AS SuppliedPhoneNumber, -- V1.17
				SUM(ISNULL(B.SuppliedMobilePhone, 0))	AS SuppliedMobilePhone, -- V1.17
				SUM(ISNULL(B.PrevSoftBounce, 0))	AS PrevSoftBounce, -- V1.18
				SUM(ISNULL(B.PrevHardBounce, 0))	AS PrevHardBounce, -- V1.18
				
				SUM(ISNULL(B.OriginalPartySuppression, 0))	AS OriginalPartySuppression, -- V1.30
				SUM(ISNULL(B.OriginalPostalSuppression, 0))AS OriginalPostalSuppression, -- V1.30
				SUM(ISNULL(B.OriginalEmailSuppression, 0))	AS OriginalEmailSuppression, -- V1.30
				SUM(ISNULL(B.OriginalPhoneSuppression, 0))	AS OriginalPhoneSuppression -- V1.30
				
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

	--select * from SampleReporting.SampleReport.SummaryDealerRegion	

	------------------------------------------------------------------------------------------------


	INSERT INTO SampleReport.SummaryDealerGroupEvents
	SELECT	CombinedDealer ,
			DealerCode,
			DealerCodeGDD,  
			DealerName,
			--SUM()	AS RecordsInFile,			
			COUNT(*) AS EventsLoaded,
			SUM(ISNULL(SuppliedEmail, 0)) AS SuppliedEmail,
			SUM(ISNULL(UsableFlag, 0)) AS UsableEvents,
			SUM(ISNULL(SentFlag, 0)) AS InvitesSent,
			SUM(ISNULL(BouncebackFlag, 0)) AS Bouncebacks,
			SUM(ISNULL(RespondedFlag, 0)) AS Responded,
			
			SUM(CASE WHEN CaseOutputType = 'Online' THEN 1 ELSE 0 END) AS EmailInvites,
			SUM(CASE WHEN CaseOutputType = 'SMS'    THEN 1 ELSE 0 END) AS SMSInvites,
			SUM(CASE WHEN CaseOutputType = 'Postal' THEN 1 ELSE 0 END) AS PostalInvites,
			SUM(CASE WHEN CaseOutputType = 'Phone' THEN 1 ELSE 0 END) AS PhoneInvites,			-- V1.10
			
			SUM(ISNULL([SoftBounce], 0))	AS SoftBounce, -- V1.17
			SUM(ISNULL(HardBounce, 0))	AS HardBounce, -- V1.17
			SUM(ISNULL(Unsubscribes, 0))	AS Unsubscribes, -- V1.17
			SUM(ISNULL(SuppliedPhoneNumber, 0))	AS SuppliedPhoneNumber, -- V1.17
			SUM(ISNULL(SuppliedMobilePhone, 0))	AS SuppliedMobilePhone, -- V1.17
			SUM(ISNULL(PrevSoftBounce, 0))	AS PrevSoftBounce, -- V1.18
			SUM(ISNULL(PrevHardBounce, 0))	AS PrevHardBounce -- V1.18	
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
	SET @UpdatedAt = GETDATE()


	----------------------------------------------------------------------
	-- Add the DealerRegion records into the aggregate table 
	----------------------------------------------------------------------

	IF (@EchoFeed <> 1 AND @DailyEcho <> 1)		-- V1.9 Do not update Global Reports in Echo Feed, V1.26
	BEGIN
	
		--- First check for and remove, any pre-existing records for this date/BMQ combination.
		IF EXISTS (
				SELECT TOP 1 ReportYear FROM SampleReport.GlobalReportDealerRegionDistinctEventAggregate	
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
			DELETE FROM SampleReport.GlobalReportDealerRegionDistinctEventAggregate	
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
		
		-- Now add the DealerRegion records into the aggregate table 
		INSERT INTO SampleReport.GlobalReportDealerRegionDistinctEventAggregate	(ReportYear, ReportMonth, SummaryType, Brand, Market, Questionnaire, UpdatedTime, SuperNationalRegion, BusinessRegion, SubNationalTerritory, SubNationalRegion, DealerCode, DealerCodeGDD, DealerName, EventsLoaded, SuppliedEmail, UsableEvents, InvitesSent, Bouncebacks, Responded, EmailInvites, SMSInvites, PostalInvites, PhoneInvites, SoftBounce,HardBounce)

		SELECT	Year(@ReportDate),
				Month(@ReportDate),
				@TimePeriod,
				@Brand,
				--@Market,
				ISNULL(R.Market, '') AS Market,								-- V1.8 Use Market from Dealer Specific 
				@Questionnaire,
				@UpdatedAt,
				ISNULL(B.SuperNationalRegion, '') AS SuperNationalRegion,   -- Key field cannot be NULL
				ISNULL(B.BusinessRegion, '') AS BusinessRegion,				-- Key field cannot be NULL   --v1.7
				ISNULL(R.SubNationalTerritory, '') AS SubNationalTerritory,	-- Key field cannot be NULL	  --v1.14
				ISNULL(R.SubNationalRegion, '') AS SubNationalRegion,		-- Key field cannot be NULL
				ISNULL(R.DealerCode, '') AS DealerCode,						-- Key field cannot be NULL
				ISNULL(R.DealerCodeGDD, '') AS DealerCodeGDD,				-- Key field cannot be NULL
				ISNULL(R.DealerName, '') AS DealerName,						-- Key field cannot be NULL  (Dealer Name added as occasionally the logging is not updated and a blank dealer can appear)
				R.EventsLoaded, 
				R.SuppliedEmail, 
				R.UsableEvents, 
				R.InvitesSent, 
				R.Bouncebacks, 
				R.Responded, 
				R.EmailInvites, 
				R.SMSInvites, 
				R.PostalInvites,
				R.PhoneInvites,
				R.SoftBounce,				-- V1.22
				R.HardBounce				-- V1.22
		FROM SampleReport.SummaryDealerRegionEvents R
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

		--- First check for and remove, any pre-existing records for this date/BMQ combination.
		IF EXISTS (
				SELECT TOP 1 ReportYear FROM SampleReport.GlobalReportDistinctEventSummary
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
			DELETE FROM SampleReport.GlobalReportDistinctEventSummary
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

		-- Now add the Global Summary sheet data
		;WITH CTE_Totals
		AS (	
				SELECT
					R.Market,									--V1.8 Group by Market
					SUM(R.EventsLoaded)		AS EventsLoaded, 
					SUM(R.SuppliedEmail)	AS SuppliedEmail, 
					SUM(R.UsableEvents)		AS UsableEvents,
					SUM(R.InvitesSent)		AS InvitesSent, 
					SUM(R.Bouncebacks)		AS Bouncebacks, 
					SUM(R.Responded)		AS Responded, 
					SUM(R.EmailInvites)		AS EmailInvites, 
					SUM(R.SMSInvites)		AS SMSInvites, 
					SUM(R.PostalInvites)	AS PostalInvites,
					SUM(R.PhoneInvites)		AS PhoneInvites,
					SUM(R.SoftBounce)       AS SoftBounce,		    -- V1.22
				    SUM(R.HardBounce)       AS HardBounce			-- V1.22
				FROM SampleReport.SummaryDealerRegionEvents R	
				GROUP BY R.Market								--V1.8 Group by Market
		)				
		INSERT INTO SampleReport.GlobalReportDistinctEventSummary  (ReportYear, ReportMonth, SummaryType, Brand, Market, Questionnaire, UpdatedTime, EventsLoaded, SuppliedEmail, UsableEvents, InvitesSent, Bouncebacks, Responded, EmailInvites, SMSInvites, PostalInvites, PhoneInvites, SuperNationalRegion, BusinessRegion, FeedType, [10YrVehicleParc],SoftBounce,HardBounce)
		SELECT		Year(@ReportDate),
					Month(@ReportDate),
					@TimePeriod,
					@Brand,
					T.Market,									--V1.8
					@Questionnaire,
					@UpdatedAt,
					
					T.EventsLoaded, 
					T.SuppliedEmail, 
					T.UsableEvents, 
					T.InvitesSent, 
					T.Bouncebacks, 
					T.Responded, 
					T.EmailInvites, 
					T.SMSInvites, 
					T.PostalInvites,
					T.PhoneInvites,					-- V1.10

					ISNULL(B.SuperNationalRegion, '')	AS SuperNationalRegion,
					ISNULL(B.BusinessRegion, '')		AS BusinessRegion,		-- v1.7
					ISNULL(B.FeedType, '')				AS FeedType,
					ISNULL(B.[10YrVehicleParc], '')		AS [10YrVehicleParc],
					
					T.SoftBounce,				-- V1.22
				    T.HardBounce				-- V1.22
					
			-- select * 
			FROM CTE_Totals t
			LEFT JOIN SampleReport.BMQSpecificInformation B 
						ON B.Brand = @brand
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
			EventsLoaded int 
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
			COUNT(*) AS EventsLoaded
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


	INSERT INTO SampleReport.SummaryFilesEvents (Market, ScheduledFiles, ReceivedFiles, ActionDate, DueDate, FileRowCount, EventsLoaded, DaysLate)

	SELECT  --COALESCE(FS.FileName, SFS.FileName) AS FileName,
			FS.Market,												-- V1.8 Add Market
			SFS.FileName  AS ScheduledFiles,
			FS.FileName   AS ReceivedFiles,
			FS.ActionDate, 
			SFS.DueDate,
			FS.FileRowCount, 
			FS.EventsLoaded, 
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
		OR SFS.FileName IS NULL
		OR FS.FileName IS NOT NULL
	ORDER BY COALESCE(FS.ActionDate, SFS.DueDate)


	------------------------------------------------------------------------------------------------
	--
	--  BUILD REPORT HEADER TABLE
	--
	------------------------------------------------------------------------------------------------

	--DECLARE @ReceivedFiles INT,
	--		@LateFiles INT,
	--		@EventsReceived INT
			
	--SELECT  @ReceivedFiles = COUNT(*) ,
	--		@LateFiles = SUM(CASE WHEN ISNULL(DaysLate, 1) > 0 THEN 1 ELSE 0 END)
	--FROM SampleReport.SummaryFilesEvents
	--WHERE ReceivedFiles IS NOT NULL
			
	--SELECT @EventsReceived = COUNT(*)
	--FROM SampleReport.IndividualRowsEvents 

	--V1.8 Change query used to build Summary Header to split by Market 
	INSERT INTO SampleReport.SummaryHeaderEvents (Brand, Market, Questionnaire, ReportDate, StartDate, EndDate, ReceivedFiles, LateFiles)
	SELECT	@Brand AS Brand,
			SF.Market,
			@Questionnaire AS Questionnaire,
			@ReportDate  AS ReportDate,
			@StartDate AS StartDate,
			DATEADD(day, -1, @EndDate) AS EndDate,
			COUNT(*) AS ReceivedFiles,
			SUM(CASE WHEN ISNULL(DaysLate, 1) > 0 THEN 1 ELSE 0 END) AS LateFiles
	FROM SampleReport.SummaryFilesEvents SF
	WHERE ReceivedFiles IS NOT NULL
	GROUP BY SF.Market

	UPDATE SH 
	SET SH.EventsReceived = 
	(SELECT COUNT(*) FROM SampleReport.IndividualRowsEvents IR WHERE IR.Market = SH.Market)
	FROM SampleReport.SummaryHeaderEvents SH


	------------------------------------------------------------------------------------------------
	--
	--  USABLE RECORDS BY DEALER TAB
	--
	------------------------------------------------------------------------------------------------

	INSERT INTO SampleReport.SummaryDealerRegionEventsUsable

		(
			DealerCode
			, DealerCodeGDD
			, DealerName
			, SubNationalTerritory			-- v1.14
			, SubNationalRegion
			, CombinedDealer
			, EventsReceived
		)

			SELECT 
				ISNULL(DealerCode, '') DealerCode
				,ISNULL(DealerCodeGDD, '') DealerCodeGDD
				,ISNULL(DealerName, '') DealerName
				,ISNULL(SubNationalTerritory, '') SubNationalTerritory		-- v1.14
				,ISNULL(SubNationalRegion, '') SubNationalRegion
				,ISNULL(CombinedDealer, '') CombinedDealer
				,COUNT(*) AS EventsReceived
			FROM SampleReport.Base
			WHERE FileActionDate >= @StartDate AND FileActionDate < @EndDate
			GROUP BY DealerCode
				,DealerCodeGDD
				,DealerName
				,SubNationalTerritory		-- v1.14
				,SubNationalRegion
				,CombinedDealer
			ORDER BY DealerCode
		

	-- UPDATE EVENT DRIVEN SUPPLIED FLAGS
	UPDATE U
		SET EventDrivenEvents = C.EventDrivenEvents
		, EventDrivenUsable = C.EventDrivenUsable
		, EventDrivenInvites = C.EventDrivenInvites
		, EventDrivenResponses = C.EventDrivenResponses
		, EventDrivenOutOfDate = C.EventDrivenOutOfDate
		, EventDrivenPartyNonSolicitation = C.EventDrivenPartyNonSolicitation
		, EventDrivenNonLatestEvent = C.EventDrivenNonLatestEvent
		, EventDrivenUncodedDealer = C.EventDrivenUncodedDealer
		, EventDrivenEventAlreadySelected = C.EventDrivenEventAlreadySelected
		, EventDrivenWithinRecontactPeriod = C.EventDrivenWithinRecontactPeriod
		, EventDrivenWithinRelativeRecontactPeriod = C.EventDrivenRelativeRecontactPeriod
		, EventDrivenExclusionListMatch = C.EventDrivenExclusionListMatch
		, EventDrivenManualRejectionFlag = C.EventDrivenManualRejectionFlag

		, EventDrivenEmailInvites				= C.EventDrivenEmailInvites		-- v1.2
		, EventDrivenSMSInvites					= C.EventDrivenSMSInvites
		, EventDrivenPostalInvites				= C.EventDrivenPostalInvites
		, EventDrivenPhoneInvites				= C.EventDrivenPhoneInvites					--V1.10
		
		, EventDrivenBarredEmailAddress			= C.EventDrivenBarredEmailAddress			-- v1.2
		, EventDrivenBarredDomain				= C.EventDrivenBarredDomain					
		, EventDrivenInvalidEmailAddress		= C.EventDrivenInvalidEmailAddress			
		, EventDrivenMissingMobilePhone			= C.EventDrivenMissingMobilePhone			
		, EventDrivenMissingMobilePhoneAndEmail = C.EventDrivenMissingMobilePhoneAndEmail	
		
		
		, EventDrivenUnmatchedModel				= C.EventDrivenUnmatchedModel
		, EventDrivenWrongEventType				= C.EventDrivenWrongEventType
		, EventDrivenEventNonSolicitation		= C.EventDrivenEventNonSolicitation
		, EventDrivenPartySuppression			= C.EventDrivenPartySuppression
		, EventDrivenPostalSuppression			= C.EventDrivenPostalSuppression
		, EventDrivenEmailSuppression			= C.EventDrivenEmailSuppression
		, EventDrivenBouncebackFlag				= C.EventDrivenBouncebackFlag
		, EventDrivenMissingStreetAndEmail		= C.EventDrivenMissingStreetAndEmail
		, EventDrivenMissingLanguage			= C.EventDrivenMissingLanguage
		, EventDrivenInvalidManufacturer		= C.EventDrivenInvalidManufacturer
		, EventDrivenInternalDealer				= C.EventDrivenInternalDealer		
		, EventDrivenMissingPartyName			= C.EventDrivenMissingPartyName
		
		,EventDrivenInvalidOwnershipCycle		= C.EventDrivenInvalidOwnershipCycle
		
		, EventDrivenMissingStreet				= C.EventDrivenMissingStreet
		, EventDrivenMissingPostcode			= C.EventDrivenMissingPostcode
		, EventDrivenMissingEmail				= C.EventDrivenMissingEmail
		, EventDrivenMissingTelephone			= C.EventDrivenMissingTelephone
		, EventDrivenMissingTelephoneAndEmail	= C.EventDrivenMissingTelephoneAndEmail

		, EventDrivenPreviousEventBounceBack	= C.EventDrivenPreviousEventBounceBack			--V1.6
		, EventDrivenEventDateTooYoung			= C.EventDrivenEventDateTooYoung				--V1.6
		
		, EventDrivenSuppliedName				= C.EventDrivenSuppliedName					--V1.6
		, EventDrivenSuppliedAddress			= C.EventDrivenSuppliedAddress					--V1.6
		, EventDrivenSuppliedPhoneNumber		= C.EventDrivenSuppliedPhoneNumber				--V1.6
		, EventDrivenSuppliedMobilePhone		= C.EventDrivenSuppliedMobilePhone				--V1.6

		, EventDrivenPhoneSuppression			= C.EventDrivenPhoneSuppression					--V1.10
		, EventDrivenDealerExclusionListMatch	= C.EventDrivenDealerExclusionListMatch			--V1.10
		, EventDrivenInvalidAFRLCode			= C.EventDrivenInvalidAFRLCode					--V1.10		
		, EventDrivenInvalidSalesType			= C.EventDrivenInvalidSalesType					--V1.10
		
		, EventDrivenPrevSoftBounce				= C.EventDrivenPrevSoftBounce					--V1.19
		, EventDrivenPrevHardBounce             = C.EventDrivenPrevHardBounce                   --V1.19
		, EventDrivenSoftBounce                 = C.EventDrivenSoftBounce                       --V1.19
		, EventDrivenHardBounce                 = C.EventDrivenHardBounce                       --V1.19
		, EventDrivenUnsubscribes               = C.EventDrivenUnsubscribes                     --V1.19
		
		, EventDrivenSVCRMInvalidSalesType      = C.EventDrivenSVCRMInvalidSalesType					--V1.24
		, EventDrivenContactPreferencesSuppression = C.EventDrivenContactPreferencesSuppression			--v1.29
		, EventDrivenContactPreferencesPartySuppress = C.EventDrivenContactPreferencesPartySuppress		--v1.29
		, EventDrivenContactPreferencesEmailSuppress = C.EventDrivenContactPreferencesEmailSuppress		--v1.29
		, EventDrivenContactPreferencesPhoneSuppress = C.EventDrivenContactPreferencesPhoneSuppress		--v1.29
		, EventDrivenContactPreferencesPostalSuppress = C.EventDrivenContactPreferencesPostalSuppress	--v1.29
		, EventDrivenPDIFlagSet					= C.EventDrivenPDIFlagSet								--v1.29
		
		, EventDrivenOriginalPartySuppression = C.EventDrivenOriginalPartySuppression					--V1.30
		, EventDrivenOriginalPostalSuppression = C.EventDrivenOriginalPostalSuppression					--V1.30
		, EventDrivenOriginalEmailSuppression = C.EventDrivenOriginalEmailSuppression					--V1.30
		, EventDrivenOriginalPhoneSuppression = C.EventDrivenOriginalPhoneSuppression					--V1.30	
		, EventDrivenOtherExclusion = C.EventDrivenOtherExclusion					                    --V1.32
		, EventDrivenSuppliedEmail	= C.EventDrivenSuppliedEmail			                            --V1.38
		, EventDrivenInvalidDateOfLastContact = C.EventDrivenInvalidDateOfLastContact			        --V1.39
		
	FROM SampleReport.SummaryDealerRegionEventsUsable U
	INNER JOIN
		(
			SELECT 
				ISNULL(DealerCode, '') DealerCode
				, ISNULL(DealerCodeGDD, '') DealerCodeGDD
				, ISNULL(DealerName, '') DealerName
				, ISNULL(SubNationalTerritory, '') SubNationalTerritory			-- v1.14
				, ISNULL(SubNationalRegion, '') SubNationalRegion
				, ISNULL(CombinedDealer, '') CombinedDealer
				, COUNT(*) AS EventDrivenEvents
				, SUM(ISNULL(UsableFlag, 0)) AS EventDrivenUsable
				, SUM(ISNULL(SentFlag, 0)) AS EventDrivenInvites
				, SUM(ISNULL(RespondedFlag, 0)) AS EventDrivenResponses
				, SUM(ISNULL(EventDateOutOfDate, 0)) AS EventDrivenOutOfDate
				, SUM(ISNULL(PartyNonSolicitation, 0)) AS EventDrivenPartyNonSolicitation
				, SUM(ISNULL(NonLatestEvent, 0)) AS EventDrivenNonLatestEvent
				, SUM(ISNULL(UncodedDealer, 0)) AS EventDrivenUncodedDealer
				, SUM(ISNULL(EventAlreadySelected, 0)) AS EventDrivenEventAlreadySelected
				, SUM(ISNULL(RecontactPeriod, 0)) AS EventDrivenWithinRecontactPeriod
				, SUM(ISNULL(RelativeRecontactPeriod, 0)) AS EventDrivenRelativeRecontactPeriod
				, SUM(ISNULL(ExclusionListMatch, 0)) AS EventDrivenExclusionListMatch
				, SUM(ISNULL(ManualRejectionFlag, 0)) AS EventDrivenManualRejectionFlag

				, SUM(CASE WHEN CaseOutputType = 'Online' THEN 1 ELSE 0 END) AS EventDrivenEmailInvites	-- v1.2
				, SUM(CASE WHEN CaseOutputType = 'SMS'    THEN 1 ELSE 0 END) AS EventDrivenSMSInvites
				, SUM(CASE WHEN CaseOutputType = 'Postal' THEN 1 ELSE 0 END) AS EventDrivenPostalInvites				
				, SUM(CASE WHEN CaseOutputType = 'Phone' THEN 1 ELSE 0 END) AS EventDrivenPhoneInvites	--V1.10			

				, SUM(ISNULL(BarredEmailAddress, 0)) AS EventDrivenBarredEmailAddress		-- v1.2
				, SUM(ISNULL(BarredDomain, 0)) AS EventDrivenBarredDomain
				, SUM(ISNULL(InvalidEmailAddress, 0)) AS EventDrivenInvalidEmailAddress
				, SUM(ISNULL(MissingMobilePhone, 0)) AS EventDrivenMissingMobilePhone
				, SUM(ISNULL(MissingMobilePhoneAndEmail, 0)) AS EventDrivenMissingMobilePhoneAndEmail
				
				
				, SUM(ISNULL(UnmatchedModel, 0)) AS EventDrivenUnmatchedModel
				, SUM(ISNULL(WrongEventType, 0)) AS EventDrivenWrongEventType	
				, SUM(ISNULL(EventNonSolicitation, 0)) AS EventDrivenEventNonSolicitation
				, SUM(ISNULL(PartySuppression, 0)) AS EventDrivenPartySuppression	
				, SUM(ISNULL(PostalSuppression, 0)) AS EventDrivenPostalSuppression	
				, SUM(ISNULL(EmailSuppression, 0)) AS EventDrivenEmailSuppression	
				, SUM(ISNULL(BouncebackFlag, 0)) AS EventDrivenBouncebackFlag
				, SUM(ISNULL(MissingStreetAndEmail, 0)) AS EventDrivenMissingStreetAndEmail
				, SUM(ISNULL(MissingLanguage, 0)) AS EventDrivenMissingLanguage
				, SUM(ISNULL(InvalidManufacturer, 0)) AS EventDrivenInvalidManufacturer
				, SUM(ISNULL(InternalDealer, 0)) AS EventDrivenInternalDealer				
				, SUM(ISNULL(MissingPartyName, 0)) AS EventDrivenMissingPartyName	
				, SUM(ISNULL(InvalidOwnershipCycle, 0)) AS EventDrivenInvalidOwnershipCycle
				
				, SUM(ISNULL(MissingStreet, 0)) AS EventDrivenMissingStreet
				, SUM(ISNULL(MissingPostcode, 0)) AS EventDrivenMissingPostcode
				, SUM(ISNULL(MissingEmail, 0)) AS EventDrivenMissingEmail
				, SUM(ISNULL(MissingTelephone, 0)) AS EventDrivenMissingTelephone
				, SUM(ISNULL(MissingTelephoneAndEmail, 0)) AS EventDrivenMissingTelephoneAndEmail
						
				, SUM(ISNULL(PreviousEventBounceBack, 0)) AS EventDrivenPreviousEventBounceBack		--V1.6
				, SUM(ISNULL(EventDateTooYoung, 0)) AS EventDrivenEventDateTooYoung					--v1.6
				
				, SUM(ISNULL(CAST(~CAST(SuppliedName AS BIT) AS INT), 0)) AS EventDrivenSuppliedName
				, SUM(ISNULL(CAST(~CAST(SuppliedAddress AS BIT) AS INT), 0)) AS EventDrivenSuppliedAddress
				, SUM(ISNULL(CAST(~CAST(SuppliedPhoneNumber AS BIT) AS INT), 0)) AS EventDrivenSuppliedPhoneNumber
				, SUM(ISNULL(CAST(~CAST(SuppliedMobilePhone AS BIT) AS INT), 0)) AS EventDrivenSuppliedMobilePhone

				, SUM(ISNULL(PhoneSuppression, 0)) AS EventDrivenPhoneSuppression					--V1.10
				, SUM(ISNULL(DealerExclusionListMatch, 0)) AS EventDrivenDealerExclusionListMatch	--V1.10
				, SUM(ISNULL(InvalidAFRLCode, 0)) AS EventDrivenInvalidAFRLCode						--V1.10
				, SUM(ISNULL(InvalidSalesType, 0)) AS EventDrivenInvalidSalesType					--V1.10
				
				, SUM(ISNULL(PrevSoftBounce, 0)) AS EventDrivenPrevSoftBounce				--V1.19
				, SUM(ISNULL(PrevHardBounce, 0)) AS EventDrivenPrevHardBounce	            --V1.19
				, SUM(ISNULL([SoftBounce], 0)) AS EventDrivenSoftBounce						--V1.19
				, SUM(ISNULL(HardBounce, 0)) AS EventDrivenHardBounce					    --V1.19
				, SUM(ISNULL(Unsubscribes, 0)) AS EventDrivenUnsubscribes					--V1.19
				
				, SUM(ISNULL(SVCRMInvalidSalesType, 0)) AS EventDrivenSVCRMInvalidSalesType	--V1.24
				
				, SUM(ISNULL(ContactPreferencesSuppression, 0)) 
											AS EventDrivenContactPreferencesSuppression		--V1.29
				, SUM(ISNULL(ContactPreferencesPartySuppress, 0)) 
											AS EventDrivenContactPreferencesPartySuppress	--V1.29
				, SUM(ISNULL(ContactPreferencesEmailSuppress, 0)) 
											AS EventDrivenContactPreferencesEmailSuppress	--V1.29
				, SUM(ISNULL(ContactPreferencesPhoneSuppress, 0)) 
											AS EventDrivenContactPreferencesPhoneSuppress	--V1.29
				, SUM(ISNULL(ContactPreferencesPostalSuppress, 0)) 
											AS EventDrivenContactPreferencesPostalSuppress	--V1.29
				, SUM(ISNULL(PDIFlagSet, 0)) AS EventDrivenPDIFlagSet						--V1.29
				
				, SUM(ISNULL(OriginalPartySuppression, 0)) AS EventDrivenOriginalPartySuppression		--V1.30
				, SUM(ISNULL(OriginalPostalSuppression, 0)) AS EventDrivenOriginalPostalSuppression	    --V1.30
				, SUM(ISNULL(OriginalEmailSuppression, 0)) AS EventDrivenOriginalEmailSuppression		--V1.30
				, SUM(ISNULL(OriginalPhoneSuppression, 0)) AS EventDrivenOriginalPhoneSuppression		--V1.30	
				, SUM(ISNULL(OtherExclusion, 0)) AS EventDrivenOtherExclusion  	--V1.32	
				, SUM(ISNULL(CAST(~CAST(SuppliedEmail AS BIT) AS INT), 0)) AS EventDrivenSuppliedEmail  --V1.38
				, SUM(ISNULL(InvalidDateOfLastContact, 0)) AS EventDrivenInvalidDateOfLastContact 	--V1.39
				
			FROM SampleReport.Base
			WHERE CASE WHEN FileName LIKE '%DDW%' THEN 0 ELSE 1 END = 1
			AND FileActionDate >= @StartDate AND FileActionDate < @EndDate
			GROUP BY DealerCode
				, DealerCodeGDD
				, DealerName
				, SubNationalTerritory			-- v1.14
				, SubNationalRegion
				, CombinedDealer
		) C
	ON U.DealerCode = C.DealerCode
	AND U.DealerCodeGDD = C.DealerCodeGDD
	AND U.DealerName = C.DealerName
	AND U.SubNationalTerritory = C.SubNationalTerritory			-- v1.14
	AND U.SubNationalRegion = C.SubNationalRegion
	AND U.CombinedDealer = C.CombinedDealer;	
			
	-- UPDATE THE DDW SUPPLIED FLAGS
	UPDATE U
		SET DDWDrivenEvents = C.DDWDrivenEvents
		, DDWDrivenInvites = C.DDWDrivenInvites
		, DDWDrivenResponses = C.DDWDrivenResponses
		
		, DDWDrivenEmailInvites		= C.DDWDrivenEmailInvites		-- v1.2
		, DDWDrivenSMSInvites		= C.DDWDrivenSMSInvites
		, DDWDrivenPostalInvites	= C.DDWDrivenPostalInvites
		, DDWDrivenPhoneInvites		= C.DDWDrivenPhoneInvites		--V1.10			
	
	FROM SampleReport.SummaryDealerRegionEventsUsable U
	INNER JOIN
		(
			SELECT 
				ISNULL(DealerCode, '') DealerCode
				, ISNULL(DealerCodeGDD, '') DealerCodeGDD
				, ISNULL(DealerName, '') DealerName
				, ISNULL(SubNationalTerritory, '') SubNationalTerritory			-- v1.14
				, ISNULL(SubNationalRegion, '') SubNationalRegion
				, ISNULL(CombinedDealer, '') CombinedDealer
				, COUNT(*) AS DDWDrivenEvents
				, SUM(ISNULL(SentFlag, 0)) AS DDWDrivenInvites
				, SUM(ISNULL(RespondedFlag, 0)) AS DDWDrivenResponses

				,SUM(CASE WHEN CaseOutputType = 'Online' THEN 1 ELSE 0 END) AS DDWDrivenEmailInvites	-- v1.2
				,SUM(CASE WHEN CaseOutputType = 'SMS'    THEN 1 ELSE 0 END) AS DDWDrivenSMSInvites
				,SUM(CASE WHEN CaseOutputType = 'Postal' THEN 1 ELSE 0 END) AS DDWDrivenPostalInvites 
				,SUM(CASE WHEN CaseOutputType = 'Phone' THEN 1 ELSE 0 END) AS DDWDrivenPhoneInvites		-- V1.10
							
				
			FROM SampleReport.Base 
			WHERE CASE WHEN FileName LIKE '%DDW%' THEN 0 ELSE 1 END = 0
			AND FileActionDate >= @StartDate AND FileActionDate < @EndDate
			GROUP BY DealerCode
				, DealerCodeGDD
				, DealerName
				, SubNationalTerritory			-- v1.14
				, SubNationalRegion
				, CombinedDealer
		) C
	ON U.DealerCode = C.DealerCode
	AND U.DealerCodeGDD = C.DealerCodeGDD
	AND U.DealerName = C.DealerName
	AND U.SubNationalTerritory = C.SubNationalTerritory		-- v1.14
	AND U.SubNationalRegion = C.SubNationalRegion
	AND U.CombinedDealer = C.CombinedDealer;

	
	-- UPDATE THE 'OTHER' REASON FOR NON USABLE FLAG **Commented out after release of V1.32***
	--UPDATE U
		--SET EventDrivenOther = O.EventDrivenOther
	--FROM SampleReport.SummaryDealerRegionEventsUsable U
	--INNER JOIN
		--(
			--SELECT 
                        --ISNULL(DealerCode, '') DealerCode
                        --, ISNULL(DealerCodeGDD, '') DealerCodeGDD
                        --, ISNULL(DealerName, '') DealerName
                        --, ISNULL(SubNationalTerritory, '') SubNationalTerritory			-- v1.14
                        --, ISNULL(SubNationalRegion, '') SubNationalRegion
                        --, ISNULL(CombinedDealer, '') CombinedDealer
                        --, COUNT(*) as EventDrivenOther
                  --FROM SampleReport.IndividualRowsEvents
                  --WHERE 
                  --SentDate IS NULL AND 
                  --ISNULL(ManualRejectionFlag, 0) + 
                  --ISNULL(EventDateOutOfDate, 0) + 
                  --ISNULL(EventNonSolicitation, 0) + 
                  --ISNULL(PartyNonSolicitation, 0) + 
                  --ISNULL(UncodedDealer, 0) +                   
                  --ISNULL(NonLatestEvent, 0) + 
                  --ISNULL(RecontactPeriod, 0) + 
                  --ISNULL(ExclusionListMatch, 0) + 
                  --ISNULL(InvalidEmailAddress, 0) + 
                  --ISNULL(BarredEmailAddress, 0) + 
                  --ISNULL(BarredDomain, 0) +                   
                  --ISNULL(MissingTelephone, 0) + 
                  --ISNULL(MissingTelephoneAndEmail, 0) + 
                  --ISNULL(MissingMobilePhone, 0) + 
                  --ISNULL(MissingMobilePhoneAndEmail, 0) + 
                  
                  --ISNULL(EventAlreadySelected, 0) + 
                  --ISNULL(InvalidOwnershipCycle, 0) + 
                  --ISNULL(RelativeRecontactPeriod, 0) + 
                  --ISNULL(InvalidManufacturer, 0)  + 
                  --ISNULL(InternalDealer, 0)  + 
                  --ISNULL(UnmatchedModel, 0)  + 
                  
                  --ISNULL(WrongEventType, 0) + 
                  --ISNULL(MissingLanguage, 0) + 
                  --ISNULL(MissingPartyName, 0) + 
                  --ISNULL(MissingStreetAndEmail, 0) + 
                  --ISNULL(BouncebackFlag, 0) + 
                  
                  --ISNULL(PartySuppression, 0)+ 
                  --ISNULL(PostalSuppression, 0) + 
				  --ISNULL(EmailSuppression, 0) +
				  
				  --ISNULL(MissingStreet, 0) +
				  --ISNULL(MissingPostcode, 0) +
				  --ISNULL(MissingEmail, 0) +
				  --ISNULL(MissingTelephone, 0) +
				  
				  --ISNULL(PreviousEventBounceBack,0) +						
				  --ISNULL(EventDateTooYoung,0) +

				  --ISNULL(DealerExclusionListMatch,0) +		-- V1.10
				  --ISNULL(PhoneSuppression,0) +				-- V1.10
				  --ISNULL(InvalidAFRLCode,0) +				-- V1.10
 				  --ISNULL(InvalidSalesType,0) +				-- V1.10
 				  
 				  --ISNULL(PrevSoftBounce,0) +				-- V1.19		-- CGR 26/04/2017 - These are not actually non-SELECTION reasons (but will do no harm here) - NNEDS REVIEWING
 				  --ISNULL(PrevHardBounce,0) +				-- V1.19		-- CGR 26/04/2017 - These are not actually non-SELECTION reasons (but will do no harm here) - NNEDS REVIEWING 
 				  --ISNULL(SoftBounce,0) +				    -- V1.19		-- CGR 26/04/2017 - These are not actually non-SELECTION reasons (but will do no harm here) - NNEDS REVIEWING 
 				  --ISNULL(HardBounce,0) +				    -- V1.19		-- CGR 26/04/2017 - These are not actually non-SELECTION reasons (but will do no harm here) - NNEDS REVIEWING 
 				  --ISNULL(Unsubscribes,0) +				    -- V1.19		-- CGR 26/04/2017 - These are not actually non-SELECTION reasons (but will do no harm here) - NNEDS REVIEWING 
                  
                  --ISNULL(SVCRMInvalidSalesType,0) +		    -- V1.24		-- iS THIS AN EXCLUSION REASON?
                 
                  --ISNULL(PDIFlagSet,0) +					-- V1.29		
                  --ISNULL(ContactPreferencesSuppression,0) +	-- V1.29	
                  --ISNULL(ContactPreferencesPartySuppress,0) +	-- V1.29
                  --ISNULL(ContactPreferencesEmailSuppress,0) +	-- V1.29
                  --ISNULL(ContactPreferencesPhoneSuppress,0) +	-- V1.29
                  --ISNULL(ContactPreferencesPostalSuppress,0) +	-- V1.29	
                                    
				  --ISNULL(MissingTelephoneAndEmail, 0) =0
                  
                  
                  --AND ISNULL(UsableFlag,0)  =0
                  --AND FileName not LIKE '%DDW%'                                                       
                  --AND FileActionDate >= @StartDate AND FileActionDate < @EndDate
                  --GROUP BY 
                        --ISNULL(DealerCode, '')
                        --, ISNULL(DealerName, '')
                        --, ISNULL(DealerCodeGDD, '')
                        --, ISNULL(SubNationalTerritory, '')			-- v1.14
                        --, ISNULL(SubNationalRegion, '')
                        --, ISNULL(CombinedDealer, '')
		--) O
	--ON U.DealerCode = O.DealerCode
	--AND U.DealerCodeGDD = O.DealerCodeGDD
	--AND U.DealerName = O.DealerName
	--AND U.SubNationalTerritory = O.SubNationalTerritory				-- v1.14
	--AND U.SubNationalRegion = O.SubNationalRegion
	--AND U.CombinedDealer = O.CombinedDealer;
	

	-- SET ALL THE NULL VALUES TO ZEROS
	UPDATE SampleReport.SummaryDealerRegionEventsUsable
		SET EventDrivenEvents = ISNULL(EventDrivenEvents, 0) 
		, EventDrivenUsable = ISNULL(EventDrivenUsable, 0) 
		, EventDrivenInvites = ISNULL(EventDrivenInvites, 0) 
		, EventDrivenResponses = ISNULL(EventDrivenResponses, 0) 
		, EventDrivenOutOfDate = ISNULL(EventDrivenOutOfDate, 0) 
		, EventDrivenPartyNonSolicitation = ISNULL(EventDrivenPartyNonSolicitation, 0) 
		, EventDrivenNonLatestEvent = ISNULL(EventDrivenNonLatestEvent, 0) 
		, EventDrivenUncodedDealer = ISNULL(EventDrivenUncodedDealer, 0) 
		, EventDrivenEventAlreadySelected = ISNULL(EventDrivenEventAlreadySelected, 0) 
		, EventDrivenWithinRecontactPeriod = ISNULL(EventDrivenWithinRecontactPeriod, 0) 
		, EventDrivenWithinRelativeRecontactPeriod = ISNULL(EventDrivenWithinRelativeRecontactPeriod, 0) 
		, EventDrivenExclusionListMatch = ISNULL(EventDrivenExclusionListMatch, 0) 

		, EventDrivenEmailInvites				= ISNULL(EventDrivenEmailInvites, 0)			-- v1.2
		, EventDrivenSMSInvites					= ISNULL(EventDrivenSMSInvites, 0)
		, EventDrivenPostalInvites				= ISNULL(EventDrivenPostalInvites, 0)
		, EventDrivenPhoneInvites				= ISNULL(EventDrivenPhoneInvites, 0)			-- V1.10
		, EventDrivenBarredEmailAddress			= ISNULL(EventDrivenBarredEmailAddress, 0)		-- v1.2
		, EventDrivenBarredDomain				= ISNULL(EventDrivenBarredDomain, 0) 
		, EventDrivenInvalidEmailAddress		= ISNULL(EventDrivenInvalidEmailAddress, 0) 
		, EventDrivenMissingMobilePhone			= ISNULL(EventDrivenMissingMobilePhone, 0) 
		, EventDrivenMissingMobilePhoneAndEmail = ISNULL(EventDrivenMissingMobilePhoneAndEmail, 0) 		
		
		, EventDrivenManualRejectionFlag = ISNULL(EventDrivenManualRejectionFlag, 0) 
		, EventDrivenOther = ISNULL(EventDrivenOther, 0) 
		, DDWDrivenEvents = ISNULL(DDWDrivenEvents, 0) 
		, DDWDrivenInvites = ISNULL(DDWDrivenInvites, 0) 
		, DDWDrivenResponses = ISNULL(DDWDrivenResponses, 0)
		
		, DDWDrivenEmailInvites = ISNULL(DDWDrivenEmailInvites, 0)			-- v1.2
		, DDWDrivenSMSInvites = ISNULL(DDWDrivenSMSInvites, 0)
		, DDWDrivenPostalInvites = ISNULL(DDWDrivenPostalInvites, 0)
		, DDWDrivenPhoneInvites = ISNULL(DDWDrivenPhoneInvites, 0)
		
		, EventDrivenUnmatchedModel				= ISNULL(EventDrivenUnmatchedModel, 0)
		, EventDrivenWrongEventType				= ISNULL(EventDrivenWrongEventType, 0)
		, EventDrivenEventNonSolicitation		= ISNULL(EventDrivenEventNonSolicitation, 0)
		, EventDrivenPartySuppression			= ISNULL(EventDrivenPartySuppression, 0)
		, EventDrivenPostalSuppression			= ISNULL(EventDrivenPostalSuppression, 0)
		, EventDrivenEmailSuppression			= ISNULL(EventDrivenEmailSuppression, 0)
		, EventDrivenBouncebackFlag				= ISNULL(EventDrivenBouncebackFlag, 0)
		, EventDrivenMissingStreetAndEmail		= ISNULL(EventDrivenMissingStreetAndEmail, 0)
		, EventDrivenMissingLanguage			= ISNULL(EventDrivenMissingLanguage, 0)
		, EventDrivenInvalidManufacturer		= ISNULL(EventDrivenInvalidManufacturer, 0)
		, EventDrivenInternalDealer				= ISNULL(EventDrivenInternalDealer, 0)		
		, EventDrivenMissingPartyName			= ISNULL(EventDrivenMissingPartyName, 0)
		, EventDrivenInvalidOwnershipCycle		= ISNULL(EventDrivenInvalidOwnershipCycle, 0)
		
		, EventDrivenMissingStreet				= ISNULL(EventDrivenMissingStreet, 0)
		, EventDrivenMissingPostcode			= ISNULL(EventDrivenMissingPostcode, 0)
		, EventDrivenMissingEmail				= ISNULL(EventDrivenMissingEmail, 0)
		, EventDrivenMissingTelephone			= ISNULL(EventDrivenMissingTelephone, 0)
		, EventDrivenMissingTelephoneAndEmail	= ISNULL(EventDrivenMissingTelephoneAndEmail, 0)
		, EventDrivenPreviousEventBounceBack	= ISNULL(EventDrivenPreviousEventBounceBack, 0)	--V1.6
		, EventDrivenEventDateTooYoung			= ISNULL(EventDrivenEventDateTooYoung, 0)		--V1.6

		, EventDrivenSuppliedName				= ISNULL(EventDrivenSuppliedName, 0)		--V1.6
		, EventDrivenSuppliedAddress			= ISNULL(EventDrivenSuppliedAddress, 0)		--V1.6
		, EventDrivenSuppliedPhoneNumber		= ISNULL(EventDrivenSuppliedPhoneNumber, 0)		--V1.6	
		, EventDrivenSuppliedMobilePhone		= ISNULL(EventDrivenSuppliedMobilePhone, 0)		--V1.6

		, EventDrivenDealerExclusionListMatch	= ISNULL(EventDrivenDealerExclusionListMatch, 0)		--V1.10
		, EventDrivenPhoneSuppression			= ISNULL(EventDrivenPhoneSuppression, 0)				--V1.10
		, EventDrivenInvalidAFRLCode			= ISNULL(EventDrivenInvalidAFRLCode, 0)					--V1.10
		, EventDrivenInvalidSalesType			= ISNULL(EventDrivenInvalidSalesType, 0)				--V1.10	

		, EventDrivenPrevSoftBounce	            = ISNULL(EventDrivenPrevSoftBounce, 0)		--V1.19
		, EventDrivenPrevHardBounce	            = ISNULL(EventDrivenPrevHardBounce, 0)		--V1.19
		, EventDrivenSoftBounce	                = ISNULL(EventDrivenSoftBounce, 0)		    --V1.19
		, EventDrivenHardBounce	                = ISNULL(EventDrivenHardBounce, 0)		    --V1.19
		, EventDrivenUnsubscribes	            = ISNULL(EventDrivenUnsubscribes, 0)		--V1.19

		, EventDrivenContactPreferencesSuppression	            
												= ISNULL(EventDrivenContactPreferencesSuppression, 0)		--V1.29
		, EventDrivenContactPreferencesPartySuppress	            
												= ISNULL(EventDrivenContactPreferencesPartySuppress, 0)		--V1.29
		, EventDrivenContactPreferencesEmailSuppress	            
												= ISNULL(EventDrivenContactPreferencesEmailSuppress, 0)		--V1.29
		, EventDrivenContactPreferencesPhoneSuppress	            
												= ISNULL(EventDrivenContactPreferencesPhoneSuppress, 0)		--V1.29
		, EventDrivenContactPreferencesPostalSuppress	            
												= ISNULL(EventDrivenContactPreferencesPostalSuppress, 0)	--V1.29
		, EventDrivenPDIFlagSet					= ISNULL(EventDrivenPDIFlagSet, 0)		--V1.29
		
		, EventDrivenOriginalPartySuppression = ISNULL(EventDrivenOriginalPartySuppression, 0)		--V1.30
		, EventDrivenOriginalPostalSuppression =  ISNULL(EventDrivenOriginalPostalSuppression, 0)	--V1.30
		, EventDrivenOriginalEmailSuppression = ISNULL(EventDrivenOriginalEmailSuppression, 0)		--V1.30
		, EventDrivenOriginalPhoneSuppression =  ISNULL(EventDrivenOriginalPhoneSuppression, 0)		--V1.30	
		, EventDrivenOtherExclusion = ISNULL(EventDrivenOtherExclusion, 0) -- V1.32
		, EventDrivenSuppliedEmail	= ISNULL(EventDrivenSuppliedEmail, 0)	--V1.38
		, EventDrivenInvalidDateOfLastContact = ISNULL(EventDrivenInvalidDateOfLastContact, 0)	--V1.39

		

		------------------------------------------------------------------------------------------------
		--
		--  POPULATE MONTHLY RESPONSE REPORT	v1.12
		--
		------------------------------------------------------------------------------------------------
		IF @TimePeriod = 'MTH'
		
		BEGIN
			;WITH	Responses_cte (TotalResponses, Brand, Market, Questionnaire)

			AS	
			(	
					SELECT		Count (Distinct cs.CaseID) TotalResponses,
								md.Brand,
								md.Market,
								md.Questionnaire
					FROM		[$(SampleDB)].[Event].[Cases] cs
					INNER JOIN  [$(SampleDB)].Event.AutomotiveEventBasedInterviews AEBI			ON cs.CaseID = AEBI.CaseID
					INNER JOIN	[$(SampleDB)].Event.Events ev									ON AEBI.EventID = ev.EventID 
					INNER JOIN	[$(SampleDB)].Requirement.SelectionCases SC						ON cs.CaseID = SC.CaseID
					INNER JOIN  [$(SampleDB)].Requirement.RequirementRollups rr					ON SC.RequirementIDPartOf = rr.RequirementIDMadeUpOf
					INNER JOIN	[$(SampleDB)].[dbo].[vwBrandMarketQuestionnaireSampleMetadata] md	on rr.RequirementIDPartOf = md.QuestionnaireRequirementID
		 
					WHERE		CS.ClosureDate >= @StartDate AND CS.ClosureDate < @EndDate 
		
		
					group by	md.Brand,
								md.Market,
								md.Questionnaire
			) 


			UPDATE	SR 
			SET			[EventsLoaded]		= T.EventsLoaded,
						[TotalResponses]	= T.TotalResponses,
						[InvitesSent]		= T.InvitesSent,
						[EmailInvites]		= T.EmailInvites,
						[SMSInvites]		= T.SMSInvites,
						[PostalInvites]		= T.PostalInvites,
						[PhoneInvites]		= T.PhoneInvites,			-- V1.10
						[GeneratedDate]		= GETDATE()

			FROM	[SampleReport].[SummaryResponses] SR

			INNER JOIN 
			(			
					SELECT
						B.Brand,
						B.Market,
						B.Questionnaire,
						COUNT(*) AS EventsLoaded,
						ISNULL(cte.TotalResponses,0) TotalResponses,
						--SUM(ISNULL(B.UsableFlag, 0)) AS UsableEvents,
						SUM(ISNULL(B.SentFlag, 0)) AS InvitesSent,
						--SUM(ISNULL(B.BouncebackFlag, 0)) AS Bouncebacks,
						SUM(CASE WHEN B.CaseOutputType = 'Online' THEN 1 ELSE 0 END) AS EmailInvites,
						SUM(CASE WHEN B.CaseOutputType = 'SMS'    THEN 1 ELSE 0 END) AS SMSInvites,
						SUM(CASE WHEN B.CaseOutputType = 'Postal' THEN 1 ELSE 0 END) AS PostalInvites,
						SUM(CASE WHEN B.CaseOutputType = 'Phone' THEN 1 ELSE 0 END) AS PhoneInvites			-- V1.10
					FROM [SampleReport].[Base] B
					LEFT JOIN Responses_cte cte		ON	B.Brand			= cte.brand AND
														B.Market		= cte.Market AND
														B.Questionnaire = cte.Questionnaire

					--INNER JOIN [SampleReport].[SummaryResponses] SR ON	B.Brand			= SR.Brand AND
					--													B.Market		= SR.Market AND
					--													B.Questionnaire	= SR.Questionnaire

					WHERE	(FileActionDate >= @StartDate AND FileActionDate < @EndDate)  
							--(SR.StartDate = @StartDate) AND
							--(SR.EndDate = @EndDate)

					GROUP BY B.Brand,
								B.Market,
								B.Questionnaire,
								cte.TotalResponses
			
		
			)	T ON	SR.Brand			= T.Brand AND
						SR.Market			= T.Market AND
						SR.Questionnaire	= T.Questionnaire AND 
						SR.StartDate		= @StartDate AND
						SR.EndDate			= @EndDate
				
		END
		
--V1.37
END
ELSE
BEGIN

	TRUNCATE TABLE SampleReport.IndividualRowsEvents;
	
	INSERT INTO SampleReport.IndividualRowsEvents 
			(SuperNationalRegion, BusinessRegion, DealerMarket, SubNationalTerritory, SubNationalRegion, CombinedDealer, DealerName, DealerCode, DealerCodeGDD, FullName, OrganisationName, AnonymityDealer, AnonymityManufacturer, CaseCreationDate, CaseStatusType, CaseOutputType, SentFlag, SentDate, RespondedFlag, ClosureDate, DuplicateRowFlag, BouncebackFlag, UsableFlag, ManualRejectionFlag, FileName, FileActionDate, FileRowCount, LoadedDate, AuditID, AuditItemID, MatchedODSPartyID, MatchedODSPersonID, LanguageID, PartySuppression, MatchedODSOrganisationID, MatchedODSAddressID, CountryID, PostalSuppression, EmailSuppression, MatchedODSVehicleID, ODSRegistrationID, MatchedODSModelID, OwnershipCycle, MatchedODSEventID, ODSEventTypeID, WarrantyID, Brand, Market, Questionnaire, QuestionnaireRequirementID, SuppliedName, SuppliedAddress, SuppliedPhoneNumber, SuppliedMobilePhone, SuppliedEmail, SuppliedVehicle, SuppliedRegistration, SuppliedEventDate, EventDateOutOfDate, EventNonSolicitation, PartyNonSolicitation, UnmatchedModel, UncodedDealer, EventAlreadySelected, NonLatestEvent, InvalidOwnershipCycle, RecontactPeriod, RelativeRecontactPeriod, InvalidVehicleRole, CrossBorderAddress, CrossBorderDealer, ExclusionListMatch, InvalidEmailAddress, BarredEmailAddress, BarredDomain, CaseID, SampleRowProcessed, SampleRowProcessedDate, WrongEventType, MissingStreet, MissingPostcode, MissingEmail, MissingTelephone, MissingStreetAndEmail, MissingTelephoneAndEmail, MissingMobilePhone, MissingMobilePhoneAndEmail, MissingPartyName, MissingLanguage, InvalidModel, InvalidManufacturer, InternalDealer, RegistrationNumber, RegistrationDate, VIN, OutputFileModelDescription, EventDate, SampleEmailAddress, CaseEmailAddress, PreviousEventBounceBack, EventDateTooYoung, AFRLCode, DealerExclusionListMatch, PhoneSuppression, SalesType, InvalidAFRLCode, InvalidSalesType, AgentCodeFlag,DataSource,HardBounce,SoftBounce,Unsubscribes, DateOfLeadCreation, PrevSoftBounce, PrevHardBounce,ServiceTechnicianID,ServiceTechnicianName,ServiceAdvisorName,ServiceAdvisorID,CRMSalesmanName,CRMSalesmanCode, FOBCode, ContactPreferencesSuppression, ContactPreferencesPartySuppress, ContactPreferencesEmailSuppress, ContactPreferencesPhoneSuppress, ContactPreferencesPostalSuppress, SVCRMSalesType, SVCRMInvalidSalesType, DealNumber, RepairOrderNumber, VistaCommonOrderNumber, SalesEmployeeCode, SalesEmployeeName, ServiceEmployeeCode, ServiceEmployeeName, RecordChanged, PDIFlagSet,OriginalPartySuppression, OriginalPostalSuppression, OriginalEmailSuppression, OriginalPhoneSuppression, OtherExclusion, OverrideFlag, GDPRflag, SelectionPostalID, SelectionEmailID, SelectionPhoneID, SelectionLandlineID, SelectionMobileID, SelectionEmail, SelectionPhone, SelectionLandline, SelectionMobile, ContactPreferencesModel,ContactPreferencesPersist, InvalidDateOfLastContact, MatchedODSPrivEmailAddressID, SamplePrivEmailAddress, EmailExcludeBarred,EmailExcludeGeneric, EmailExcludeInvalid, CompanyExcludeBodyShop, CompanyExcludeLeasing, CompanyExcludeFleet, CompanyExcludeBarredCo, OutletPartyID, Dealer10DigitCode, OutletFunction, RoadsideAssistanceProvider, CRC_Owner, ClosedBy, Owner, CountryIsoAlpha2, CRCMarketCode, InvalidDealerBrand, SubBrand, ModelCode, LeadVehSaleType, ModelVariant) -- V1.12 -'AgentCodeFlag' added, V1.15, V1.16 - DateOfLeadCreation added, V1.18, V1.20, V1.21, v1.23, V1.24, V1.25, V1.27 , v1.29, V1.30, V1.32, V1.33, V1.34, V1.35, V1.36, V1.39, V1.40, V1.41, V1.43, V1.44, V1.45, V1.46, V1.47
	SELECT   SuperNationalRegion, BusinessRegion, DealerMarket, SubNationalTerritory, SubNationalRegion, CombinedDealer, DealerName, DealerCode, DealerCodeGDD, FullName, OrganisationName, AnonymityDealer, AnonymityManufacturer, CaseCreationDate, CaseStatusType, CaseOutputType, SentFlag, SentDate, RespondedFlag, ClosureDate, DuplicateRowFlag, BouncebackFlag, UsableFlag, ManualRejectionFlag, FileName, FileActionDate, FileRowCount, LoadedDate, AuditID, AuditItemID, MatchedODSPartyID, MatchedODSPersonID, LanguageID, PartySuppression, MatchedODSOrganisationID, MatchedODSAddressID, CountryID, PostalSuppression, EmailSuppression, MatchedODSVehicleID, ODSRegistrationID, MatchedODSModelID, OwnershipCycle, MatchedODSEventID, ODSEventTypeID, WarrantyID, Brand, Market, Questionnaire, QuestionnaireRequirementID, SuppliedName, SuppliedAddress, SuppliedPhoneNumber, SuppliedMobilePhone, SuppliedEmail, SuppliedVehicle, SuppliedRegistration, SuppliedEventDate, EventDateOutOfDate, EventNonSolicitation, PartyNonSolicitation, UnmatchedModel, UncodedDealer, EventAlreadySelected, NonLatestEvent, InvalidOwnershipCycle, RecontactPeriod, RelativeRecontactPeriod, InvalidVehicleRole, CrossBorderAddress, CrossBorderDealer, ExclusionListMatch, InvalidEmailAddress, BarredEmailAddress, BarredDomain, CaseID, SampleRowProcessed, SampleRowProcessedDate, WrongEventType, MissingStreet, MissingPostcode, MissingEmail, MissingTelephone, MissingStreetAndEmail, MissingTelephoneAndEmail, MissingMobilePhone, MissingMobilePhoneAndEmail, MissingPartyName, MissingLanguage, InvalidModel, InvalidManufacturer, InternalDealer, RegistrationNumber, RegistrationDate, VIN, OutputFileModelDescription, EventDate, SampleEmailAddress, CaseEmailAddress, PreviousEventBounceBack, EventDateTooYoung, AFRLCode, DealerExclusionListMatch, PhoneSuppression, SalesType, InvalidAFRLCode, InvalidSalesType, AgentCodeFlag,DataSource,HardBounce,[SoftBounce],Unsubscribes, DateOfLeadCreation, PrevSoftBounce, PrevHardBounce,ServiceTechnicianID,ServiceTechnicianName,ServiceAdvisorName,ServiceAdvisorID,CRMSalesmanName,CRMSalesmanCode, FOBCode, ContactPreferencesSuppression, ContactPreferencesPartySuppress, ContactPreferencesEmailSuppress, ContactPreferencesPhoneSuppress, ContactPreferencesPostalSuppress, SVCRMSalesType, SVCRMInvalidSalesType, DealNumber, RepairOrderNumber, VistaCommonOrderNumber, SalesEmployeeCode, SalesEmployeeName, ServiceEmployeeCode, ServiceEmployeeName, RecordChanged, PDIFlagSet,OriginalPartySuppression, OriginalPostalSuppression, OriginalEmailSuppression, OriginalPhoneSuppression, OtherExclusion, OverrideFlag, GDPRflag, SelectionPostalID, SelectionEmailID, SelectionPhoneID, SelectionLandlineID, SelectionMobileID, SelectionEmail, SelectionPhone, SelectionLandline, SelectionMobile, ContactPreferencesModel,ContactPreferencesPersist, InvalidDateOfLastContact, MatchedODSPrivEmailAddressID, SamplePrivEmailAddress, EmailExcludeBarred,EmailExcludeGeneric, EmailExcludeInvalid, CompanyExcludeBodyShop, CompanyExcludeLeasing, CompanyExcludeFleet, CompanyExcludeBarredCo, OutletPartyID, Dealer10DigitCode, OutletFunction, RoadsideAssistanceProvider, CRC_Owner, ClosedBy, Owner, CountryIsoAlpha2, CRCMarketCode, InvalidDealerBrand, SubBrand, ModelCode, LeadVehSaleType, ModelVariant  -- V1.12 -'AgentCodeFlag' added, V1.15, V1.16 - DateOfLeadCreation added, V1.18, V1.20, V1.21, v1.23, V1.24, V1.25, V1.27 , v1.29, V1.30, V1.32, V1.33, V1.34, V1.35, V1.36, V1.39, V1.40, V1.41, V1.43, V1.44, V1.45, V1.46, V1.47
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
