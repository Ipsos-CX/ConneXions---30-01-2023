CREATE PROCEDURE [SampleReport].[uspGenerateBaseData]
    @Brand NVARCHAR(510) ,
    @MarketRegion VARCHAR (200), 
	@Questionnaire VARCHAR (255), 
	@ReportType VARCHAR(200), 
    @ReportDate DATETIME ,
    @EchoFeed BIT = 0, 
    @DailyEcho BIT = 0,
    @EchoFeed12mthRolling BIT = 0
AS
    SET NOCOUNT ON;

    DECLARE @ErrorNumber INT;
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;
    DECLARE @ErrorLocation NVARCHAR(500);
    DECLARE @ErrorLine INT;
    DECLARE @ErrorMessage NVARCHAR(2048);

    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    BEGIN TRY


/*
	Purpose:	Builds the base table from which the various sub reports area generated from
		
	Release		Version		Date				Developer			Comment
	LIVE		1.0			11/07/2013			Chris Ross			Created
	LIVE		1.1			17/10/2013			Martin Riverol		Amended BounceBack flagging mechanism (BUG# 9538)
	LIVE		1.2			13/11/2013			Martin Riverol		#9633 - Add supplied dealer code to DealerCode column for events not coded	with a dealer
	LIVE		1.3			02/12/2013			Martin Riverol		Force RespondedFlag = NULL as opposed to Zero when their is no closure date
	LIVE		1.4			24/01/2014			Chris Ross			9751 -  Add new columns: SuppliedMobilePhone, MissingMobilePhone, MissingMobilePhoneAndEmail, CaseOutputType, 
																	SuppliedEmail, CaseEmail
	LIVE		1.5			14/05/2014			Ali Yuksel			BUG 10346 - MissingPartyName  added
	LIVE		1.6			09/06/2014			Martin Riverol		BUG 10302 - Date range amendments to facilitate the Echo Feed (i.e. All Sample up to run date as opposed to EOPM)
	LIVE		1.7			16/10/2014			Chris Ross			BUG 10835 - Add in On-line Rejection to bounceback - checking that there is actually an email associated with the case.
	LIVE		1.8			15/12/2014			Eddie Thomas		BUG 11047 - Add PreviousEventBounceBack	& EventDateTooYoung 
	LIVE		1.9			22/01/2015			Peter Doyle			Deal with null on EventDateTooYoung (column is not null)?
	LIVE		1.10		29/01/2015			Peter Doyle			BUG 11207 - Force Echo reports to look at last year's data when reports are run in the 1st quarter of current year.
	LIVE		1.11		27/02/2015			Chris Ross			BUG 11026 - Add in BusinessRegion column
	LIVE		1.12		05/08/2015			Peter Doyle			BUG 11741 - Fix on Fullname processing for Romania
	LIVE		1.13		26/08/2015			Chris Ledger		BUG 11658 - Addition of Roadside (major change for regions)
	LIVE		1.14		11/11/2015			Chris Ledger		BUG 11658 - Removal of Duplicate Files from Sample Reports
	LIVE		1.15		29/01/2016			Chris Ross			BUG 12038 - Add in PreOwned functionID based on Questionnaire
	LIVE		1.16		22/02/2016			Chris Ledger		BUG 12395 - Sample Reports Amendments
	LIVE		1.17		22/04/2016			Chris Ledger		Change Echo @StartYearDate to only show this year's data
	LIVE		1.18		11/07/2016			Eddie Thomas		BUG 12811 - Monthly Response Report
	LIVE		1.19        19/07/2016          Ben King            BUG 12853 - CRC sample reporting raw files
	LIVE		1.20		04/08/2016			Ben King			BUG 12919 - Sample reports - rejection flags change
	LIVE		1.21		10/08/2016			Ben King			BUG 12861 - Roadside Sample reporting - Echo raw files. Add field 'DataSource' to Echo output files.
	LIVE		1.22		30/09/2016			Ben King			BUG 13116 - Sample reports - rejection flag correction (September 2016)
	LIVE		1.23		18/10/2016			Chris Ross			BUG 13171 - Add in SubNationalTerritory column
	LIVE		1.24		14/11/2016			Ben King			BUG 13312 - Flag DedupeEqualToEvents flag
	LIVE		1.25		15/11/2016			Ben King			BUG 13314 - add seperate flag for HardBounce & SoftBounce.
	LIVE		1.26		15/11/2016			Ben King			BUG 13314 - SEPERATE 'Customer Unsubscription'  PARTY-NONSOLICITATIONS
	LIVE		1.27		23/11/2016			Chris Ross			BUG 13344 - Add new in column: DateOfLeadCreation
	LIVE		1.28		24/11/2016			Ben King			BUG 13358 - Add Previous Hard & Soft bounce back flags	
	LIVE		1.29		25/01/2017			Ben King			BUG 13511 - Adding Dealer info to sampleReports: CRC,Roadside & Lost Leads	
	LIVE		1.30		01/02/2017			Ben King			BUG 13546 - Add US Employee Fields to Echo reports	
	LIVE		1.31		02/02/2017			Chris Ross			BUG 13549 - Add in alternative North America model and model variant values.
	LIVE		1.32		16/02/2017			Ben King			BUG 13600 - Echo/Sample reports change: SoftBounceFlag
	LIVE		1.33		23/03/2017			Ben King			BUG 13465 - Add FOBCode to Echo & SampleReports (individual Sheet)
	LIVE		1.34		25/04/2017			Chris Ross			BUG 13364 - Modify Unsubscribe cout to use ContactOutcome file.  
																	Also, include the 5 new suppressions flags in the base table.
	LIVE		1.35		17/05/2017			Ben King			BUG 13933 & 13884 - Add fields SVCRMSalesType, SVCRMInvalidSalesType, DealNumber, RepairOrderNumber, VistaCommonOrderNumber		
	LIVE		1.36		24/05/2017			Ben King			BUG 13950 - Echo reporting change - employee reporting for generic roles	
	LIVE		1.37		30/05/2017			Ben King			BUG 13942 - Echo Sample Reporting on a Daily Basis - superceded by V1.40 - Removed.	
	LIVE		1.38		31/05/2017			Ben King			BUG 13985 - Echo Report Changes: Add AuditItemID and correct Sales codes & Names variables.
	LIVE		1.39		20/06/2017          Ben King			BUG 14033 - Add Field RecordChanged to Echo output
	LIVE		1.40		25/07/2017			Ben King			BUG 14098 - Calculate RecordChanged field for YTD files & Daily files		
	LIVE		1.41		07/09/2017			Chris Ross			BUG 14122 - Add in PDIFlagSet column
	LIVE		1.42		08/09/2017			Eddie Thomas		BUG 14141 - New Bodyshop questionnaire
	LIVE		1.43		18/10/2017			Ben King			BUG 14324 - SV-CRM Sales Type sample reporting
	LIVE		1.44		14/11/2017			Ben King			BUG 14379 - New Suppression Logic_for Sample Reporting Purposes
	LIVE		1.45		21/12/2017			Ben King			BUG 14455 - Anonymity on Sample reporting website
	LIVE		1.46		11/01/2018			Ben King			BUG 14488 - 90 day response capture into 2018
	LIVE		1.47		19/01/2018			Ben King			BUG 14493 - Add anonymous flags to echo output (Add 2 fields (AnonymityDealer	, AnonymityManufacturer)  to 'ConcatenatedData' field as ouput in Echo)
	LIVE		1.48		19/01/2018			Ben King			BUG 14487 - Sample Reporting _Other column
	LIVE		1.49		07/02/2018			Ben King			BUG 14541 - Echo BUG fix - DealerCodeGDD blank in output
	LIVE		1.50		14/02/2018			Ben King			BUG 14546 - Sample & Echo reporting - Update Customer Prefs values at CaseId generated point
	LIVE		1.51		29/12/2017			Chris Ross			BUG 14200 - Add in the new ContactPreferencesUnsubscribe value from the logging table (still calc as previously for records before bug release date)
	LIVE		1.52		14/03/2018			Ben King			BUG 14486 - Customer Preference Override Flag
	LIVE		1.53		12/04/2018			Ben King			BUG 14635 - Retain Selection Rollbacks CaseId's (NOT LIVE)
	LIVE		1.54		20/04/2018			Ben King			BUG 14682 - 14682 - UK Purchase - unusable sample being flagged as invalid SV-CRM sales type
	LIVE		1.55		20/04/2018			Ben King			BUG 14658 - Sample Event Reports_ Date Sent Issue
	LIVE		1.56		01/05/2018			Ben King			BUG 14669 - GDPR New Flag_ Sample Reporting
	LIVE		1.57		08/05/2018			Ben King			BUG 14651 - Sample reporting load failure? (PERFORMANCE IMPROVEMENT)
	LIVE		1.58		08/08/2018			Ben King			BUG 14906 - Update Echo reoprts to check for change in DealePartyID
	LIVE		1.59		03/10/2018			Ben King			BUG 15012 - Party Non-Sol flag (sample & echo reporting)
	LIVE		1.60		03/10/2018			Ben King			BUG 15021 - Sample report Brazil change
	LIVE		1.61		05/10/2018			Ben King			BUG 15017 - Add ContactMechanismID's
	LIVE		1.62		28/11/2018			Chris Ledger		Replace Variables from Commented Out Code to Allow Comparison to Match
	LIVE		1.63		17/12/2018			Ben King			BUG 15125 - Historical suppression flag logic alteration
	LIVE		1.64		08/01/2018			Ben King			BUG 15120 - Sample reporting - Memory issue when running USA YTD report
	LIVE		1.65		16/01/2019			Ben King			BUG 15192 - Sample reporting - change to date showing on website
	LIVE		1.66		28/01/2019			Ben King			BUG 15227 - 12 month Static rolling extract report
	LIVE		1.67		05/02/2019			Ben King			BUG 15216 - V1.8 fix
	LIVE		1.68		15/02/2019			Ben King			BUG 15126 - add new exclusion flag InvalidDateOfLastContact to echo/sample reports
	LIVE		1.69		15/02/2019			Ben King			BUG 15211 - add MatchedODSPrivEmailAddressID
	LIVE		1.70		17/04/2019			Ben King			BUG 15192 - Sample reporting - change to date showing on website - link to selection output date
	LIVE		1.71		15/07/2019			Ben King			BUG 15454 - Sample Reporting - Preowned Sales Employee fields
	LIVE		1.72		29/10/2019			Chris Ledger		BUG 15490 - Add PreOwned LostLeads
	LIVE		1.73		04/12/2019			Ben King			BUG 16754 - Update DedupeEqualToEvents to refer back to YTD date range during daily run
	LIVE		1.74		11/12/2019			Ben King			BUG 15437 - correct usable flag and sent date for records not output
	LIVE		1.75		03/01/2020			Ben King			BUG 16864 - Add exclusion category flags
	LIVE		1.76        14/02/2020			Ben King			BUG 16909 - AgentCodeFlag logic change
	LIVE		1.77		26/02/2020			Ben King			BUG 16676 - add ReExported field to YearlyEchoHistoryRecordChanged logging/Inserts
	LIVE		1.78		01/04/2020			Chris Ledger		BUG 15372 - Fix hard coded database references and cases
	LIVE		1.79		02/02/2021			Ben King			BUG 18093 - add 10digit code (plus other fields)
	LIVE		1.80		10/03/2021			Ben King			BUG 18128 - Sample Reporting: Filter on "Core" markets when base table builds
	LIVE		1.81		26/03/2021			Ben King			BUG 18158 - Add the crc agent cdsid field to sample reports feed
	LIVE		1.82        20/04/2021          Ben King            BUG 18184 - Update Manual Rejection Flag - Samplereporting
	LIVE		1.83        23/04/2021          Ben King            BUG 18188 - Medallia Sample reporting files - update needed to PII (N/A) fields to not be blanked out
	LIVE		1.84        12/05/2021          Ben King            BUG 18214 - Sample reporting - update SVCRMInvalidSalesType flag
	LIVE		1.85		10/06/2021			Ben King			TASK 474 - Japan Purchase - Mismatch between Dealer and VIN
	LIVE		1.86		17/06/2021			Ben King			TASK 495 - Sample reporting for General Enquiries
	LIVE		1.87        20/07/2021          Ben King            TASK 557 - Blank applicable employee data for specific markets for Medalia 
	LIVE		1.88		24/08/2021			Chris Ledger		Fix object reference
	LIVE		1.89        21/09/2021          Ben King            TASK 609 - Spain events with event too young issue in sample reporting
	LIVE		1.90        21/03/2022          Ben King            TASK 823 - 19465 - Irish Records selected with exclusion reason
	LIVE		1.91		16/06/2022			Ben King			TASK 914 - 19515 - Removal of PII from Invalid VINs
	LIVE		1.92		28/09/2022			Eddie Thomas		TASK 1017 - Adding in SubBrand
	LIVE		1.93		05/10/2022			Eddie Thomas		TASK 926 - Adding ModelCode & ModelDescription
	LIVE		1.94		14/10/2022			Eddie Thomas		TASK 1064 - Adding LeadVehSaleType & ModelVariant
	LIVE		1.95		28/10/2022			Ben King			TASK 1053 - 19616 - Sample Health - clear out reasons for non selections for duplicates
	CL CHECKED OUT
	*/

	-- TEST PARAMETERS
	--DECLARE @Brand NVARCHAR (510) = 'Land Rover'
	--DECLARE @MarketRegion VARCHAR (200) = 'United Kingdom'
	--DECLARE @Questionnaire VARCHAR (255) = 'Roadside'
	--DECLARE @ReportType VARCHAR(200) = 'Market'
	--DECLARE @ReportDate DATETIME = '2015-07-20'
	--DECLARE @EchoFeed BIT = 0


	-- Get start and end dates to select the previous month 
        DECLARE @LastMonthDate DATETIME ,
            @StartMonthDate DATETIME ,
            @StartYearDate DATETIME ,
            @EndDate DATETIME;

 --V1.66 - IF RUNNING 12 MONTHS ROLLING, SKIP BULK PROCESSING. DATA ALREADY STORED IN TBL YearlyEchoHistory
 IF @EchoFeed12mthRolling <> 1
	BEGIN
        SELECT  @LastMonthDate = DATEADD(dd, 0,
                                         DATEDIFF(dd, 0,
                                                  DATEADD(m, -1, @ReportDate))); -- Also remove time

        SELECT  @StartMonthDate = DATEADD(dd, 1,
                                          DATEADD(dd, -( DAY(@LastMonthDate) ),
                                                  @LastMonthDate)); --First day of this Month
	
        IF @EchoFeed = 1
		-- Echo reports used to need to show previous year's data (removed but leave in old code in case need to rerun) V1.17
            BEGIN
				SELECT  @LastMonthDate = DATEADD(dd, 0,
                                         DATEDIFF(dd, 0,
                                                  DATEADD(m, -3, @ReportDate))); --V1.46 (Jan,Feb,March also refer to entire previous years data 
																					--    when YTD run, April forward only pools current year)
            
				--SELECT  @StartYearDate = DATEADD(YEAR,
                                             --DATEDIFF(YEAR, 0, @ReportDate)
                                             --- 1, 0);

				-- V1.95 UPDATED YTD TO RUN LAST 3 MONTHS. THIS HAS BEEN REMOVED - USED TO RUN AS PER V1.46
                --SELECT  @StartYearDate = CONVERT(DATETIME, CONVERT(VARCHAR(8), DATEPART(YEAR,
                --                                              @LastMonthDate))
                --        + '0101'); --First day of the year

				SELECT  @StartYearDate = DATEADD(dd, 0,
                                         DATEDIFF(dd, 0,
                                                  DATEADD(m, -3, @ReportDate)))

           END;
        ELSE
            BEGIN
                SELECT  @StartYearDate = CONVERT(DATETIME, CONVERT(VARCHAR(8), DATEPART(YEAR,
                                                              @LastMonthDate))
                        + '0101'); --First day of the year
            END;

	--SELECT @StartYearDate = CONVERT(DATETIME, CONVERT(VARCHAR(8), DATEPART(YEAR, @LastMonthDate)) + '0101') --First day of the year
	
        IF @EchoFeed = 1 -- BUG 10302. Output sample received to date 
            SELECT  @EndDate = DATEADD(DD, 0, DATEDIFF(dd, 0, @ReportDate) + 1);
        ELSE
            SELECT  @EndDate = DATEADD(dd,
                                       -( DAY(DATEADD(mm, 1, @LastMonthDate))
                                          - 1 ),
                                       DATEADD(mm, 1, @LastMonthDate)); --First Day of Next Month
	
	    ----------------------------------------------------------------------------------------
		-- Echo Sample Reporting on a Daily Basis			v1.37
		----------------------------------------------------------------------------------------


IF @DailyEcho = 1
	BEGIN	
		
		SELECT  @EndDate = DATEADD(DD, 0, DATEDIFF(dd, 0, @ReportDate) + 1)
	
		DECLARE @DayNumber INT
		SELECT @DayNumber = DATEPART(WEEKDAY,@ReportDate) 
		  
			IF @DayNumber =  1 
				SELECT @StartYearDate = DATEADD(DD, 0, DATEDIFF(dd, 0, @EndDate) -7) --'SUNDAY' 
			ELSE IF @DayNumber = 2
			BEGIN
				SELECT @StartYearDate = DATEADD(DD, 0, DATEDIFF(dd, 0, @EndDate) -1) --'MONDAY' 
				--TRUNCATE TABLE SampleReport.WeeklyEchoHistory
			END	
			ELSE IF @DayNumber = 3		
				SELECT @StartYearDate = DATEADD(DD, 0, DATEDIFF(dd, 0, @EndDate) -2) --'TUESDAY' 
			ELSE IF @DayNumber = 4
				SELECT @StartYearDate = DATEADD(DD, 0, DATEDIFF(dd, 0, @EndDate) -3) --'WEDNESDAY'
			ELSE IF @DayNumber = 5
				SELECT @StartYearDate = DATEADD(DD, 0, DATEDIFF(dd, 0, @EndDate) -4) --'THURSDAY' 
			ELSE IF @DayNumber = 6
				SELECT @StartYearDate = DATEADD(DD, 0, DATEDIFF(dd, 0, @EndDate) -5) --'FRIDAY' 
			ELSE 
				SELECT @StartYearDate = DATEADD(DD, 0, DATEDIFF(dd, 0, @EndDate) -6) --'SATURDAY' 
			
	END
		
	---------------------------------------------------------------------------------------- 
    -- Get system values 
    ----------------------------------------------------------------------------------------
	DECLARE @NewSuppressionLogicDate DATE,
			@NewOtherExclusion DATE,
			@NewUnsubscribeLoggingFlag DATETIME2,
			@PartyNonSolicitationFlag DATE,
			@CustomerPrefReCalc DATE,
			@CaseSentDateReCalc DATE,
			@CaseSentDateReCalc_V2 DATE,
			@PreownedEmployeeData DATE,
			@EventDateTooYoung DATE,
			@SuppliedEventDate DATE
	
	SELECT @NewSuppressionLogicDate = BUG_13364_NewSuppressionLogic,
		   @NewOtherExclusion = BUG_14487_NewOtherExclusionFlag,
		   @NewUnsubscribeLoggingFlag = BUG_14200_NewUnsubscribeLoggingFlag,
		   @PartyNonSolicitationFlag = BUG_15012_PartyNonSolicitationFlag,
		   @CustomerPrefReCalc = BUG_15125_CustomerPrefReCalc,
		   @CaseSentDateReCalc = BUG_15192_CaseSentDateReCalc,
		   @CaseSentDateReCalc_V2 = BUG_15192_CaseSentDateReCalc_V2,
		   @EventDateTooYoung = BUG_18325_EventDateTooYoung,
		   @SuppliedEventDate = TASK_823_SuppliedEventDate

	FROM   [SampleReport].[SystemValues]
	
	-- Get the switch over date for CRM VEH_SALE_TYPE_DESC to stop being used and Sale Type Code checks to be used instead.   -- V1.54
		DECLARE @CRMSaleTypeCheckSwitchDate DATE
		SELECT @CRMSaleTypeCheckSwitchDate = CRMSaleTypeCheckSwitchDate FROM [$(SampleDB)].Selection.System
		
	----------------------------------------------------------------------------------------
	-- Monthly Response Totals			v1.18
	----------------------------------------------------------------------------------------

	--INSERT RECORDS FOR MARKETS WE WILL ADD RESPONSE COUNTS TOO
	;WITH NewResponseRPT_CTE (Brand, Market, Questionnaire, StartDate, EndDate)
	AS
	(
		SELECT  B.Brand, M.Market, Q.Questionnaire, @StartMonthDate AS StartDate, @EndDate AS EndDate 
		FROM [$(SampleDB)].[dbo].BrandMarketQuestionnaireMetadata BMQ
		INNER JOIN [$(SampleDB)].[dbo].Brands B ON BMQ.BrandID = B.BrandID
		INNER JOIN [$(SampleDB)].[dbo].Markets M ON BMQ.MarketID = M.MarketID
		INNER JOIN [$(SampleDB)].[dbo].Questionnaires Q ON BMQ.QuestionnaireID = Q.QuestionnaireID
		LEFT JOIN [$(SampleDB)].[dbo].Regions R ON M.RegionID = R.RegionID
		WHERE 
		SampleLoadActive = 1
		AND (SampleReportOutput = 1 OR SampleEventReportOutput = 1)
	)


	INSERT SampleReport.SummaryResponses ( Brand, Market, Questionnaire, StartDate, EndDate)

	SELECT		CTE.Brand, CTE.Market, CTE.Questionnaire, CTE.StartDate, CTE.EndDate
	FROM		NewResponseRPT_CTE CTE
	LEFT JOIN	SampleReport.SummaryResponses SR ON		CTE.Brand			= SR.Brand AND
														CTE.Market			= SR.Market AND
														CTE.Questionnaire	= SR.Questionnaire AND
														CTE.StartDate		= SR.StartDate AND
														CTE.EndDate			= SR.EndDate

	WHERE		SR.StartDate IS NULL
	ORDER BY	CTE.Brand, CTE.Market, CTE.Questionnaire
	
	
	
	----------------------------------------------------------------------------------------
	-- Build base table
	----------------------------------------------------------------------------------------

        TRUNCATE TABLE SampleReport.Base;

		-- ADD REGION TO Temporary Table
		IF (OBJECT_ID('tempdb..#MarketRegion') IS NOT NULL)
		BEGIN
			DROP TABLE #MarketRegion
		END

		CREATE TABLE #MarketRegion
			(
				Market varchar (200) ,
				Region varchar(200)
			)
		
				
		INSERT INTO #MarketRegion
		SELECT M.Market, R.Region
		FROM [$(SampleDB)].[dbo].Markets M 
		INNER JOIN [$(SampleDB)].[dbo].Regions R ON M.RegionID = R.RegionID
		GROUP BY M.Market, R.Region
		
		--V1.57
		--Ensure Execution plan is recalulated, avoid previous execution plan stored in Cache being applied.
		--Prevenents parallelism within execustion plan that can cause locks.
		DECLARE @DBID AS INT

		SELECT @DBID =  db_id ('SAMPLEREPORTING')
		DBCC FLUSHPROCINDB(@DBID)
				
        INSERT  INTO SampleReport.Base
                ( [ReportDate] ,
	   			  [BusinessRegion]		,			-- V1.13 Pick Up BusinessRegion from Region
                  [FileName] ,
                  FileActionDate ,
                  FileRowCount ,
                  [LoadedDate] ,
                  [AuditID] ,
                  [AuditItemID] ,
                  [MatchedODSPartyID] ,
                  [MatchedODSPersonID] ,
                  [LanguageID] ,
                  [PartySuppression] ,
                  [MatchedODSOrganisationID] ,
                  [MatchedODSAddressID] ,
                  [CountryID] ,
                  [PostalSuppression] ,
                  [EmailSuppression] ,
                  [MatchedODSVehicleID] ,
                  [ODSRegistrationID] ,
                  [MatchedODSModelID] ,
                  [OwnershipCycle] ,
                  [MatchedODSEventID] ,
                  [ODSEventTypeID] ,
                  [WarrantyID] ,
                  [Brand] ,
                  [Market] ,
                  [Questionnaire] ,
                  [QuestionnaireRequirementID] ,
                  [SuppliedName] ,
                  [SuppliedAddress] ,
                  [SuppliedPhoneNumber] ,
                  [SuppliedMobilePhone] ,				-- v1.4
                  [SuppliedEmail] ,
                  [SuppliedVehicle] ,
                  [SuppliedRegistration] ,
                  [SuppliedEventDate] ,
                  [EventDateOutOfDate] ,
                  [EventNonSolicitation] ,
                  [PartyNonSolicitation] ,
                  [UnmatchedModel] ,
                  [UncodedDealer] ,
                  [EventAlreadySelected] ,
                  [NonLatestEvent] ,
                  [InvalidOwnershipCycle] ,
                  [RecontactPeriod] ,
                  [RelativeRecontactPeriod] ,
                  [InvalidVehicleRole] ,
                  [CrossBorderAddress] ,
                  [CrossBorderDealer] ,
                  [ExclusionListMatch] ,
                  [InvalidEmailAddress] ,
                  [BarredEmailAddress] ,
                  [BarredDomain] ,
                  [CaseID] ,
                  [SampleRowProcessed] ,
                  [SampleRowProcessedDate] ,
                  [WrongEventType] ,
                  [MissingStreet] ,
                  [MissingPostcode] ,
                  [MissingEmail] ,
                  [MissingTelephone] ,
                  [MissingStreetAndEmail] ,
                  [MissingTelephoneAndEmail] ,
                  [MissingMobilePhone] ,					-- v1.4
                  [MissingMobilePhoneAndEmail] ,			-- v1.4
                  [MissingPartyName] ,						-- v1.5
                  [MissingLanguage] ,
                  [InvalidModel] ,
                  [InvalidManufacturer] ,
                  [InternalDealer] ,
                  RegistrationNumber ,
                  RegistrationDate ,
                  VIN ,
                  OutputFileModelDescription ,
                  EventDate ,
                  MatchedODSEmailAddressID ,			-- v1.4
				--PreviousEventBounceBack,				-- v1.8
                  EventDateTooYoung,					-- v1.8
                  PhysicalFileRow,						-- V1.14 
                  DuplicateFileFlag,					-- V1.14
				  DealerExclusionListMatch,				-- V1.16
				  PhoneSuppression,						-- V1.16
				  InvalidAFRLCode,						-- V1.16
				  InvalidSalesType,						-- V1.16
				  AgentCodeFlag,	                    -- V1.19
				  DataSource,							-- V1.21
				  
				  ServiceTechnicianID,					-- V1.30
				  ServiceTechnicianName,				-- V1.30
				  ServiceAdvisorName,				    -- V1.30
				  ServiceAdvisorID,				        -- V1.30
				 
				  CRMSalesmanName,		                -- V1.30
				  CRMSalesmanCode, 			            -- V1.30
				  
				  FOBCode,	    -- V1.33
				  ContactPreferencesSuppression,		-- v1.34	
				  ContactPreferencesPartySuppress,		-- v1.34	
				  ContactPreferencesEmailSuppress,		-- v1.34
				  ContactPreferencesPhoneSuppress,		-- v1.34
				  ContactPreferencesPostalSuppress,		-- v1.34
				  Unsubscribes,							-- v1.51
				  
				  SVCRMSalesType,						-- v1.35
				  SVCRMInvalidSalesType,                -- v1.35
				  DealNumber,                           -- v1.35
				  RepairOrderNumber,                    -- v1.35
                  VistaCommonOrderNumber,               -- v1.35
                  
                  SalesEmployeeCode,					-- v1.36
                  SalesEmployeeName,					-- v1.36
				  ServiceEmployeeCode,					-- v1.36
				  ServiceEmployeeName,					-- v1.36
				  RecordChanged,						-- V1.39
				  
				  PDIFlagSet,							-- v1.41 
				  GDPRflag,								-- V1.56
				  DealerPartyID,						-- V1.58
				  SelectionPostalID,					-- V1.61
				  SelectionEmailID,						-- V1.61
				  SelectionPhoneID,						-- V1.61
				  SelectionLandlineID,					-- V1.61
				  SelectionMobileID,					-- V1.61
				  SelectionEmail,						-- V1.61
				  SelectionPhone,						-- V1.61
				  SelectionLandline,					-- V1.61
				  SelectionMobile,						-- V1.61
				  InvalidDateOfLastContact,             -- V1.68
				  MatchedODSPrivEmailAddressID,			-- V1.69
				  EmailExcludeBarred,                   -- V1.75
				  EmailExcludeGeneric,                  -- V1.75
				  EmailExcludeInvalid,                  -- V1.75
				  CompanyExcludeBodyShop,               -- V1.75
				  CompanyExcludeLeasing,                -- V1.75
				  CompanyExcludeFleet,                  -- V1.75
				  CompanyExcludeBarredCo,				-- V1.75
				  OutletPartyID,						-- V1.79
				  Dealer10DigitCode,					-- V1.79
                  OutletFunction,						-- V1.79
	              RoadsideAssistanceProvider,			-- V1.79
	              CRC_Owner,							-- V1.79
				  ClosedBy,								-- V1.79
				  Owner,								-- V1.79
				  CountryIsoAlpha2,						-- V1.79
				  CRCMarketCode,						-- V1.79
				  InvalidDealerBrand					-- V1.85
		        )
                SELECT  @ReportDate ,
						MR.Region	,				-- V1.13 Pick up BusinessRegion from Region
                        F.[FileName] ,
                        F.ActionDate ,
                        F.FileRowCount ,
                        SQ.[LoadedDate] ,
                        SQ.[AuditID] ,
                        SQ.[AuditItemID] ,
                        SQ.[MatchedODSPartyID] ,
                        SQ.[MatchedODSPersonID] ,
                        SQ.[LanguageID] ,
                        SQ.[PartySuppression] ,
                        SQ.[MatchedODSOrganisationID] ,
                        SQ.[MatchedODSAddressID] ,
                        SQ.[CountryID] ,
                        CASE 
							WHEN CMT.ContactMethodologyTypeID IN (3,4,5,7,8) THEN 0
							ELSE SQ.[PostalSuppression] END AS PostalSuppression ,		--V1.16
                        SQ.[EmailSuppression] ,
                        SQ.[MatchedODSVehicleID] ,
                        SQ.[ODSRegistrationID] ,
                        SQ.[MatchedODSModelID] ,
                        SQ.[OwnershipCycle] ,
                        SQ.[MatchedODSEventID] ,
                        SQ.[ODSEventTypeID] ,
                        SQ.[WarrantyID] ,
                        SQ.[Brand] ,
                        SQ.[Market] ,
                        SQ.[Questionnaire] ,
                        SQ.[QuestionnaireRequirementID] ,
                        SQ.[SuppliedName] ,
                        CASE
							WHEN SQ.Market = 'Brazil' AND SQ.Questionnaire = 'Roadside' THEN 1 --V1.60
							ELSE SQ.[SuppliedAddress] END AS SuppliedAddress,
                        CASE 
							WHEN CMT.ContactMethodologyTypeID IN (1,2,5,7,8)
							AND SQ.Market <> 'South Africa' AND SQ.Market <> 'Russian Federation' THEN 1 --V1.22 
							ELSE SQ.[SuppliedPhoneNumber] END AS SuppliedPhoneNumber,			--V1.16
                        CASE 
							WHEN CMT.ContactMethodologyTypeID IN (1,2,5)
							AND SQ.Market <> 'South Africa' AND SQ.Market <> 'Russian Federation' THEN 1 --V1.22
							ELSE SQ.[SuppliedMobilePhone] END AS SuppliedMobileNumber,			--V1.16
                        SQ.[SuppliedEmail] ,
                        SQ.[SuppliedVehicle] ,
                        SQ.[SuppliedRegistration] ,
                        SQ.[SuppliedEventDate] ,
                        SQ.[EventDateOutOfDate] ,
                        SQ.[EventNonSolicitation] ,
                        0 , --partyNonsolicitaion
                        SQ.[UnmatchedModel] ,
                        SQ.[UncodedDealer] ,
                        SQ.[EventAlreadySelected] ,
                        SQ.[NonLatestEvent] ,
                        SQ.[InvalidOwnershipCycle] ,
                        SQ.[RecontactPeriod] ,
                        SQ.[RelativeRecontactPeriod] ,
                        SQ.[InvalidVehicleRole] ,
                        SQ.[CrossBorderAddress] ,
                        SQ.[CrossBorderDealer] ,
                        SQ.[ExclusionListMatch] ,
                        SQ.[InvalidEmailAddress] ,
                        SQ.[BarredEmailAddress] ,
                        SQ.[BarredDomain] ,
                        SQ.[CaseID] ,
                        SQ.[SampleRowProcessed] ,
                        SQ.[SampleRowProcessedDate] ,
                        SQ.[WrongEventType] ,
                        SQ.[MissingStreet] ,
                        SQ.[MissingPostcode] ,
                        SQ.[MissingEmail] ,
                        CASE 
							WHEN CMT.ContactMethodologyTypeID IN (1,2,5,7,8) THEN 0
							ELSE SQ.[MissingTelephone] END AS MissingTelephone,				--V1.16
                        SQ.[MissingStreetAndEmail] ,
                        SQ.[MissingTelephoneAndEmail] ,
                        SQ.[MissingMobilePhone] ,			-- v1.4
                        SQ.[MissingMobilePhoneAndEmail] ,	-- v1.4
                        SQ.[MissingPartyName] ,				-- v1.5
                        SQ.[MissingLanguage] ,
                        SQ.[InvalidModel] ,
                        SQ.[InvalidManufacturer] ,
                        SQ.[InternalDealer] ,
                        MVE.RegistrationNumber ,
                        MVE.RegistrationDate ,
                        CASE WHEN LEN(V.VIN) = 20 AND SUBSTRING(V.VIN,18,1) = '_' 
							THEN SUBSTRING(V.VIN,1,17) 
							ELSE V.VIN 
                        END AS VIN ,
                        CASE WHEN SQ.[CountryID] IN (	SELECT mkt.CountryID FROM [$(SampleDB)].dbo.Regions r					-- v1.31
														INNER JOIN [$(SampleDB)].dbo.Markets mkt ON mkt.RegionID = r.RegionID
														WHERE r.Region = 'North America NSC') 
								THEN M.NorthAmericaModelDescription 
								ELSE M.OutputFileModelDescription END AS OutputFileModelDescription ,
                        E.EventDate ,
                        SQ.MatchedODSEmailAddressID ,		-- v1.4
			--ISNULL(sq.[PreviousEventBounceBack],0),		-- v1.8
                        ISNULL(SQ.[EventDateTooYoung], 0),	-- v1.9
                        SQ.PhysicalFileRow,						-- V1.14
                        0,									-- V1.14
                        SQ.DealerExclusionListMatch,		-- V1.16
                        CASE 
							WHEN CMT.ContactMethodologyTypeID IN (1,2,5) THEN 0
							ELSE ISNULL(SQ.PhoneSuppression,0) END AS PhoneSuppression,				-- V1.16
                        SQ.InvalidAFRLCode,					-- V1.16
                        SQ.InvalidSaleType,					-- V1.16
                        0,                                  -- V1.81
						RE.DataSource,						-- V1.21
						
						COALESCE(DRS.[DMS_TECHNICIAN_ID], AIF.TechnicianID,'') AS ServiceTechnicianID,		-- V1.30, --V1.38 (Updated)
						COALESCE(DRS.[DMS_TECHNICIAN], AIF.TechnicianName,'') AS ServiceTechnicianName,		-- V1.30, --V1.38 (Updated)
						COALESCE(DRS.[DMS_SERVICE_ADVISOR],AIF.ServiceAdvisorName,'') AS ServiceAdvisorName,	-- V1.30, --V1.38 (Updated)
						COALESCE(DRS.[DMS_SERVICE_ADVISOR_ID], AIF.ServiceAdvisorID,'') AS ServiceAdvisorID,	-- V1.30, --V1.38 (Updated)
				
						COALESCE(VCS.VISTACONTRACT_SALES_MAN_FULNAM, AIF.SalesAdvisorName,'') AS CRMSalesmanName,	    -- V1.30, --V1.38 (Updated)
						COALESCE(VCS.VISTACONTRACT_SALESMAN_CODE, AIF.SalesAdvisorID,'') AS CRMSalesmanCode,		    -- V1.30, --V1.38 (Updated)
						
						ISNULL(V.FOBCode, 0) AS FOBCode,													-- V1.33
					    ISNULL(ContactPreferencesSuppression, 0)    AS 	ContactPreferencesSuppression,		-- v1.34	
			 		    ISNULL(ContactPreferencesPartySuppress, 0)  AS 	ContactPreferencesPartySuppress,	-- v1.34	
			  		    ISNULL(ContactPreferencesEmailSuppress, 0)  AS 	ContactPreferencesEmailSuppress,	-- v1.34
					    ISNULL(ContactPreferencesPhoneSuppress, 0)  AS 	ContactPreferencesPhoneSuppress,	-- v1.34
					    ISNULL(ContactPreferencesPostalSuppress, 0) AS 	ContactPreferencesPostalSuppress,	-- v1.34
					    ISNULL(ContactPreferencesUnsubscribed, 0)	AS  ContactPreferencesUnsubscribed,		-- v1.51
					    
					    VCS.VEH_SALE_TYPE_DESC,																-- V1.35
					    CASE 
							WHEN (SQ.Market = 'UNITED KINGDOM' AND SQ.Questionnaire = 'SALES') 				-- V1.35
							AND VCS.VEH_SALE_TYPE_DESC IN ('Retail Sold','Small business fleet') THEN 0
							WHEN (SQ.Questionnaire <> 'SALES' OR SQ.Market <> 'UNITED KINGDOM') THEN 0																		-- V1.35																		        
							ELSE 1
						END AS SVCRMInvalidSalesType,
					    
						CSA.DealNumber,																		-- V1.35
						COALESCE(DRS.DMS_REPAIR_ORDER_NUMBER_UNIQUE, CSE.RO_NUM) AS RepairOrderNumber,		-- V1.35
						VCS.VISTACONTRACT_COMMON_ORDER_NUM,
																			                                -- V1.35
						CASE
							WHEN SQ.Questionnaire = 'Sales' AND VCS.AuditItemID IS NULL THEN AIF.SalesmanCode
							ELSE ''
							END As SalesEmployeeCode,
						CASE
							WHEN SQ.Questionnaire = 'Sales' AND VCS.AuditItemID IS NULL THEN AIF.Salesman 
							ELSE ''
						END AS  SalesEmployeeName,
						CASE
							WHEN SQ.Questionnaire IN ('Service','Bodyshop') AND DRS.AuditItemID IS NULL THEN AIF.SalesmanCode
							ELSE ''
						END AS  ServiceEmployeeCode,
						CASE
							WHEN SQ.Questionnaire IN ('Service','Bodyshop') AND DRS.AuditItemID IS NULL THEN AIF.Salesman
							ELSE ''
						END AS ServiceEmployeeName,
						
						0,																					-- V1.39
						
						SQ.PDIFlagSet,							-- v1.41 
						0,										-- V1.56
						COALESCE(NULLIF(SQ.SalesDealerID, 0), NULLIF(SQ.ServiceDealerID, 0), NULLIF(SQ.BodyshopDealerID,0)) AS DealerPartyID,  --V1.58
						SQ.SelectionPostalID,					-- V1.61
						SQ.SelectionEmailID,					-- V1.61
						SQ.SelectionPhoneID,					-- V1.61
						SQ.SelectionLandlineID,					-- V1.61
						SQ.SelectionMobileID,					-- V1.61
						NULL,									-- V1.61 selection email
						NULL,									-- V1.61 selection phone
						NULL,									-- V1.61 selection landline
						NULL,									-- V1.61 selection mobile
						CAST(SQ.InvalidDateOfLastContact AS INT),            -- V1.68
						SQ.MatchedODSPrivEmailAddressID,		-- V1.69
						0,										-- V1.75
						0,										-- V1.75
						0,										-- V1.75
						0,										-- V1.75
						0,										-- V1.75
						0,										-- V1.75
						0,										-- V1.75
						NULL AS OutletPartyID,					-- V1.79
				        NULL AS Dealer10DigitCode,				-- V1.79
                        NULL AS OutletFunction,					-- V1.79
						RE.RoadsideAssistanceProvider,          -- V1.79
						NULL AS CRC_Owner,						-- V1.79
						CRC.ClosedBy,							-- V1.79
				        CASE
							WHEN SQ.Questionnaire = 'CRC' THEN CRC.Owner
							WHEN SQ.Questionnaire = 'CRC General Enquiry' THEN GEE.EmployeeResponsibleName
							ELSE ''
						END AS Owner,							-- V1.79, V1.86
						NULL AS CountryIsoAlpha2,				-- V1.79
						CASE
							WHEN SQ.Questionnaire = 'CRC' THEN CRC.MarketCode 
							WHEN SQ.Questionnaire = 'CRC General Enquiry' THEN GEE.MarketCode
							ELSE ''
						END AS CRCMarketCode,					-- V1.79, V1.86
						SQ.InvalidDealerBrand					-- V1.85
					    
                FROM    [$(AuditDB)].[dbo].Files F
                        JOIN [$(AuditDB)].[dbo].IncomingFiles ICF ON ICF.AuditID = F.AuditID 
								-- ??				AND ICF.LoadSuccess = 1 
								-- ??				AND ICF.FileLoadFailureID IS NULL
					    JOIN [$(WebsiteReporting)].[dbo].[SampleQualityAndSelectionLogging] SQ					
							ON F.AuditID = SQ.AuditID 					
							AND	SQ.Brand = @Brand
							AND	SQ.Questionnaire = @Questionnaire 
						JOIN [$(SampleDB)].[dbo].Markets MK ON SQ.Market = MK.Market --V1.80
						JOIN #MarketRegion MR ON SQ.Market = MR.Market
							AND MR.Market = CASE @ReportType							-- V1.13 New Market Filter
								WHEN 'Market' THEN @MarketRegion ELSE MR.Market END
							AND MR.Region = CASE @ReportType							-- V1.13 New Region Filter
								WHEN 'Region' THEN @MarketRegion ELSE MR.Region END
                        LEFT JOIN [$(SampleDB)].Vehicle.Vehicles V ON V.VehicleID = SQ.MatchedODSVehicleID
                        LEFT JOIN [$(SampleDB)].Meta.VehicleEvents MVE ON MVE.VehicleID = SQ.MatchedODSVehicleID
                                                              AND MVE.EventID = SQ.MatchedODSEventID
                        LEFT JOIN [$(SampleDB)].Vehicle.Models M ON M.ModelID = MVE.ModelID
                        LEFT JOIN [$(SampleDB)].Event.Events E ON E.EventID = SQ.MatchedODSEventID
						LEFT JOIN (														--V1.16
							SELECT DISTINCT BMQ.ContactMethodologyTypeID, B.Brand, M.Market, Q.Questionnaire
							FROM [$(SampleDB)].[dbo].BrandMarketQuestionnaireMetadata BMQ
							INNER JOIN [$(SampleDB)].[dbo].Brands B ON B.BrandID= BMQ.BrandID
							INNER JOIN [$(SampleDB)].[dbo].Markets M ON M.MarketID = BMQ.MarketID
							INNER JOIN [$(SampleDB)].[dbo].Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
							WHERE BMQ.SampleLoadActive = 1	
							) CMT ON CMT.Brand = @Brand
									AND CMT.Questionnaire = @Questionnaire
									AND CMT.Market = SQ.Market							--V1.16
									LEFT JOIN   [$(ETLDB)].[CRC].[CRCEvents] crc ON sq.AuditItemID = crc.AuditItemID --V1.19
									LEFT JOIN	[$(ETLDB)].[GeneralEnquiry].[GeneralEnquiryEvents] GEE ON sq.AuditItemID = GEE.AuditItemID--V1.86
									LEFT JOIN   [$(ETLDB)].[Roadside].[RoadsideEventsProcessed] RE on sq.AuditItemID = RE.AuditItemID --V1.21
									LEFT JOIN	[$(ETLDB)].[CRM].[DMS_Repair_Service] DRS ON DRS.AuditItemID = SQ.AuditItemID -- V1.30
									LEFT JOIN	[$(ETLDB)].[CRM].[Vista_Contract_Sales] VCS ON VCS.AuditItemID = SQ.AuditItemID -- V1.30
									LEFT JOIN	[$(AuditDB)].Audit.AdditionalInfoSales AIF ON AIF.AuditItemID = SQ.AuditItemID -- V1.30
									LEFT JOIN	[$(ETLDB)].[Canada].[Sales] CSA ON CSA.AuditID = SQ.AuditID	-- V1.35
																			  AND CSA.PhysicalRowID = SQ.PhysicalFileRow
							        LEFT JOIN	[$(ETLDB)].[Canada].[Service] CSE ON CSE.AuditID = SQ.AuditID	-- V1.35
																			  AND CSE.PhysicalRowID = SQ.PhysicalFileRow
																	  					
              WHERE   F.ActionDate >= @StartYearDate
                        AND F.ActionDate < @EndDate
						AND MK.FranchiseCountryType = 'Core' --V1.80; 
    
	--V1.79 -------------------------------------------------------------------------------------------------------------    
	  --SUPERCEDED BY V1.81

	  ----UPDATE B
	  ----SET CRC_Owner = CASE
			----				WHEN LK.CODE IS NOT NULL THEN LK.FirstName
			----				WHEN LK.CODE IS NULL AND LEN(ISNULL(B.ClosedBy,'')) > 0 THEN B.ClosedBY
			----		  ELSE B.[Owner]
			----		  END
	  ----FROM SampleReport.Base B
	  ----LEFT JOIN	[$(ETLDB)].Lookup.CRCAgentLookup LK ON CASE 
			----												WHEN LEN(ISNULL(B.ClosedBy,'')) > 0 THEN B.ClosedBy
			----												ELSE B.[Owner] 
			----											 END  = lk.Code 
			----										  AND B.Brand = lk.Brand
			----										  AND B.CRCMarketCode = lk.MarketCode
													  
	 UPDATE B
	 SET CountryIsoAlpha2 = ISOAlpha2
	 FROM SampleReport.Base B
	 INNER JOIN [$(SampleDB)].ContactMechanism.Countries C ON B.CountryID = C.CountryID 


	 --V1.89 -------------------------------------------------------------------------------------------------------------

	 UPDATE B
	 SET EventDateTooYoung = 0
	 FROM SampleReport.Base B
	 WHERE FileActionDate >= @EventDateTooYoung
	 AND ReportDate > = EventDate
	 AND CaseID IS NULL


	 -- V1.90 -------------------------------------------------------------------------------------------------------------

	 UPDATE B
	 SET B.EventDate = B.RegistrationDate, B.SuppliedEventDate = 1
	 FROM SampleReport.Base B
	 WHERE B.EventDate IS NULL
	 AND B.RegistrationDate IS NOT NULL
	 AND B.Questionnaire = 'Sales'
	 AND B.FileActionDate >= @SuppliedEventDate


	 --V1.87 ------------------------------------------------------------------------------------------------------------- 
	 
	 UPDATE B
		SET B.ServiceTechnicianID	= '',															
		    B.ServiceTechnicianName	= '',                                                  		
		    B.ServiceAdvisorName  = '',                                                     
	        B.ServiceAdvisorID	= '',	                                                   	 
	        B.CRMSalesmanName	= '',	                                                   
	        B.CRMSalesmanCode   = '', 
		    B.ServiceEmployeeCode = '', 														
		    B.ServiceEmployeeName = ''
		FROM SampleReport.Base B
		INNER JOIN [$(SampleDB)].dbo.Markets M ON B.CountryID = M.CountryID			-- V1.88
		WHERE M.ExcludeEmployeeData = 1

	 --V1.81 -------------------------------------------------------------------------------------------------------------  

	UPDATE B
	SET CRC_Owner = 
		CASE
			WHEN LKO.CDSID IS NOT NULL THEN LKO.CDSID
			WHEN LKF.CDSID IS NOT NULL THEN LKF.CDSID
			ELSE ''                                                                                                                                                                                                                 
		END 
	FROM SampleReport.Base B
	INNER JOIN  [$(SampleDB)].ContactMechanism.Countries C ON B.CountryID = C.CountryID 
	LEFT JOIN	[$(ETLDB)].[Lookup].[CRCAgents_GlobalList] LKO ON LTRIM(RTRIM(B.[Owner])) = LKO.CDSID 
																 AND C.ISOAlpha3 = LKO.MarketCode	
	LEFT JOIN	[$(ETLDB)].[Lookup].[CRCAgents_GlobalList] LKF ON LTRIM(RTRIM(B.[Owner])) = LKF.FullName 
																 AND C.ISOAlpha3 =  LKF.MarketCode 
	WHERE B.Questionnaire IN ('CRC', 'CRC General Enquiry') --V1.86


	UPDATE B
	SET AgentCodeFlag = 1
	FROM SampleReport.Base B
	WHERE LEN(ISNULL(CRC_Owner,'')) = 0
	AND Questionnaire IN ('CRC', 'CRC General Enquiry') --V1.86

	 ---------------------------------------------------------------------------------------------------------------------
	 --V1.84
	 UPDATE B
	 SET B.SVCRMInvalidSalesType = 1
	 FROM SampleReport.Base B 
	 INNER JOIN [$(WebsiteReporting)].[dbo].[SampleQualityAndSelectionLogging] SQ ON B.AuditItemID = SQ.AuditItemID
	 WHERE B.Questionnaire = 'SALES'
	 AND B.Market IN ('Canada','United States of America')
	 AND SQ.InvalidCRMSaleType = 1


    --V1.71 -------------------------------------------------------------------------------------------------------------    
    
		UPDATE B
		SET SalesEmployeeCode = AIF.SalesmanCode, SalesEmployeeName = Salesman 
		FROM SampleReport.Base B  
		INNER JOIN	[$(AuditDB)].Audit.AdditionalInfoSales AIF ON AIF.AuditItemID = B.AuditItemID         
        WHERE B.Questionnaire = 'Preowned'
        AND LoadedDate >= @PreownedEmployeeData
    
    --V1.54 -------------------------------------------------------------------------------------------------------------
    
		UPDATE	SampleReport.Base
		SET		SVCRMInvalidSalesType = 0
		WHERE	LoadedDate >= @CRMSaleTypeCheckSwitchDate
		AND     Market = 'UNITED KINGDOM' --V1.84
                          
    ---------------------------------------------------------------------------------------------------------------------
	-- V1.50 		UPDATE CUSTOMER PREFERENCE FIELDS AT SELECTION PINT  V1.50 
	--			    (NB: ONLY APPLICABLE FROM DATE OF SampleQualityAndSelectionLogging AUDITTING. BUG 14435)
	---------------------------------------------------------------------------------------------------------------------                     
    
				UPDATE	B
				SET		B.ContactPreferencesPartySuppress = SQA.ContactPreferencesPartySuppress,
						B.ContactPreferencesEmailSuppress =	SQA.ContactPreferencesEmailSuppress,
						B.ContactPreferencesPhoneSuppress =	SQA.ContactPreferencesPhoneSuppress,
						B.ContactPreferencesPostalSuppress = SQA.ContactPreferencesPostalSuppress
				FROM	SampleReport.Base B
					INNER JOIN [$(WebsiteReporting)].dbo.SampleProcessedLoggingAudit SPL ON SPL.AuditItemID = B.AuditItemID
					INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLoggingAudit SQA ON SQA.AuditItemID = SPL.AuditItemID
																						 AND SQA.AuditTimestamp = SPL.AuditTimestamp
					LEFT JOIN [$(SampleDB)].[Event].[CasesRollBack] CRB ON CRB.CaseID = B.CaseID -- V1.53
				WHERE	SPL.SelectionPoint = 1
				AND		CRB.CaseID IS NULL -- V1.53

	---------------------------------------------------------------------------------------------------------------------
	--				BLANK EXCLUSION FLAGS NOT APPLICABLE TO PartyMatchingMethodology  V1.20 
	--------------------------------------------------------------------------------------------------------------------- 
	 
				Update   B
				SET      B.SuppliedPhoneNumber = 1, B.SuppliedAddress = 1, B.PostalSuppression = 0
				
				FROM     SampleReport.Base B
					     LEFT JOIN [$(SampleDB)].[dbo].Markets SB ON B.Market = SB.Market
					     INNER JOIN [$(SampleDB)].[dbo].PartyMatchingMethodologies PM ON SB.PartyMatchingMethodologyID = PM.ID
				WHERE    PM.PartyMatchingMethodology = 'Name and Email Address'
				
				Update  B
				SET		B.SuppliedAddress = 1, B.PostalSuppression = 0
				
				FROM   SampleReport.Base B
					   LEFT JOIN [$(SampleDB)].[dbo].Markets SB ON B.Market = SB.Market
					   INNER JOIN [$(SampleDB)].[dbo].PartyMatchingMethodologies PM ON SB.PartyMatchingMethodologyID = PM.ID
				WHERE  PM.PartyMatchingMethodology = 'Name and Telephone Number' 
	 
	 ---------------------------------------------------------------------------------------------------------------------
	 --				SEPERATE 'Customer Unsubscription'  PARTY-NONSOLICITATIONS V1.26
	 --------------------------------------------------------------------------------------------------------------------- 


				UPDATE B													-- v1.34 - New update to use ContactOutcome table NOT YET LIVE - BUG 13364
				SET Unsubscribes = 1
				FROM SampleReport.Base B
				INNER JOIN [$(AuditDB)].Audit.CaseContactMechanismOutcomes acco ON acco.PartyID = COALESCE(NULLIF(B.MatchedODSPersonID,0), NULLIF(B.MatchedODSOrganisationID,0), B.MatchedODSPartyID)
				INNER JOIN [$(SampleDB)].[ContactMechanism].[OutcomeCodes] oc ON oc.[OutcomeCode] = acco.OutcomeCode 
																	  AND oc.Unsubscribe = 1
			    WHERE B.LoadedDate >= acco.ActionDate
			    AND B.LoadedDate < @NewUnsubscribeLoggingFlag	-- v1.51 -- Only process records loaded during period when ContactPreferencesUnsubscribed flag was not being set
				AND Unsubscribes <> 1							-- v1.51 -- Only process if not already set TRUE
			    AND ACCO.CasePartyCombinationValid = 1		
																	  
				UPDATE B
				SET Unsubscribes = 1
				FROM SampleReport.Base B
						INNER JOIN [$(SampleDB)].dbo.NonSolicitations NS ON NS.PartyID = COALESCE(NULLIF(B.MatchedODSPersonID,0), NULLIF(B.MatchedODSOrganisationID,0), B.MatchedODSPartyID)
						INNER JOIN [$(SampleDB)].Party.NonSolicitations PNS ON PNS.NonSolicitationID = NS.NonSolicitationID
						INNER JOIN [$(SampleDB)].dbo.NonSolicitationTexts NT on NT.NonSolicitationTextID = NS.NonSolicitationTextID
				WHERE B.LoadedDate <= ISNULL(NS.ThroughDate, B.LoadedDate)
				AND B.LoadedDate >= NS.FromDate
				AND B.LoadedDate < @NewUnsubscribeLoggingFlag	-- v1.51 -- Only process records loaded during period when ContactPreferencesUnsubscribed flag was not being set
				AND Unsubscribes <> 1							-- v1.51 -- Only process if not already set TRUE
				AND NT.NonSolicitationText = 'Customer Unsubscription'													  
																	  
				
				UPDATE SampleReport.Base
					SET Unsubscribes = 0
				WHERE Unsubscribes IS NULL	
	
				
				UPDATE B
				SET PartyNonSolicitation = 1
				FROM SampleReport.Base B
						INNER JOIN [$(SampleDB)].dbo.NonSolicitations NS ON NS.PartyID = COALESCE(NULLIF(B.MatchedODSPersonID,0), NULLIF(B.MatchedODSOrganisationID,0), B.MatchedODSPartyID)
						INNER JOIN [$(SampleDB)].Party.NonSolicitations PNS ON PNS.NonSolicitationID = NS.NonSolicitationID
						INNER JOIN [$(SampleDB)].dbo.NonSolicitationTexts NT on NT.NonSolicitationTextID = NS.NonSolicitationTextID
				WHERE B.LoadedDate <= ISNULL(NS.ThroughDate, B.LoadedDate)
				AND B.LoadedDate >= NS.FromDate								
				AND NT.NonSolicitationText <> 'Customer Unsubscription'
				AND B.LoadedDate <= @PartyNonSolicitationFlag --V1.59 - RETAIN OLD FLAG
	
				--V1.59
				UPDATE B
				SET PartyNonSolicitation = 1
				FROM SampleReport.Base B
						INNER JOIN [$(SampleDB)].dbo.NonSolicitations NS ON NS.PartyID = COALESCE(NULLIF(B.MatchedODSPersonID,0), NULLIF(B.MatchedODSOrganisationID,0), B.MatchedODSPartyID)
						INNER JOIN [$(SampleDB)].Party.NonSolicitations PNS ON PNS.NonSolicitationID = NS.NonSolicitationID
						INNER JOIN [$(SampleDB)].dbo.NonSolicitationTexts NT on NT.NonSolicitationTextID = NS.NonSolicitationTextID
						LEFT JOIN  [$(SampleDB)].Party.Organisations O ON O.PartyID = NS.PartyID
				WHERE B.LoadedDate <= ISNULL(NS.ThroughDate, B.LoadedDate)
				AND B.LoadedDate >= NS.FromDate								
				AND NT.NonSolicitationText <> 'Customer Unsubscription'
				AND O.PartyID IS NULL -- V1.59 Ignore Company Name blackisted Non-Solicitaions (these are added upon load - [Load].[vwPartyNonSolicitations]) 
				AND B.LoadedDate > @PartyNonSolicitationFlag -- CHANGE FOR DATA MOVING FORWARD FROM ROLL OUT
				
				--V1.59 - add Black listed company names to this flag instead of PartyNonSolicitation
				UPDATE B
				SET ExclusionListMatch = 1
				FROM SampleReport.Base B
						INNER JOIN [$(SampleDB)].dbo.NonSolicitations NS ON NS.PartyID = B.MatchedODSOrganisationID
						INNER JOIN [$(SampleDB)].Party.Organisations O ON O.PartyID = NS.PartyID
						INNER JOIN [$(SampleDB)].Party.BlacklistStrings BS ON O.OrganisationName = BS.BlacklistString
				WHERE B.LoadedDate <= ISNULL(NS.ThroughDate, B.LoadedDate)
				AND B.LoadedDate >= NS.FromDate	
				AND B.LoadedDate > @PartyNonSolicitationFlag							

				
	---------------------------------------------------------------------------------------------------------------------
	--				SET GDPRflag V1.56
	--------------------------------------------------------------------------------------------------------------------- 

				UPDATE B
				SET GDPRflag = 1
				FROM SampleReport.Base B
						INNER JOIN [$(SampleDB)].dbo.NonSolicitations NS ON NS.PartyID = COALESCE(NULLIF(B.MatchedODSPersonID,0), NULLIF(B.MatchedODSOrganisationID,0), B.MatchedODSPartyID)
						INNER JOIN [$(SampleDB)].Party.NonSolicitations PNS ON PNS.NonSolicitationID = NS.NonSolicitationID
						INNER JOIN [$(SampleDB)].dbo.NonSolicitationTexts NT on NT.NonSolicitationTextID = NS.NonSolicitationTextID
				WHERE	NS.ThroughDate IS NULL
				AND		NS.NonSolicitationTextID IN (22,23) --UAT CODES
				
	---------------------------------------------------------------------------------------------------------------------- 

	---  POPULATE THE Dealer info (Regions and Groups, etc) in SampleReport.Base ------------------------------------------


        UPDATE  b
        SET     SuperNationalRegion = d.SuperNationalRegion ,
                BusinessRegion = d.BusinessRegion ,					-- V1.11
                DealerMarket = d.Market ,
                SubNationalTerritory = d.SubNationalTerritory ,		-- v1.23
                SubNationalRegion = d.SubNationalRegion ,
                CombinedDealer = d.CombinedDealer ,
                DealerName = d.TransferDealer ,
                DealerCode = d.TransferDealerCode ,
                DealerCodeGDD = d.TransferDealerCode_GDD,
				OutletPartyID = d.OutletPartyID,                     -- V1.79 
				Dealer10DigitCode = d.Dealer10DigitCode,			 -- V1.79 
				OutletFunction = d.OutletFunction					 -- V1.79 
	-- select * LostLeads
        FROM    SampleReport.Base b
                JOIN [$(SampleDB)].Event.EventPartyRoles epr ON epr.EventID = b.MatchedODSEventID
                JOIN [$(SampleDB)].[dbo].DW_JLRCSPDealers d ON d.OutletPartyID = epr.PartyID
                                                        AND d.OutletFunction = CASE @Questionnaire
                                                              WHEN 'Service'
                                                              THEN 'AfterSales'
                                                              WHEN 'Sales'
                                                              THEN 'Sales'
                                                              WHEN 'LostLeads'
                                                              THEN 'Sales'			--V1.29
                                                              WHEN 'PreOwned'		--V1.15
                                                              THEN 'PreOwned'
                                                              WHEN 'Bodyshop'		--V1.42
                                                              THEN 'Bodyshop'		--V1.42
															  WHEN 'PreOwned LostLeads'		-- V1.72
															  THEN 'PreOwned'				-- V1.72
															  ELSE ''
                                                              END;

	---  V1.29 Adding Dealer info to sampleReports: CRC,Roadside & Lost Leads ------------------------------------------
	
	--patch 09112018 - GDPR RESTRICTION sets countrydID to 236 - this created Key Violation below as field values set to NULL
	UPDATE B
	SET B.CountryID = M.CountryID
	FROM SampleReport.Base B
	INNER JOIN [$(SampleDB)].dbo.Markets M ON B.Market = M.Market
	WHERE B.CountryID = 236
	
	--Update CRC & Roadside Dealer info. (NB: SuperNationalRegion on Market level, do no need to join on Dealer level)
	UPDATE  b
        SET     SuperNationalRegion = snr.SuperNationalRegion ,
                BusinessRegion = br.Region ,                               -- V1.11
                DealerMarket = COALESCE(m.DealerTableEquivMarket, m.Market) ,
                SubNationalTerritory = '' ,            -- v1.23
                SubNationalRegion = '' ,
                CombinedDealer = '' ,
                DealerName = '' ,
                DealerCode = '' ,
                DealerCodeGDD = '',
				OutletPartyID = '',									-- V1.79 
				Dealer10DigitCode = '',				     			 -- V1.79 
				OutletFunction = ''									-- V1.79 
       
        FROM    SampleReport.Base b
                INNER JOIN [$(SampleDB)].dbo.Markets m ON m.CountryID = b.CountryID
                           INNER JOIN [$(SampleDB)].dbo.Regions br ON br.RegionID = m.RegionID
                           INNER JOIN [$(SampleDB)].[dbo].[SuperNationalRegions] snr ON snr.SuperNationalRegionID = br.SuperNationalRegionID   
        WHERE	B.Questionnaire IN ('CRC', 'Roadside', 'CRC General Enquiry')  --V1.86                
		
	
	--Update Roadside info. (NB: SuperNationalRegion on Market level, do no need to join on Dealer level)
	--UPDATE  b
        --SET     SuperNationalRegion = snr.SuperNationalRegion ,
                --BusinessRegion = br.Region ,                               -- V1.11
                --DealerMarket = COALESCE(m.DealerTableEquivMarket, m.Market) ,
                --SubNationalTerritory = '' ,            -- v1.23
                --SubNationalRegion = '' ,
                --CombinedDealer = '' ,
                --DealerName = '' ,
                --DealerCode = '' ,
                --DealerCodeGDD = ''
       
        --FROM    SampleReport.Base b
                --INNER JOIN [$(SampleDB)].dbo.Markets m ON m.CountryID = b.CountryID																-- 1.62
                           --INNER JOIN [$(SampleDB)].dbo.Regions br ON br.RegionID = m.RegionID														-- 1.62
                           --INNER JOIN [$(SampleDB)].[dbo].[SuperNationalRegions] snr ON snr.SuperNationalRegionID = br.SuperNationalRegionID		-- 1.62

	--  POPULATE records with an uncoded dealer code with the Dealer code supplied in the sample (Bug #9633)
	
	
        UPDATE  SampleReport.Base
        SET     DealerCode = COALESCE(NULLIF(SalesDealerCode, ''),
                                      NULLIF(ServiceDealerCode, ''))
        FROM    SampleReport.Base b
                JOIN [$(WebsiteReporting)].[dbo].[SampleQualityAndSelectionLogging] sq ON b.AuditItemID = sq.AuditItemID
        WHERE   b.DealerCode IS NULL;
	 
	
	--- POPULATE with Customer Name and Organisations Name ------------------------------------------
	
        IF @MarketRegion = 'Romania'
            BEGIN 
                UPDATE  SampleReport.Base
                SET     FullName = CASE WHEN FirstName <> LastName AND CHARINDEX(FirstName, LastName) = 0 AND CHARINDEX(LastName, FirstName) = 0
                                             
                                             
                                        THEN LTRIM(ISNULL(LTRIM(RTRIM(Title)) + ' ', ''))
                                                          
                                             + LTRIM(ISNULL(COALESCE(LTRIM(RTRIM(FirstName)),LTRIM(RTRIM(Initials))) + ' ', ''))
                                                            
                                             + ISNULL(LTRIM(RTRIM(LastName)),'')
                                                      
                                        ELSE LTRIM(ISNULL(LTRIM(RTRIM(Title))+ ' ', ''))
                                                          
                                             + LTRIM(ISNULL(LTRIM(RTRIM(Initials))+ ' ', ''))
                                                            
                                             + ISNULL(LTRIM(RTRIM(LastName)),'')
                                                      
                                   END ,
						--+ ISNULL(LTRIM(RTRIM(SecondLastName)) + ' ', '') ,
                        OrganisationName = ISNULL(o.OrganisationName, '')
                FROM    SampleReport.Base b
                        INNER JOIN [$(SampleDB)].Meta.VehiclePartyRoleEvents VPRE ON VPRE.EventID = b.MatchedODSEventID
                        LEFT JOIN [$(SampleDB)].Party.Organisations o ON o.PartyID = b.MatchedODSOrganisationID
                        LEFT JOIN [$(SampleDB)].Party.People P ON P.PartyID = COALESCE(VPRE.PrincipleDriver,
                                                              VPRE.RegisteredOwner,
                                                              VPRE.Purchaser,
                                                              VPRE.OtherDriver)
                        LEFT JOIN [$(SampleDB)].Party.Titles T ON T.TitleID = P.TitleID;

            END; 
        ELSE
            BEGIN
                UPDATE  SampleReport.Base
                SET     FullName = [$(SampleDB)].Party.udfGetAddressingText(COALESCE(VPRE.PrincipleDriver,
                                                              VPRE.RegisteredOwner,
                                                              VPRE.Purchaser,
                                                              VPRE.OtherDriver),
                                                              0, 219, 19,
                                                              ( SELECT
                                                              AddressingTypeID
                                                              FROM
                                                              [$(SampleDB)].Party.AddressingTypes
                                                              WHERE
                                                              AddressingType = 'Addressing'
                                                              )) ,
                        OrganisationName = ISNULL(o.OrganisationName, '')
                FROM    SampleReport.Base b
                        INNER JOIN [$(SampleDB)].Meta.VehiclePartyRoleEvents VPRE ON VPRE.EventID = b.MatchedODSEventID
                        LEFT JOIN [$(SampleDB)].Party.Organisations o ON o.PartyID = b.MatchedODSOrganisationID;

            END;





	--- POPULATE with Email Addresses as supplied in Sample file -- v1.4 ------------------------------------
        UPDATE  SampleReport.Base
        SET     SampleEmailAddress = ea.EmailAddress
        FROM    SampleReport.Base b
                INNER JOIN [$(SampleDB)].ContactMechanism.EmailAddresses ea ON ea.ContactMechanismID = b.MatchedODSEmailAddressID;
                
                
    --- POPULATE with Email Addresses as supplied in Sample file -- V1.69 ------------------------------------
        UPDATE  SampleReport.Base
        SET     SamplePrivEmailAddress = ea.EmailAddress
        FROM    SampleReport.Base b
                INNER JOIN [$(SampleDB)].ContactMechanism.EmailAddresses ea ON ea.ContactMechanismID = b.MatchedODSPrivEmailAddressID;            


	-- POPULATE ModelCode -- V1.93
	;WITH ModelCodes_CTE (QuestionnaireRequirementID, ModelID, ModelDescription, ModelCode)
	AS
	(
		SELECT DISTINCT SM.QuestionnaireRequirementID, M.ModelID, M.ModelDescription, MR.RequirementID AS ModelCode 
		FROM		[$(SampleDB)].dbo.vwBrandMarketQuestionnaireSampleMetadata	SM
		INNER JOIN	[$(SampleDB)].Requirement.QuestionnaireRequirements			QR	ON SM.QuestionnaireRequirementID	= QR.RequirementID
		INNER JOIN	[$(SampleDB)].Requirement.Requirements						R	ON QR.RequirementID					= R.RequirementID
		INNER JOIN	[$(SampleDB)].Requirement.QuestionnaireModelRequirements	QMR ON QMR.RequirementIDPartOf			= R.RequirementID
		INNER JOIN	[$(SampleDB)].Requirement.ModelRequirements					MR	ON QMR.RequirementIDMadeUpOf		= MR.RequirementID
		INNER JOIN	[$(SampleDB)].Vehicle.Models								M	ON MR.ModelID						= M.ModelID
	)
	UPDATE		SB
	SET			ModelCode = CTE.ModelCode
	FROM		SampleReport.Base				SB
	INNER JOIN  [$(SampleDB)].Vehicle.Vehicles	VEH ON SB.MatchedODSVehicleID			= VEH.VehicleID		-- EXTRA STEP BECAUSE ORIGINAL INSERT INTO SampleReport.Base sometimes has OldModelID 
	INNER JOIN	ModelCodes_CTE					CTE ON	SB.QuestionnaireRequirementID	= CTE.QuestionnaireRequirementID
	WHERE		VEH.ModelID	= CTE.ModelID		-- EXTRA STEP BECAUSE ORIGINAL INSERT INTO SampleReport.Base sometimes has OldModelID 

	--UNKNOWN MODELS NOT LIKELY TO BE ASSOCIATED TO A QUESTIONNAIRE, THIS IS A MOP UP TO POPULATE RECORDS THAT PREVIOUS STEP COULDN'T
	;WITH UnknownModels_CTE (ModelID, ModelCode)
	AS
	(
		SELECT		MD.ModelID, RequirementID
		FROM		[$(SampleDB)].Requirement.ModelRequirements	RQ
		INNER JOIN	[$(SampleDB)].Vehicle.Models					MD ON RQ.ModelID = MD.ModelID
		WHERE		ModelDescription LIKE '%unknown%'
	)
	UPDATE		SB
	SET			ModelCode = CTE.ModelCode
	FROM		SampleReport.Base				SB
	INNER JOIN  [$(SampleDB)].Vehicle.Vehicles	VEH ON SB.MatchedODSVehicleID			= VEH.VehicleID		-- EXTRA STEP BECAUSE ORIGINAL INSERT INTO SampleReport.Base sometimes has OldModelID 
	INNER JOIN	UnknownModels_CTE				CTE ON VEH.ModelID	= CTE.ModelID
	WHERE		SB.ModelCode IS NULL	

	--V1.94
	UPDATE		SB
	SET			LeadVehSaleType					=	CASE
															WHEN ISNULL(AIS.JLRSuppliedEventType,'') <> '' THEN AIS.JLRSuppliedEventType
															ELSE 
																CASE LTRIM(RTRIM(L.LEAD_VEH_SALE_TYPE))
																	WHEN 'NEW VEHICLE SALE' THEN '1'
																	WHEN 'USED VEHICLE SALE' THEN '2'	
																END
													END
	FROM		SampleReport.Base				SB
	LEFT JOIN	[$(SampleDB)].Event.AdditionalInfoSales	AIS ON SB.MatchedODSEventID = AIS.EventID
	LEFT JOIN	[$(ETLDB)].CRM.Lost_Leads		L ON SB.AuditItemID = L.AuditItemID	
	WHERE		SB.Questionnaire = 'LostLeads' -- V1.95

	--V1.94
	UPDATE		SB
	SET			ModelVariant						= mv.Variant
	FROM		SampleReport.Base					SB
	INNER JOIN	[$(SampleDB)].Vehicle.Vehicles		VEH ON SB.MatchedODSVehicleID	= VEH.VehicleID
	INNER JOIN  [$(SampleDB)].Vehicle.ModelVariants	MV	ON VEH.ModelVariantID		= MV.VariantID
	

	--ATTEMPTED BUG FIX : OutputFileModelDescription NOT ALWAYS POPULATING
	UPDATE		SB
	SET			OutputFileModelDescription =	CASE 
													WHEN SB.[CountryID] IN (	SELECT mkt.CountryID 
																				FROM [$(SampleDB)].dbo.Regions r
																				INNER JOIN [$(SampleDB)].dbo.Markets mkt ON mkt.RegionID = r.RegionID
																				WHERE r.Region = 'North America NSC'
																			) THEN MD.NorthAmericaModelDescription 
													ELSE MD.OutputFileModelDescription
												END
	FROM		SampleReport.Base					SB
	INNER JOIN	[$(SampleDB)].Vehicle.Vehicles		VEH ON SB.MatchedODSVehicleID	= VEH.VehicleID
	INNER JOIN	[$(SampleDB)].Vehicle.Models		MD	ON VEH.ModelID				= MD.ModelID					
	WHERE		ISNULL(SB.OutputFileModelDescription,'') =''

	-- POPULATE ModelCode -- V1.93 2ND MOP UP, USING RECENTLY POPULATED MODEL DESCRIPTION
	;WITH ModelCodes_CTE ( ModelCode, ModelDescription)
	AS
	(
		SELECT  RQ.RequirementID, RQ.Requirement
		FROM	[$(SampleDB)].Requirement.Requirements RQ
		INNER JOIN 
		(
			--ELIMINATE MODELS WITH DUPLICATE MODEL CODES. NOT IDEAL BUT MEANS WE CAN POPULATE THE MAJORITY OF RECORDS)
			SELECT		COUNT(*) CNT, MD.ModelDescription
			FROM		[$(SampleDB)].Vehicle.Models MD
			INNER JOIN	[$(SampleDB)].Requirement.Requirements RQ ON MD.ModelDescription = RQ.Requirement AND RequirementTypeID = 4
			GROUP BY	MD.ModelDescription
			HAVING		COUNT(*) = 1
			UNION 
			SELECT 1 , 'Unknown Vehicle'
		)	MD ON RQ.Requirement = MD.ModelDescription		
	)
	UPDATE		SB
	SET			ModelCode			= CTE.ModelCode
	FROM		SampleReport.Base	SB 
	INNER JOIN	ModelCodes_CTE		CTE ON SB.OutputFileModelDescription = CTE.ModelDescription
	WHERE		ISNULL(SB.ModelCode,0)	=0 

	--V1.92	
	UPDATE		BS
	SET			SubBrand						= SB.SubBrand	
	FROM		SampleReport.Base				BS
	INNER JOIN  [$(SampleDB)].Vehicle.Vehicles	VEH ON BS.MatchedODSVehicleID = VEH.VehicleID
	INNER JOIN  [$(SampleDB)].Vehicle.Models	MD ON VEH.ModelID	= MD.ModelID
	INNER JOIN  [$(SampleDB)].Vehicle.SubBrands	SB	ON MD.SubBrandID = SB.SubBrandID	

	------------------------------------------------------------------------------------------------
	-- Duplicate event processing  (set flags etc)
	------------------------------------------------------------------------------------------------


	-- Get all the dupes --------------

        IF ( OBJECT_ID('tempdb..#Dupes') IS NOT NULL )
            BEGIN
                DROP TABLE #Dupes;
            END;

        SELECT  MatchedODSEventID AS EventID
        INTO    #Dupes
        FROM    SampleReport.Base
        GROUP BY MatchedODSEventID
        HAVING  COUNT(*) > 1;


	-- Pick the latest loaded row prior to the case creation date and flag it as the "non-dupe"
	--------------------------------------------------------------------------------------------

        IF ( OBJECT_ID('tempdb..#NonDupe') IS NOT NULL )
            BEGIN
                DROP TABLE #NonDupe;
            END;

        SELECT  b.MatchedODSEventID AS EventID ,
                b.CaseID ,
                MAX(b.AuditItemID) AS AuditItemID
        INTO    #NonDupe
        FROM    #Dupes de
                INNER JOIN SampleReport.Base b ON b.MatchedODSEventID = de.EventID
                INNER JOIN [$(SampleDB)].Event.Cases c ON c.CaseID = b.CaseID
        WHERE   b.LoadedDate < c.CreationDate
        GROUP BY b.MatchedODSEventID ,
                b.CaseID;


	-- For the remainder of those that have a caseID, then just set the latest record as the non-dupe
	-- as this is the one that would be the one we would mark as non-dupe were a case created tomorrow.
	-- Note: This is unlikely ever to happen as there shouldn't be records loaded afterward that are flagged with the 
	--       caseID but just in case there is an anomaly in the data we'll catch it here.
	--------------------------------------------------------------------------------------------

        IF ( OBJECT_ID('tempdb..#NonDupe2') IS NOT NULL )
            BEGIN
                DROP TABLE #NonDupe2;
            END;

        SELECT  b.MatchedODSEventID AS EventID ,
                b.CaseID ,
                MAX(b.AuditItemID) AS AuditItemID
        INTO    #NonDupe2
        FROM    #Dupes de
                INNER JOIN SampleReport.Base b ON b.MatchedODSEventID = de.EventID
        WHERE   de.EventID NOT IN ( SELECT  EventID
                                    FROM    #NonDupe )
                AND b.CaseID IS NOT NULL
        GROUP BY b.MatchedODSEventID ,
                b.CaseID;


	-- Those remaining have no CaseID, flag the latest one as the "non-dupe"
	--------------------------------------------------------------------------------------------

        IF ( OBJECT_ID('tempdb..#NonDupe3') IS NOT NULL )
            BEGIN
                DROP TABLE #NonDupe3;
            END;

        SELECT  b.MatchedODSEventID AS EventID ,
                b.CaseID ,
                MAX(b.AuditItemID) AS AuditItemID
        INTO    #NonDupe3
        FROM    #Dupes de
                INNER JOIN SampleReport.Base b ON b.MatchedODSEventID = de.EventID
        WHERE   de.EventID NOT IN ( SELECT  EventID
                                    FROM    #NonDupe )
                AND de.EventID NOT IN ( SELECT  EventID
                                        FROM    #NonDupe2 )
        GROUP BY b.MatchedODSEventID ,
                b.CaseID;



	-- Set dupe flag on rows where event AlreadySelected = TRUE  and no Case details
	-- This captures those records which are (previous selected) dupes from a previous year that have 
	-- records in this year.
        UPDATE  b
        SET     DuplicateRowFlag = 1
        FROM    SampleReport.Base b
        WHERE   ISNULL(DuplicateRowFlag, 0) <> 1
                AND EventAlreadySelected = 1
                AND CaseID IS NULL
                AND MatchedODSEventID NOT IN ( SELECT   EventID
                                               FROM     #NonDupe )
                AND MatchedODSEventID NOT IN ( SELECT   EventID
                                               FROM     #NonDupe2 )
                AND MatchedODSEventID NOT IN ( SELECT   EventID
                                               FROM     #NonDupe3 );

	-- Set flag on all dupe rows and clear CaseID------------------------------------------
        UPDATE  b
        SET     DuplicateRowFlag = 1 ,
                CaseID = NULL
        FROM    #Dupes d
                INNER JOIN SampleReport.Base b ON b.MatchedODSEventID = d.EventID 


	-- Now reset flags and add CaseID on all "non-dupe" rows -------------------------------
	;
        WITH    CTE_AllNonDupes ( AuditItemID, CaseID )
                  AS ( SELECT   AuditItemID ,
                                CaseID
                       FROM     #NonDupe
                       UNION
                       SELECT   AuditItemID ,
                                CaseID
                       FROM     #NonDupe2
                       UNION
                       SELECT   AuditItemID ,
                                CaseID
                       FROM     #NonDupe3
                     )
            UPDATE  b
            SET     DuplicateRowFlag = 0 ,
                    CaseID = nd.CaseID
            FROM    CTE_AllNonDupes nd
                    INNER JOIN SampleReport.Base b ON b.AuditItemID = nd.AuditItemID; 
    
                    	
	
	-- Set DuplicateRowFlag to 0 where NULL  1.13 -- 
	UPDATE b
	SET DuplicateRowFlag = 0
	FROM SampleReport.Base b
	WHERE DuplicateRowFlag IS NULL


	------------------------------------------------------------------------------------------------
	-- Add in closure dates for all CaseIDs and set all "Unusable" flags to 0, and update CaseEmailAddress
	------------------------------------------------------------------------------------------------

        IF ( OBJECT_ID('tempdb..#CasesOutput') IS NOT NULL )
            BEGIN
                DROP TABLE #CasesOutput;
            END;


        CREATE TABLE #CasesOutput
            (
              CaseID INT ,
              CaseOutputType VARCHAR(100)
            );
			

        INSERT  INTO #CasesOutput
                ( CaseID ,
                  CaseOutputType
                )
                SELECT  b.CaseID ,
                        CASE ct.CaseOutputType
							WHEN 'CATI' THEN 'PHONE'
							ELSE ct.CaseOutputType END AS CaseOutputType
                FROM    SampleReport.Base b
                        INNER JOIN [$(SampleDB)].Event.CaseOutput co ON co.CaseID = b.CaseID
                        INNER JOIN [$(SampleDB)].Event.CaseOutputTypes ct ON ct.CaseOutputTypeID = co.CaseOutputTypeID
                WHERE   ct.CaseOutputType <> 'Non Output'
                        AND co.AuditItemID = ( SELECT   MAX(AuditItemID) -- V1.32 (CHANGE FROM MIN TO MAX)
                                               FROM     [$(SampleDB)].Event.CaseOutput co2
                                               WHERE    co2.CaseID = b.CaseID
                                             );

        UPDATE  b
        SET     CaseCreationDate = c.CreationDate ,
                CaseStatusType = cst.CaseStatusType ,
                CaseOutputType = ISNULL(ct.CaseOutputType, '') ,				-- v1.4
                ClosureDate = c.ClosureDate ,
                RespondedFlag = CASE WHEN c.ClosureDate IS NOT NULL THEN 1
                                     ELSE NULL
                                END ,
                SentFlag = CASE WHEN ct.CaseID IS NOT NULL THEN 1
                                ELSE 0
                           END ,
                SentDate = CASE WHEN ct.CaseID IS NOT NULL AND b.FileActionDate < @CaseSentDateReCalc --V1.65
                                THEN DATEADD(DAY, 2, c.CreationDate)
								WHEN ct.CaseID IS NOT NULL AND b.FileActionDate >= @CaseSentDateReCalc
								THEN c.CreationDate
                           ELSE NULL
                           END,
                UsableFlag = 1 ,
                UnmatchedModel = 0 ,
                UncodedDealer = 0 ,
                EventAlreadySelected = 0 ,
                NonLatestEvent = 0 ,
                ExclusionListMatch = 0 ,
                BarredEmailAddress = 0 ,
                BarredDomain = 0 ,
                InvalidModel = 0 ,
                EventDateOutOfDate = 0 ,
                EventNonSolicitation = 0 ,
                RecontactPeriod = 0 ,
                RelativeRecontactPeriod = 0 ,
                MissingStreet = 0 ,
                MissingPostcode = 0 ,
                MissingEmail = 0 ,
                MissingTelephone = 0 ,
                MissingStreetAndEmail = 0 ,
                MissingTelephoneAndEmail = 0 ,
                MissingMobilePhone = 0 ,						-- v1.4
                MissingMobilePhoneAndEmail = 0 ,				-- v1.4
                MissingPartyName = 0 ,						-- v1.5		
                InvalidManufacturer = 0 ,
                InternalDealer = 0 ,
                InvalidOwnershipCycle = 0 ,
                PreviousEventBounceBack = 0 ,					-- v1.8
                EventDateTooYoung = 0,						-- v1.8
                DealerExclusionListMatch = 0,				-- V1.16
                InvalidAFRLCode = 0,						-- V1.16
                InvalidSalesType = 0,						-- V1.16
                PDIFlagSet = 0,								-- v1.41
                SVCRMInvalidSalesType = 0,					-- v1.43
                ContactPreferencesSuppression = 0			-- V1.34
        FROM    SampleReport.Base b
                INNER JOIN [$(SampleDB)].Event.Cases c ON c.CaseID = b.CaseID
                LEFT JOIN [$(SampleDB)].Event.CaseStatusTypes cst ON cst.CaseStatusTypeID = c.CaseStatusTypeID
                LEFT JOIN #CasesOutput ct ON ct.CaseID = b.CaseID; 


	--V1.70 Set record SentDate to date when selection output file was FIRST created
	;WITH CaseOutputDate (ActionDate, CaseID)
	AS
		(
			SELECT MIN(F.ActionDate), B.CaseID
			FROM SampleReport.Base B
			INNER JOIN [$(SampleDB)].Event.CaseOutput C ON B.CaseID = C.CaseID
			INNER JOIN [$(AuditDB)].dbo.Files F ON C.AuditID = F.AuditID
			WHERE B.FileActionDate >= @CaseSentDateReCalc_V2
			GROUP BY B.CaseID         
		)
	UPDATE B
	SET B.SentDate = C.ActionDate
	FROM SampleReport.Base B
	INNER JOIN CaseOutputDate C ON B.CaseID = C.CaseID
	WHERE B.FileActionDate >= @CaseSentDateReCalc_V2


	-- Update where a rejection has been applied.
        UPDATE  b
        SET     ManualRejectionFlag = 1
	-- select * 
        FROM    SampleReport.Base b
        WHERE   CaseStatusType = 'Refused by Exec'
                --AND b.SentFlag <> 1; --V1.82

	-- Update where the CaseStatus is incorrectly set
        UPDATE  b
        SET     CaseStatusType = '(Altered after sending)'
	-- select * 
        FROM    SampleReport.Base b
        WHERE   CaseStatusType = 'Refused by Exec'
                AND b.SentFlag = 1;


	-- Add in CaseEmailAddress values					-- 1.4
        UPDATE  SampleReport.Base
        SET     CaseEmailAddress = ea.EmailAddress
        FROM    SampleReport.Base b
                INNER JOIN [$(SampleDB)].Event.CaseContactMechanisms ccm ON ccm.CaseID = b.CaseID
                INNER JOIN [$(SampleDB)].ContactMechanism.EmailAddresses ea ON ea.ContactMechanismID = ccm.ContactMechanismID;


	------------------------------------------------------------------------------------------------
	-- Set flag for Duplicate Files
	------------------------------------------------------------------------------------------------
	IF (OBJECT_ID('tempdb..#DuplicateFileSampleRows') IS NOT NULL)
		BEGIN
			DROP TABLE #DuplicateFileSampleRows
		END

	CREATE TABLE #DuplicateFileSampleRows
			
		(
			FileName VARCHAR(100)
			, PhysicalFileRow BIGINT
			, CountDuplicateRows BIGINT
		);
		
	INSERT INTO #DuplicateFileSampleRows (FileName, PhysicalFileRow, CountDuplicateRows)
	SELECT
	F.FileName,
	b.PhysicalFileRow,
	COUNT(*)
	FROM SampleReport.Base b
	INNER JOIN [$(AuditDB)].[dbo].Files F ON b.AuditID = F.AuditID AND F.ActionDate > '2014-11-01'
	GROUP BY F.FileName,
	b.PhysicalFileRow
	HAVING COUNT(*) > 1
	AND F.FileName NOT LIKE '%China%'
	AND F.FileName NOT LIKE '%VINMaintenance%'
	--AND F.FileName NOT LIKE '%Combined_DDW%'
	--AND F.FileName LIKE '%Germany%'

	IF (OBJECT_ID('tempdb..#DuplicateFiles') IS NOT NULL)
		BEGIN
			DROP TABLE #DuplicateFiles
		END
			
	SELECT DISTINCT DUP.FileName, LEFT(DUP.FileName,CHARINDEX('.',DUP.FileName)-1) + '%' As FileNameShort
	INTO #DuplicateFiles
	FROM #DuplicateFileSampleRows DUP


	UPDATE b SET b.DuplicateFileFlag = 1
	--SELECT DF.FileNameShort, F.*, b.*
	FROM SampleReport.Base b
	INNER JOIN [$(AuditDB)].[dbo].Files F ON b.AuditID = F.AuditID AND F.ActionDate > '2014-11-01'
	INNER JOIN #DuplicateFiles DF ON F.FileName LIKE DF.FileNameShort
	
	DELETE FROM SampleReport.Base 
	WHERE DuplicateRowFlag = 1 AND DuplicateFileFlag = 1
	------------------------------------------------------------------------------------------------
	
    ------------------------------------------------------------------------------------------------
	-- FLAG DedupeEqualToEvents Flag - V1.24 
	------------------------------------------------------------------------------------------------
	
	UPDATE B
	SET DuplicateRowFlag = 0
	FROM SampleReport.Base B
	WHERE DuplicateRowFlag IS NULL
	
	
	IF (OBJECT_ID('tempdb..#SortDupesForRemovalV2') IS NOT NULL)
			BEGIN
				DROP TABLE #SortDupesForRemovalV2
			END
	
	CREATE TABLE #SortDupesForRemovalV2
			
		(
			AuditItemID BIGINT
			, VIN VARCHAR(50)
			, EventDate DATETIME2
			, CaseID INT
			, SentDate DATETIME2
			, FileName VARCHAR(100)
			, RemovalSort SMALLINT
		);
			
	WITH cteDupes
	AS
		(
			SELECT VIN, EventDate
			FROM SampleReport.Base B
			GROUP BY B.VIN, B.EventDate
			HAVING COUNT(*) > 1
		) 
		
			INSERT INTO #SortDupesForRemovalV2
				
				(
					AuditItemID
					, VIN
					, EventDate
					, CaseID
					, SentDate
					, FileName
					, RemovalSort
				)
					SELECT 
						B.AuditItemID
						, B.VIN
						, B.EventDate
						, B.CaseID
						, B.SentDate
						, FileName
						, ROW_NUMBER() OVER (PARTITION BY B.VIN, B.EventDate ORDER BY B.SentDate DESC, CASE WHEN B.FileName LIKE '%DDW%' THEN 0 ELSE 1 END) RemovalSort
					FROM SampleReport.Base B
					INNER JOIN cteDupes D ON B.VIN = D.VIN AND B.EventDate = D.EventDate
					WHERE DuplicateRowFlag <> 1

	UPDATE B
	SET DedupeEqualToEvents = 1
	FROM SampleReport.Base B
	WHERE DuplicateRowFlag = 1

	UPDATE B 
	SET DedupeEqualToEvents = 1
	FROM SampleReport.Base B
		INNER JOIN #SortDupesForRemovalV2 R ON R.AuditItemID = B.AuditItemID
		WHERE R.RemovalSort > 1
	AND R.SentDate IS NULL


	--V1.73
	IF @DailyEcho = 1
	BEGIN 

		--SAME METHOD OF SETTING DATE RANGE AS YTD RUN
		SELECT  @LastMonthDate = DATEADD(dd, 0, DATEDIFF(dd, 0, DATEADD(m, -3, @ReportDate)));
		SELECT @StartYearDate = CONVERT(DATETIME, CONVERT(VARCHAR(8), DATEPART(YEAR, @LastMonthDate)) + '0101')
		SELECT  @EndDate = DATEADD(DD, 0, DATEDIFF(dd, 0, @ReportDate) + 1);

		--Update DedupeEqualToEvents during daily run to be consistent with YTD run
		--NB DuplicateRow intentionally updated after this statement, flagging duplicates against any previous sample, not just YTD.
		UPDATE B 
		SET B.DedupeEqualToEvents = 1
		FROM SampleReport.Base B
			INNER JOIN SampleReport.YearlyEchoHistory R ON R.MatchedODSEventID = B.MatchedODSEventID
		WHERE   R.FileActionDate >= @StartYearDate
        AND		R.FileActionDate < @EndDate
		AND		R.AuditItemID <> B.AuditItemID

	END
	
	UPDATE SampleReport.Base
		SET DedupeEqualToEvents = 0
	WHERE DedupeEqualToEvents IS NULL

	------------------------------------------------------------------------------------------------
	-- Add Bouncebacks 
	------------------------------------------------------------------------------------------------

        UPDATE  B
        SET     BouncebackFlag = 1
        FROM    SampleReport.Base B
                INNER JOIN [$(SampleDB)].Event.CaseContactMechanismOutcomes CCO ON CCO.CaseID = B.CaseID
                INNER JOIN [$(SampleDB)].ContactMechanism.OutcomeCodes OC ON CCO.OutcomeCode = OC.OutcomeCode
        WHERE   OC.OutcomeCode IN ( '10', '20', '22', '50', '52', '54', '110' )
                OR ( OC.OutcomeCode = '99'
                     AND ISNULL(CaseEmailAddress, '') <> ''
                   );		-- v1.7
                   
        UPDATE  B
        SET     HardBounce = 1
        FROM    SampleReport.Base B
                INNER JOIN [$(SampleDB)].Event.CaseContactMechanismOutcomes CCO ON CCO.CaseID = B.CaseID
                INNER JOIN [$(SampleDB)].ContactMechanism.OutcomeCodes OC ON CCO.OutcomeCode = OC.OutcomeCode
        WHERE   OC.OutcomeCode IN ( '10') --V1.25
        
        UPDATE  SampleReport.Base
				SET HardBounce = 0
        WHERE HardBounce IS NULL
               
	   
	   UPDATE  B
        SET     [SoftBounce] = 1
        FROM    SampleReport.Base B
                INNER JOIN [$(SampleDB)].Event.CaseContactMechanismOutcomes CCO ON CCO.CaseID = B.CaseID
                INNER JOIN [$(SampleDB)].ContactMechanism.OutcomeCodes OC ON CCO.OutcomeCode = OC.OutcomeCode
        WHERE   OC.OutcomeCode IN ('20', '21', '22', '23','24','25', '50', '51','52','53','54','70' )
                OR ( OC.OutcomeCode = '99'
                     AND ISNULL(CaseEmailAddress, '') <> ''
                   ); --V1.25
	   
	   UPDATE  SampleReport.Base -- V1.32
			    SET [SoftBounce] = 0
       WHERE RespondedFlag = 1
       AND CaseOutputType = 'Online'
	   
	   UPDATE  SampleReport.Base
			    SET [SoftBounce] = 0
       WHERE [SoftBounce] IS NULL
	   
	------------------------------------------------------------------------------------------------
	-- Add Previous Event Email Bouncebacks 
	------------------------------------------------------------------------------------------------
        UPDATE  B
        SET     PreviousEventBounceBack = 1
        FROM    [$(SampleDB)].[dbo].NonSolicitations ns
                INNER JOIN [$(SampleDB)].[dbo].NonSolicitationTexts nst ON ns.NonSolicitationTextID = nst.NonSolicitationTextID
                                                              AND nst.NonSolicitationText = 'Email Bounce Back'
                INNER JOIN SampleReport.Base B ON ns.PartyID = COALESCE(NULLIF(B.MatchedODSPersonID, 0), NULLIF(B.MatchedODSOrganisationID, 0), NULLIF(B.MatchedODSPartyID, 0)) -- V1.67 fix, missing NULLIF within COALESCE
                LEFT JOIN [$(SampleDB)].Meta.PartyBestEmailAddresses pbe ON ns.PartyID = pbe.PartyID
        WHERE   ( ns.FromDate < B.LoadedDate )
                AND    --v1.8	
                ( pbe.ContactMechanismID IS NULL );
        
		 

        SELECT COALESCE(NULLIF(Y.MatchedODSPersonID, 0), NULLIF(Y.MatchedODSOrganisationID, 0), NULLIF(Y.MatchedODSPartyID, 0)) AS [CoalescePartyID], Y.MatchedODSEventID,Y.MatchedODSEmailAddressID, Y.[SoftBounce]
        INTO #PrevSoftBounce
        FROM SampleReport.YearlyEchoHistory Y -- V1.95
        WHERE Y.[SoftBounce] = 1 -- V1.28
        

        UPDATE  B
        SET     PrevSoftBounce = 1
        FROM    SampleReport.Base B
				INNER JOIN #PrevSoftBounce PSB ON PSB.CoalescePartyID = COALESCE(NULLIF(B.MatchedODSPersonID, 0), NULLIF(B.MatchedODSOrganisationID, 0), NULLIF(B.MatchedODSPartyID, 0))
								 AND PSB.MatchedODSEmailAddressID = B.MatchedODSEmailAddressID
		where PSB.MatchedODSEventID < B.MatchedODSEventID -- V1.28

		
        UPDATE  SampleReport.Base
				SET PrevSoftBounce = 0
        WHERE PrevSoftBounce IS NULL -- V1.28
          
		  

		SELECT COALESCE(NULLIF(Y.MatchedODSPersonID, 0), NULLIF(Y.MatchedODSOrganisationID, 0), NULLIF(Y.MatchedODSPartyID, 0)) AS [CoalescePartyID], Y.MatchedODSEventID,Y.MatchedODSEmailAddressID, Y.HardBounce
        INTO #PrevHardBounce
        FROM SampleReport.YearlyEchoHistory Y -- V1.95
        WHERE Y.HardBounce = 1 -- V1.28
        
        
        UPDATE  B
        SET     PrevHardBounce = 1
        FROM    SampleReport.Base B
				INNER JOIN #PrevHardBounce PHB ON PHB.CoalescePartyID = COALESCE(NULLIF(B.MatchedODSPersonID, 0), NULLIF(B.MatchedODSOrganisationID, 0), NULLIF(B.MatchedODSPartyID, 0))
								 AND PHB.MatchedODSEmailAddressID = B.MatchedODSEmailAddressID
		where PHB.MatchedODSEventID < B.MatchedODSEventID -- V1.28
	   


	   UPDATE  SampleReport.Base
			    SET PrevHardBounce = 0
       WHERE PrevHardBounce IS NULL -- V1.28



	------------------------------------------------------------------------------------------------
	-- Add AFRL Code V1.16
	------------------------------------------------------------------------------------------------
        UPDATE  B
        SET     AFRLCode = vpre.AFRLCode
		FROM SampleReport.Base B
		INNER JOIN [$(AuditDB)].Audit.VehiclePartyRoleEventsAFRL vpre   ON vpre.EventID = B.MatchedODSEventID
		AND vpre.VehicleID = B.MatchedODSVehicleID
		AND vpre.PartyID = COALESCE(NULLIF(B.MatchedODSPersonID,0), NULLIF(B.MatchedODSOrganisationID,0));

	
	------------------------------------------------------------------------------------------------
	-- Add in any Additonal Info columns (Sales Type V1.16; DateOfLeadCreation V1.27)
	------------------------------------------------------------------------------------------------
        UPDATE  B
        SET     SalesType = aais.TypeOfSaleOrig,
				DateOfLeadCreation = aais.LostLead_DateOfLeadCreation			-- v1.27
		FROM SampleReport.Base B
		INNER JOIN [$(AuditDB)].Audit.AdditionalInfoSales aais ON B.AuditItemID = aais.AuditItemID


	------------------------------------------------------------------------------------------------
	-- Set Useable flag				Note: if this changes, check flags set from Cases (above)
	------------------------------------------------------------------------------------------------

        UPDATE  SampleReport.Base
        SET     UsableFlag = 1
        WHERE   DuplicateRowFlag = 0
                AND UnmatchedModel = 0
                AND UncodedDealer = 0
                AND EventAlreadySelected = 0
                AND NonLatestEvent = 0
                AND ExclusionListMatch = 0
                AND BarredEmailAddress = 0
                AND BarredDomain = 0
                AND InvalidModel = 0
                AND EventDateOutOfDate = 0
                AND EventNonSolicitation = 0
                AND RecontactPeriod = 0
                AND RelativeRecontactPeriod = 0
                AND MissingStreet = 0	-- Rule is: Email only market with missing email OR non-email with missing Address Line 1
                AND MissingPostcode = 0	-- Note: As these flags are only set if they are required by the output type we can against check all.
                AND MissingEmail = 0
                AND MissingTelephone = 0
                AND MissingStreetAndEmail = 0
                AND MissingTelephoneAndEmail = 0
                AND MissingMobilePhone = 0					-- v1.4
                AND MissingMobilePhoneAndEmail = 0			-- v1.4
                AND MissingPartyName = 0					-- v1.5		
                AND InvalidManufacturer = 0
                AND InternalDealer = 0
                AND InvalidOwnershipCycle = 0
                AND PreviousEventBounceBack = 0				-- v1.8
                AND EventDateTooYoung = 0					-- v1.8
				AND DealerExclusionListMatch = 0			-- V1.16
				AND InvalidAFRLCode = 0						-- V1.16
				AND InvalidSalesType = 0					-- V1.16
				AND PDIFlagSet = 0							-- v1.41 
				AND SVCRMInvalidSalesType = 0				-- v1.43
				AND ContactPreferencesSuppression = 0		-- V1.34
				AND InvalidDealerBrand = 0					-- V1.85
							
	------------------------------------------------------------------------------------------------
	-- Add in anonymity 
	------------------------------------------------------------------------------------------------

	-- As the anonymity flag could have been set on a caseID in a previous year and not in this 
	-- selection, we will link on eventID to Cases to get the anonymity flags
	
		--V1.83 REMOVED UPDATE
        UPDATE  b
        SET     AnonymityDealer = c.AnonymityDealer ,
                AnonymityManufacturer = c.AnonymityManufacturer 
                --VIN = '' ,
                --OutputFileModelDescription = '' ,
                --RegistrationDate = NULL ,
                --EventDate = NULL ,
                --RegistrationNumber = '' ,
                --OrganisationName = '' ,
                --FullName = '' ,
                --MatchedODSModelID = NULL ,
                --MatchedODSPartyID = 0 ,
                --MatchedODSPersonID = 0 ,
                --MatchedODSOrganisationID = 0 ,
                --MatchedODSAddressID = 0 ,
                --MatchedODSVehicleID = 0 ,
                --ODSRegistrationID = 0 ,
                --SampleEmailAddress = '' ,				--v1.4
                --CaseEmailAddress = ''					--v1.4
        FROM    SampleReport.Base b
                INNER JOIN [$(SampleDB)].Event.AutomotiveEventBasedInterviews aebi ON aebi.EventID = b.MatchedODSEventID
                INNER JOIN [$(SampleDB)].Event.Cases c ON c.CaseID = aebi.CaseID
        WHERE   ISNULL(c.AnonymityDealer, 0) = 1
                OR ISNULL(c.AnonymityManufacturer, 0) = 1;
       
       --V1.56         
       UPDATE  b
        SET     VIN = '[GDPR - Erased]' ,
                OutputFileModelDescription = '[GDPR - Erased]' ,
                RegistrationDate = NULL ,
                EventDate = NULL ,
                RegistrationNumber = '[GDPR - Erased]' ,
                OrganisationName = '[GDPR - Erased]' ,
                FullName = '[GDPR - Erased]' ,
                MatchedODSModelID = 88 , --code website uses to blank Model information
                MatchedODSPartyID = 0 ,
                MatchedODSPersonID = 0 ,
                MatchedODSOrganisationID = 0 ,
                MatchedODSAddressID = 0 ,
                MatchedODSVehicleID = 0 ,
                ODSRegistrationID = 0 ,
                SampleEmailAddress = '[GDPR - Erased]' ,				--v1.4
                CaseEmailAddress = '[GDPR - Erased]'					--v1.4
        FROM    SampleReport.Base b
        WHERE	b.GDPRflag = 1


		-- V1.91
		UPDATE	b 
		SET		FullName = '',
				OrganisationName = '',
				SampleEmailAddress = '',
				CaseEmailAddress = '',
				ServiceTechnicianName = '',
				ServiceAdvisorID = '',
				CRMSalesmanName = '',
				CRMSalesmanCode = '',
				SalesEmployeeCode = '',
				SalesEmployeeName = '',
				ServiceEmployeeCode = '',
				ServiceEmployeeName = '',
				RegistrationNumber = ''
		FROM    SampleReport.Base b
		WHERE	b.UnmatchedModel = 1

                
    --V1.47
		UPDATE	SampleReport.Base
		SET		AnonymityDealer = 0
		WHERE	AnonymityDealer IS NULL
		
		UPDATE	SampleReport.Base
		SET		AnonymityManufacturer = 0
		WHERE	AnonymityManufacturer IS NULL	

	----------------------------------------------------------------------------------------
	-- New Suppression Logic_for Sample Reporting Purposes	V1.63
	----------------------------------------------------------------------------------------
	
	--Contact preferences changed more than once.
		;WITH ContactPrefernce (RowNumber, Market, ContactPreferencesModel, ContactPreferencesPersist, AuditRecordType, UpdateDate)
		AS
		(
		SELECT ROW_NUMBER () OVER (ORDER BY Market,UpdateDate,AuditRecordType) RowNumber
		, Market
		, ContactPreferencesModel
		, ContactPreferencesPersist
		, AuditRecordType
		, UpdateDate
		FROM [$(AuditDB)].Audit.Markets
		WHERE AuditRecordType = 'DELETED'
		)
		SELECT F.Market, T.ContactPreferencesModel AS ContactPreferencesModel, 
			   T.ContactPreferencesPersist AS ContactPreferencesPersist, 
			   F.UpdateDate AS FromDate, T.UpdateDate AS ToDate
		INTO #ContactModel       
		FROM ContactPrefernce F, ContactPrefernce T
		WHERE T.RowNumber = F.RowNumber + 1
		AND T.Market = F.Market


		--Contact preferences initial setting from 1990 - first contact preferences change
		;WITH FirstDeleted (UpdateDate, Market)
		AS
		(
			SELECT MIN(UpdateDate), Market
			FROM [$(AuditDB)].Audit.Markets
			WHERE AuditRecordType = 'DELETED'
			GROUP BY Market
		)
		INSERT INTO #ContactModel 
		SELECT M.Market, M.ContactPreferencesModel AS ContactPreferencesModel_To,
			   M.ContactPreferencesPersist AS ContactPreferencesPersist,
			   '1990-01-01' AS FromDate, M.UpdateDate AS ToDate
		FROM [$(AuditDB)].Audit.Markets M
		INNER JOIN FirstDeleted F ON F.Market = M.Market
								  AND F.UpdateDate = M.UpdateDate 
		AND M.AuditRecordType = 'DELETED'
			
				
		--Contact preferences current setting, from last contact preferences change to current date
		;WITH FirstInserted (UpdateDate, Market)
		AS
		(
			SELECT Max(UpdateDate), Market
			FROM [$(AuditDB)].Audit.Markets
			WHERE AuditRecordType = 'INSERTED'
			GROUP BY Market
		)
		INSERT INTO #ContactModel 
		SELECT M.Market, M.ContactPreferencesModel AS ContactPreferencesModel,
			   M.ContactPreferencesPersist AS ContactPreferencesPersist,
			   M.UpdateDate AS FromDate, Convert(varchar(10), GETDATE(),120) AS ToDate
		FROM [$(AuditDB)].Audit.Markets M
		INNER JOIN FirstInserted F ON F.Market = M.Market
								  AND F.UpdateDate = M.UpdateDate 
		AND M.AuditRecordType = 'INSERTED'


		--BASE SETTINGS ON LAST SELECTION DATE
		--NB ContactPreferencesPersist VALUE IS FOR GLOBAL CONTACT PREFERENCE
		UPDATE B
		SET B.ContactPreferencesModel = CM.ContactPreferencesModel,
			B.ContactPreferencesPersist = CONVERT(INT,CM.ContactPreferencesPersist)
		FROM SampleReport.Base B
		INNER JOIN #ContactModel CM ON B.Market = CM.Market
		WHERE B.LoadedDate >= CM.FromDate AND B.LoadedDate < CM.ToDate
		

		--Take current values if audit values of contact preferences not assigned 
		--this means current values have not changed since set-up.
		UPDATE B
		SET B.ContactPreferencesModel = M.ContactPreferencesModel,
			B.ContactPreferencesPersist = CONVERT(INT,M.ContactPreferencesPersist)
		FROM SampleReport.Base B
		INNER JOIN [$(SampleDB)].dbo.Markets M ON M.Market = B.Market
		WHERE B.ContactPreferencesModel IS NULL
		AND B.ContactPreferencesPersist IS NULL

		--Update Global original suppressions
		UPDATE B
		SET B.OriginalPartySuppression =  CASE WHEN B.ContactPreferencesPersist = 1 
										  THEN CONVERT(INT,CP.OriginalPartySuppression)
										  ELSE 0 END ,
			B.OriginalPostalSuppression = CASE WHEN B.ContactPreferencesPersist = 1 
	                                      THEN CONVERT(INT,CP.OriginalPostalSuppression)
	                                      ELSE 0 END,
			B.OriginalEmailSuppression =  CASE WHEN B.ContactPreferencesPersist = 1
									      THEN CONVERT(INT,CP.OriginalEmailSuppression)
									      ELSE 0 END,
			B.OriginalPhoneSuppression =  CASE WHEN B.ContactPreferencesPersist = 1
										  THEN CONVERT(INT,CP.OriginalPhoneSuppression)
										  ELSE 0 END
		FROM SampleReport.Base B
		INNER JOIN [$(AuditDB)].Audit.ContactPreferences CP on CP.AuditItemID = B.AuditItemID
		WHERE B.ContactPreferencesModel = 'Global'

		--Update Survey original suppressions
		UPDATE B
		SET B.OriginalPartySuppression =  CASE WHEN CPS.ContactPreferencesPersist = 1 
										  THEN CONVERT(INT,CPS.OriginalPartySuppression)
										  ELSE 0 END,
			B.OriginalPostalSuppression = CASE WHEN CPS.ContactPreferencesPersist = 1
										  THEN CONVERT(INT,CPS.OriginalPostalSuppression)
										  ELSE 0 END,
			B.OriginalEmailSuppression =  CASE WHEN CPS.ContactPreferencesPersist = 1
										  THEN CONVERT(INT,CPS.OriginalEmailSuppression)
										  ELSE 0 END,
			B.OriginalPhoneSuppression =  CASE WHEN CPS.ContactPreferencesPersist = 1
										  THEN CONVERT(INT,CPS.OriginalPhoneSuppression)
										  ELSE 0 END,
			B.ContactPreferencesPersist = CPS.ContactPreferencesPersist -- contact prefernce at Survey level. 
			                                                            -- Sample.Party.ContactPreferencesEventCategoryOverides	settings takes precedance By Survey - recorded in Audit table
			                                                            						  
		FROM SampleReport.Base B
		INNER JOIN [$(AuditDB)].Audit.ContactPreferencesBySurvey CPS on CPS.AuditItemID = B.AuditItemID
		WHERE B.ContactPreferencesModel = 'By Survey'

		-- END OF V1.63 alteration

		--Remove NULL values
		UPDATE SampleReport.Base
		SET OriginalPartySuppression = 0
		WHERE OriginalPartySuppression IS NULL

		UPDATE SampleReport.Base
		SET OriginalPostalSuppression = 0
		WHERE OriginalPostalSuppression IS NULL

		UPDATE SampleReport.Base
		SET OriginalEmailSuppression = 0
		WHERE OriginalEmailSuppression IS NULL

		UPDATE SampleReport.Base
		SET OriginalPhoneSuppression = 0
		WHERE OriginalPhoneSuppression IS NULL
		
		----2 or more PIDS loaded for first time so no Original suppression in Audit
		----first record can have suppressions, second (+) may not but same suppressions applied during selection for all reocords
		----4 logic statements below patches scenario
		UPDATE SampleReport.Base
		SET OriginalPartySuppression = ContactPreferencesPartySuppress
		WHERE PartySuppression = 0
		AND OriginalPartySuppression = 0
		AND ContactPreferencesPersist = 1
		
		UPDATE SampleReport.Base
		SET OriginalPostalSuppression = ContactPreferencesPostalSuppress
		WHERE PostalSuppression = 0
		AND OriginalPostalSuppression = 0
		AND ContactPreferencesPersist = 1

		UPDATE SampleReport.Base
		SET OriginalEmailSuppression = ContactPreferencesEmailSuppress
		WHERE EmailSuppression = 0
		AND OriginalEmailSuppression = 0
		AND ContactPreferencesPersist = 1

		UPDATE SampleReport.Base
		SET OriginalPhoneSuppression = ContactPreferencesPhoneSuppress
		WHERE PhoneSuppression = 0
		AND OriginalPhoneSuppression = 0
		AND ContactPreferencesPersist = 1


		UPDATE B
		SET B.OriginalPostalSuppression = CASE
				WHEN CMT.ContactMethodologyType IN 
				(
				'Mixed (CATI & Email)',
				'Mixed (Email & SMS)',
				'Mixed (email & CATI)',
				'Email Only'
				)
				THEN 0
				ELSE B.OriginalPostalSuppression
			END,
			B.OriginalPhoneSuppression = CASE
				WHEN CMT.ContactMethodologyType IN 
				(
				'Mixed (email & postal)',
				'Email Only'
				)
				THEN 0
				ELSE B.OriginalPhoneSuppression
			END
		FROM SampleReport.Base B
		INNER JOIN(
		SELECT DISTINCT BMQ.ContactMethodologyTypeID,CM.ContactMethodologyType, BR.Brand, M.Market, Q.Questionnaire
			FROM [$(SampleDB)].[dbo].BrandMarketQuestionnaireMetadata BMQ
			INNER JOIN [$(SampleDB)].[dbo].Brands BR ON BR.BrandID= BMQ.BrandID
			INNER JOIN [$(SampleDB)].[dbo].Markets M ON M.MarketID = BMQ.MarketID
			INNER JOIN [$(SampleDB)].[dbo].Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
			INNER JOIN [$(SampleDB)].SelectionOutput.ContactMethodologyTypes CM ON CM.ContactMethodologyTypeID = BMQ.ContactMethodologyTypeID
			WHERE BMQ.SampleLoadActive = 1								
			) CMT ON CMT.Brand = B.Brand
					AND CMT.Questionnaire = B.Questionnaire
					AND CMT.Market = B.Market
		
	--------------------------------------------------------------------------------------------------------------------
	-- Existing Suppression Logic_for Sample Reporting Purposes	v1.44 (keep back-data the same before roll out of V1.63)
	--------------------------------------------------------------------------------------------------------------------
	UPDATE  B
		SET		B.OriginalPartySuppression = YH.OriginalPartySuppression,
				B.OriginalPostalSuppression = YH.OriginalPostalSuppression,
				B.OriginalEmailSuppression = YH.OriginalEmailSuppression,
				B.OriginalPhoneSuppression = YH.OriginalPhoneSuppression,
				B.ContactPreferencesModel = YH.ContactPreferencesModel,
			    B.ContactPreferencesPersist = YH.ContactPreferencesPersist
		FROM	SampleReport.Base B
		INNER JOIN SampleReport.YearlyEchoHistory YH ON B.AuditItemID = YH.AuditItemID
		WHERE B.FileActionDate < @CustomerPrefReCalc
		
	------------------------------------------------------------------------------------------------
	--V1.52 Customer Preference Override Flag
	------------------------------------------------------------------------------------------------
	
		--If record loaded date < = Override date and last processed date >= Override date (including time if on same date) then Override was applied to record
		UPDATE  B
		SET		B.OverrideFlag = 1
		
		FROM	SampleReport.Base B
			INNER JOIN [$(SampleDB)].Event.EventCategories EC ON EC.EventCategory = B.Questionnaire
			INNER JOIN [$(AuditDB)].Audit.ContactPreferencesBySurvey AB ON AB.PartyID = COALESCE(NULLIF(B.MatchedODSPersonID,0), NULLIF(B.MatchedODSOrganisationID,0), B.MatchedODSPartyID)
																		AND AB.EventCategoryID = EC.EventCategoryID 
	
		WHERE		B.FileActionDate <= AB.UpdateDate
		AND		B.SampleRowProcessedDate >= AB.UpdateDate
		AND		AB.OverridePreferences = 1
		
		
		--If PartyID loaded after PartyID override date and File Loaded date > newest PartyID loaded date, then override values were not applied
		;WITH PID_OVRD (PartyID, EventCategoryID, UpdateDate) AS
		(
			SELECT	AB.PartyID, AB.EventCategoryID, Max(AB.UpdateDate) AS UpdateDate
			FROM	[$(AuditDB)].Audit.ContactPreferencesBySurvey AB
				INNER JOIN SampleReport.Base B ON COALESCE(NULLIF(B.MatchedODSPersonID,0), NULLIF(B.MatchedODSOrganisationID,0), B.MatchedODSPartyID) = AB.PartyID
			WHERE	AB.OverridePreferences = 1
			GROUP BY AB.PartyID, AB.EventCategoryID
		),
			PID_AFTER (PartyID, EventCategoryID, UpdateDate) AS --PIDS that have been loaded after Override applied.
		(
			SELECT	AB.PartyID, AB.EventCategoryID, Max(AB.UpdateDate) AS UpdateDate
			FROM	[$(AuditDB)].Audit.ContactPreferencesBySurvey AB
				INNER JOIN PID_OVRD PO ON PO.PartyID = AB.PartyID
			WHERE	AB.OverridePreferences IS NULL
			AND		AB.UpdateDate > PO.UpdateDate
			GROUP BY AB.PartyID, AB.EventCategoryID
		)
		
			UPDATE B
			SET	   B.OverrideFlag = 0
			FROM   SampleReport.Base B
				INNER JOIN [$(SampleDB)].Event.EventCategories EC ON EC.EventCategory = B.Questionnaire
				INNER JOIN PID_AFTER PA ON PA.PartyID = COALESCE(NULLIF(B.MatchedODSPersonID,0), NULLIF(B.MatchedODSOrganisationID,0), B.MatchedODSPartyID)
									AND PA.EventCategoryID = EC.EventCategoryID 
			WHERE  B.FileActionDate >= PA.UpdateDate
	
	
		--APPLY OVERRIDE FLAG TO HIGHEST EVENT ID FOR EACH PARTY ID
		;WITH MaxEventPID (MatchedODSEventID, PartyID) AS
		(
			SELECT MAX(MATCHEDODSEVENTID), COALESCE(NULLIF(MatchedODSPersonID,0), NULLIF(MatchedODSOrganisationID,0), MatchedODSPartyID) AS PartyID
			FROM SampleReport.Base
			WHERE OverrideFlag = 1
			GROUP BY COALESCE(NULLIF(MatchedODSPersonID,0), NULLIF(MatchedODSOrganisationID,0), MatchedODSPartyID), MATCHEDODSEVENTID
		)
			UPDATE B
			SET	   B.OverrideFlag = 0
			FROM   SampleReport.Base B
				INNER JOIN MaxEventPID M ON M.PartyID = COALESCE(NULLIF(B.MatchedODSPersonID,0), NULLIF(B.MatchedODSOrganisationID,0), B.MatchedODSPartyID) 
			WHERE B.MatchedODSEventID < M.MatchedODSEventID  


		UPDATE  B
		SET		B.OverrideFlag = 0
		FROM	SampleReport.Base B
		WHERE	B.OverrideFlag IS NULL	
		
	
	 -- V1.55 - FLAG POOLED EVENTS RECEIVED BEFORE @StartYearDate AS DUPLICATES  --
    
    UPDATE B
    SET DuplicateRowFlag = 1
    FROM SampleReport.Base B
	INNER JOIN	[$(AuditDB)].Audit.Events AE ON AE.EventID = B.MatchedODSEventID
	INNER JOIN	[$(AuditDB)].dbo.AuditItems AI ON AI.AuditItemID = AE.AuditItemID
	INNER JOIN	[$(AuditDB)].dbo.Files F ON F.AuditID = AI.AuditID
	WHERE	F.ActionDate < @StartYearDate
	
	UPDATE B
	SET	 UsableFlag = 0, SentFlag = 0
	FROM SampleReport.Base B
	WHERE DedupeEqualToEvents = 1


	-- V1.95 
	UPDATE	B
	SET		B.SentFlag = 0
	FROM	SampleReport.Base B	
	WHERE	B.SentFlag IS NULL


	--V1.74
	UPDATE B
	SET	 UsableFlag = 0, SentDate = NULL
	FROM SampleReport.Base B
	WHERE UsableFlag = 1
	AND SentDate IS NOT NULL
	AND SentFlag = 0


	-- V1.95
	UPDATE	B
	SET		B.UsableFlag = 0
	FROM	SampleReport.Base B	
	WHERE	B.UsableFlag IS NULL

	
	-- V1.95
	UPDATE	B
	SET		B.PDIFlagSet = 0
	FROM	SampleReport.Base B	
	WHERE	B.PDIFlagSet IS NULL


	-- V1.95
	UPDATE	B
	SET		NoMatch_CRCAgent =	1
	FROM SampleReport.Base B
	INNER JOIN SampleReport.CasesNotOutputHealthCheck C ON B.CaseID = C.CaseID
	WHERE B.SentDate IS NULL
	AND	  B.SentFlag = 0
	AND	  ISNULL(B.CRC_Owner,'') = ''
	AND	  C.ReasonsForNonOutput LIKE '%CRC%' 


	-- V1.95
	UPDATE	B
	SET		NoMatch_InviteBMQ =	CASE WHEN C.ReasonsForNonOutput LIKE '%BMQ combination missing%' 
									 THEN 1
								ELSE 0 END,
			NoMatch_InviteLanguage = CASE WHEN C.ReasonsForNonOutput LIKE '%Language%' 
										  THEN 1
									 ELSE 0 END
	FROM SampleReport.Base B
	INNER JOIN SampleReport.CasesNotOutputHealthCheck C ON B.CaseID = C.CaseID
	WHERE B.SentDate IS NULL
	AND	  B.SentFlag = 0
	

	------------------------------------------------------------------------------------------------
	--V1.48 Add in otherExclusion reason
	------------------------------------------------------------------------------------------------

	    UPDATE  SampleReport.Base
        SET     OtherExclusion = 1
        WHERE   ISNULL(ManualRejectionFlag,0) = 0
                AND ISNULL(EventDateOutOfDate,0) = 0
				AND ISNULL(EventNonSolicitation ,0) = 0
				AND ISNULL(PartyNonSolicitation ,0) = 0
				AND ISNULL(UncodedDealer ,0) = 0
				AND ISNULL(NonLatestEvent ,0) = 0
				AND ISNULL(RecontactPeriod ,0) = 0
				AND ISNULL(ExclusionListMatch ,0) = 0
				AND ISNULL(InvalidEmailAddress ,0) = 0
				AND ISNULL(BarredEmailAddress ,0) = 0
				AND ISNULL(BarredDomain ,0) = 0
				AND ISNULL(EventAlreadySelected ,0) = 0
				AND ISNULL(InvalidOwnershipCycle ,0) = 0
				AND ISNULL(RelativeRecontactPeriod ,0) = 0
				AND ISNULL(InvalidManufacturer ,0) = 0
				AND ISNULL(UnmatchedModel ,0) = 0
				AND ISNULL(WrongEventType ,0) = 0
				AND ISNULL(MissingLanguage ,0) = 0
				AND ISNULL(PartySuppression ,0) = 0
				AND ISNULL(PostalSuppression ,0) = 0
				AND ISNULL(EmailSuppression ,0) = 0
				AND ISNULL(MissingEmail ,0) = 0
				AND ISNULL(EventDateTooYoung ,0) = 0
				AND ISNULL(DealerExclusionListMatch ,0) = 0
				AND ISNULL(PhoneSuppression ,0) = 0
				AND ISNULL(InvalidSalesType ,0) = 0
				AND ISNULL(PrevHardBounce ,0) = 0
				AND ISNULL(HardBounce ,0) = 0
				AND ISNULL(Unsubscribes ,0) = 0
				AND ISNULL(SVCRMInvalidSalesType ,0) = 0
				AND ISNULL(PDIFlagSet ,0) = 0
				AND ISNULL(OriginalPartySuppression ,0) = 0
				AND ISNULL(OriginalEmailSuppression ,0) = 0
				AND ISNULL(OriginalPhoneSuppression ,0) = 0
				AND ISNULL(OriginalPostalSuppression ,0) = 0
				AND ISNULL(SuppliedName ,0) = 1
				AND ISNULL(SuppliedAddress ,0) = 1
				AND ISNULL(SuppliedPhoneNumber ,0) = 1
				AND ISNULL(SuppliedMobilePhone ,0) = 1
				AND ISNULL(UsableFlag ,0) = 0
				AND ISNULL(InvalidDealerBrand, 0) = 1 --V1.85
				--AND ISNULL(AgentCodeFlag,0) = 0
				
				--V1.76
				UPDATE  SampleReport.Base
				SET		AgentCodeFlag = 0
				WHERE	Questionnaire NOT IN ('CRC', 'CRC General Enquiry') --V1.86
				
				UPDATE  SampleReport.Base
				SET     OtherExclusion = 0
				WHERE   ISNULL(AgentCodeFlag,0) = 1	
				AND		Questionnaire IN ('CRC', 'CRC General Enquiry') --V1.86
				
				UPDATE	SampleReport.Base
			    SET		OtherExclusion = 0
			    WHERE	OtherExclusion IS NULL		
 

	--Set new suppressions fields backdata to blank if loaded date of record is less than
	--roll out date of suppression change
	UPDATE SampleReport.Base
	SET ContactPreferencesSuppression = NULL, ContactPreferencesPartySuppress = NULL, ContactPreferencesEmailSuppress = NULL,
		ContactPreferencesPhoneSuppress = NULL, ContactPreferencesPostalSuppress = NULL, OriginalPartySuppression = NULL,
		OriginalPostalSuppression = NULL, OriginalEmailSuppression = NULL, OriginalPhoneSuppression = NULL
	WHERE FileActionDate < @NewSuppressionLogicDate
	
	----------------------------------------------------------------------------------------
	-- Update selection contact information	V1.61
	----------------------------------------------------------------------------------------

	UPDATE Y
	SET Y.SelectionEmail = E.EmailAddress
	FROM SampleReport.Base Y
	INNER JOIN [$(SampleDB)].ContactMechanism.EmailAddresses E ON E.ContactMechanismID = Y.SelectionEmailID

	UPDATE Y
	SET Y.SelectionPhone = T.ContactNumber
	FROM SampleReport.Base Y
	INNER JOIN [$(SampleDB)].ContactMechanism.TelephoneNumbers T ON T.ContactMechanismID = Y.SelectionPhoneID

	UPDATE Y
	SET Y.SelectionLandline = T.ContactNumber
	FROM SampleReport.Base Y
	INNER JOIN [$(SampleDB)].ContactMechanism.TelephoneNumbers T ON T.ContactMechanismID = Y.SelectionLandlineID

	UPDATE Y
	SET Y.SelectionMobile = T.ContactNumber
	FROM SampleReport.Base Y
	INNER JOIN [$(SampleDB)].ContactMechanism.TelephoneNumbers T ON T.ContactMechanismID = Y.SelectionMobileID


	----------------------------------------------------------------------------------------
	-- Update Category Exclusion Flags	V1.75
	----------------------------------------------------------------------------------------

	UPDATE B
	SET B.EmailExcludeBarred  =  1 
	FROM SampleReport.Base B
	INNER JOIN [$(SampleDB)].ContactMechanism.BlacklistContactMechanisms BCM ON BCM.ContactMechanismID = B.MatchedODSEmailAddressID
	INNER JOIN [$(SampleDB)].ContactMechanism.BlacklistStrings CMBS ON BCM.BlacklistStringID = CMBS.BlacklistStringID
	INNER JOIN [$(SampleDB)].ContactMechanism.BlacklistTypes CMBT ON CMBS.BlacklistTypeID = CMBT.BlacklistTypeID
	INNER join [$(SampleDB)].ContactMechanism.EmailExclusionCategories ec ON ec.EmailExclusionCategoryID = CMBT.EmailExclusionCategoryID
	WHERE EC.ExclusionCategoryName = 'JLR Exclusion - Barred Email'

	UPDATE B
	SET B.EmailExcludeGeneric  =  1 
	FROM SampleReport.Base B
	INNER JOIN [$(SampleDB)].ContactMechanism.BlacklistContactMechanisms BCM ON BCM.ContactMechanismID = B.MatchedODSEmailAddressID
	INNER JOIN [$(SampleDB)].ContactMechanism.BlacklistStrings CMBS ON BCM.BlacklistStringID = CMBS.BlacklistStringID
	INNER JOIN [$(SampleDB)].ContactMechanism.BlacklistTypes CMBT ON CMBS.BlacklistTypeID = CMBT.BlacklistTypeID
	INNER join [$(SampleDB)].ContactMechanism.EmailExclusionCategories ec ON ec.EmailExclusionCategoryID = CMBT.EmailExclusionCategoryID
	WHERE EC.ExclusionCategoryName = 'Email not usable - generic ''noemail'''

	UPDATE B
	SET B.EmailExcludeInvalid  =  1 
	FROM SampleReport.Base B
	INNER JOIN [$(SampleDB)].ContactMechanism.BlacklistContactMechanisms BCM ON BCM.ContactMechanismID = B.MatchedODSEmailAddressID
	INNER JOIN [$(SampleDB)].ContactMechanism.BlacklistStrings CMBS ON BCM.BlacklistStringID = CMBS.BlacklistStringID
	INNER JOIN [$(SampleDB)].ContactMechanism.BlacklistTypes CMBT ON CMBS.BlacklistTypeID = CMBT.BlacklistTypeID
	INNER join [$(SampleDB)].ContactMechanism.EmailExclusionCategories ec ON ec.EmailExclusionCategoryID = CMBT.EmailExclusionCategoryID
	WHERE EC.ExclusionCategoryName = 'Invalid Email'


	UPDATE B
	SET B.CompanyExcludeBodyShop = 1
	FROM SampleReport.Base B
	INNER JOIN [$(SampleDB)].Party.IndustryClassifications IC ON B.MatchedODSOrganisationID = IC.PartyID
	INNER JOIN [$(SampleDB)].Party.PartyExclusionCategories PEC ON PEC.PartyExclusionCategoryID = IC.PartyExclusionCategoryID
	WHERE PEC.ExclusionCategoryName = 'JLR Exclusion - Body shop'

	UPDATE B
	SET B.CompanyExcludeLeasing = 1
	FROM SampleReport.Base B
	INNER JOIN [$(SampleDB)].Party.IndustryClassifications IC ON B.MatchedODSOrganisationID = IC.PartyID
	INNER JOIN [$(SampleDB)].Party.PartyExclusionCategories PEC ON PEC.PartyExclusionCategoryID = IC.PartyExclusionCategoryID
	WHERE PEC.ExclusionCategoryName = 'JLR Exclusion - Leasing'

	UPDATE B
	SET B.CompanyExcludeFleet = 1
	FROM SampleReport.Base B
	INNER JOIN [$(SampleDB)].Party.IndustryClassifications IC ON B.MatchedODSOrganisationID = IC.PartyID
	INNER JOIN [$(SampleDB)].Party.PartyExclusionCategories PEC ON PEC.PartyExclusionCategoryID = IC.PartyExclusionCategoryID
	WHERE PEC.ExclusionCategoryName = 'JLR Exclusion - Fleet'

	UPDATE B
	SET B.CompanyExcludeBarredCo = 1
	FROM SampleReport.Base B
	INNER JOIN [$(SampleDB)].Party.IndustryClassifications IC ON B.MatchedODSOrganisationID = IC.PartyID
	INNER JOIN [$(SampleDB)].Party.PartyExclusionCategories PEC ON PEC.PartyExclusionCategoryID = IC.PartyExclusionCategoryID
	WHERE PEC.ExclusionCategoryName = 'JLR Exclusion - Barred Company'

	----------------------------------------------------------------------------------------
	-- Write Static report information to holding table	v1.64
	----------------------------------------------------------------------------------------
	
	IF @EchoFeed = 0 AND @DailyEcho = 0
	BEGIN
	
	--Remove previous reports run during same month to prevent duplication
	DELETE S
	FROM SampleReport.StaticReports S
	INNER JOIN SampleReport.Base B ON S.AuditItemID = B.AuditItemID
	WHERE (MONTH(S.ReportDate) = MONTH(B.ReportDate)
	AND S.MarketOrRegion = @MarketRegion)
	
	--Append Base table (add all fields from base table to this insert)
	INSERT INTO SampleReport.StaticReports  
			(	
				ReportDate, SuperNationalRegion, BusinessRegion, DealerMarket, SubNationalTerritory, SubNationalRegion, CombinedDealer, DealerName, -- v1.41 named columns
			DealerCode, DealerCodeGDD, FullName, OrganisationName, AnonymityDealer, AnonymityManufacturer, CaseCreationDate, CaseStatusType, 
			CaseOutputType, SentFlag, SentDate, RespondedFlag, ClosureDate, DuplicateRowFlag, BouncebackFlag, UsableFlag, ManualRejectionFlag, 
			FileName, FileActionDate, FileRowCount, LoadedDate, AuditID, AuditItemID, MatchedODSPartyID, MatchedODSPersonID, LanguageID, 
			PartySuppression, MatchedODSOrganisationID, MatchedODSAddressID, CountryID, PostalSuppression, EmailSuppression, MatchedODSVehicleID, 
			ODSRegistrationID, MatchedODSModelID, OwnershipCycle, MatchedODSEventID, ODSEventTypeID, WarrantyID, Brand, Market, Questionnaire, 
			QuestionnaireRequirementID, SuppliedName, SuppliedAddress, SuppliedPhoneNumber, SuppliedMobilePhone, SuppliedEmail, SuppliedVehicle, 
			SuppliedRegistration, SuppliedEventDate, EventDateOutOfDate, EventNonSolicitation, PartyNonSolicitation, UnmatchedModel, UncodedDealer, 
			EventAlreadySelected, NonLatestEvent, InvalidOwnershipCycle, RecontactPeriod, RelativeRecontactPeriod, InvalidVehicleRole, CrossBorderAddress, 
			CrossBorderDealer, ExclusionListMatch, InvalidEmailAddress, BarredEmailAddress, BarredDomain, CaseID, SampleRowProcessed, SampleRowProcessedDate, 
			WrongEventType, MissingStreet, MissingPostcode, MissingEmail, MissingTelephone, MissingStreetAndEmail, MissingTelephoneAndEmail, 
			MissingMobilePhone, MissingMobilePhoneAndEmail, MissingPartyName, MissingLanguage, InvalidModel, InvalidManufacturer, InternalDealer,
			RegistrationNumber, RegistrationDate, VIN, OutputFileModelDescription, EventDate, MatchedODSEmailAddressID, SampleEmailAddress, 
			CaseEmailAddress, PreviousEventBounceBack, EventDateTooYoung, PhysicalFileRow, DuplicateFileFlag, AFRLCode, DealerExclusionListMatch, 
			PhoneSuppression, SalesType, InvalidAFRLCode, InvalidSalesType, AgentCodeFlag, DataSource, HardBounce, [SoftBounce], DedupeEqualToEvents, 
			Unsubscribes, DateOfLeadCreation, PrevSoftBounce, PrevHardBounce, ServiceTechnicianID, ServiceTechnicianName, ServiceAdvisorName, 
			ServiceAdvisorID, CRMSalesmanName, CRMSalesmanCode, FOBCode, ContactPreferencesSuppression, ContactPreferencesPartySuppress, 
			ContactPreferencesEmailSuppress, ContactPreferencesPhoneSuppress, ContactPreferencesPostalSuppress, SVCRMSalesType, SVCRMInvalidSalesType, 
			DealNumber, RepairOrderNumber, VistaCommonOrderNumber, SalesEmployeeCode, SalesEmployeeName, ServiceEmployeeCode, ServiceEmployeeName, 
			RecordChanged, CheckSumCalc, ConcatenatedData, PDIFlagSet, ContactPreferencesModel,ContactPreferencesPersist, OriginalPartySuppression,
			OriginalPostalSuppression, OriginalEmailSuppression, OriginalPhoneSuppression, OtherExclusion, OverrideFlag, GDPRflag, DealerPartyID, SelectionPostalID,
			SelectionEmailID, SelectionPhoneID, SelectionLandlineID, SelectionMobileID, SelectionEmail, SelectionPhone, SelectionLandline, SelectionMobile, MarketOrRegion, InvalidDateOfLastContact, MatchedODSPrivEmailAddressID, SamplePrivEmailAddress,
			EmailExcludeBarred,EmailExcludeGeneric, EmailExcludeInvalid, CompanyExcludeBodyShop, CompanyExcludeLeasing, CompanyExcludeFleet, CompanyExcludeBarredCo, SubBrand, ModelCode, LeadVehSaleType, ModelVariant)
			
	SELECT ReportDate, SuperNationalRegion, BusinessRegion, DealerMarket, SubNationalTerritory, SubNationalRegion, CombinedDealer, DealerName, -- v1.41 named columns
			DealerCode, DealerCodeGDD, FullName, OrganisationName, AnonymityDealer, AnonymityManufacturer, CaseCreationDate, CaseStatusType, 
			CaseOutputType, SentFlag, SentDate, RespondedFlag, ClosureDate, DuplicateRowFlag, BouncebackFlag, UsableFlag, ManualRejectionFlag, 
			FileName, FileActionDate, FileRowCount, LoadedDate, AuditID, AuditItemID, MatchedODSPartyID, MatchedODSPersonID, LanguageID, 
			PartySuppression, MatchedODSOrganisationID, MatchedODSAddressID, CountryID, PostalSuppression, EmailSuppression, MatchedODSVehicleID, 
			ODSRegistrationID, MatchedODSModelID, OwnershipCycle, MatchedODSEventID, ODSEventTypeID, WarrantyID, Brand, Market, Questionnaire, 
			QuestionnaireRequirementID, SuppliedName, SuppliedAddress, SuppliedPhoneNumber, SuppliedMobilePhone, SuppliedEmail, SuppliedVehicle, 
			SuppliedRegistration, SuppliedEventDate, EventDateOutOfDate, EventNonSolicitation, PartyNonSolicitation, UnmatchedModel, UncodedDealer, 
			EventAlreadySelected, NonLatestEvent, InvalidOwnershipCycle, RecontactPeriod, RelativeRecontactPeriod, InvalidVehicleRole, CrossBorderAddress, 
			CrossBorderDealer, ExclusionListMatch, InvalidEmailAddress, BarredEmailAddress, BarredDomain, CaseID, SampleRowProcessed, SampleRowProcessedDate, 
			WrongEventType, MissingStreet, MissingPostcode, MissingEmail, MissingTelephone, MissingStreetAndEmail, MissingTelephoneAndEmail, 
			MissingMobilePhone, MissingMobilePhoneAndEmail, MissingPartyName, MissingLanguage, InvalidModel, InvalidManufacturer, InternalDealer,
			RegistrationNumber, RegistrationDate, VIN, OutputFileModelDescription, EventDate, MatchedODSEmailAddressID, SampleEmailAddress, 
			CaseEmailAddress, PreviousEventBounceBack, EventDateTooYoung, PhysicalFileRow, DuplicateFileFlag, AFRLCode, DealerExclusionListMatch, 
			PhoneSuppression, SalesType, InvalidAFRLCode, InvalidSalesType, AgentCodeFlag, DataSource, HardBounce, [SoftBounce], DedupeEqualToEvents, 
			Unsubscribes, DateOfLeadCreation, PrevSoftBounce, PrevHardBounce, ServiceTechnicianID, ServiceTechnicianName, ServiceAdvisorName, 
			ServiceAdvisorID, CRMSalesmanName, CRMSalesmanCode, FOBCode, ContactPreferencesSuppression, ContactPreferencesPartySuppress, 
			ContactPreferencesEmailSuppress, ContactPreferencesPhoneSuppress, ContactPreferencesPostalSuppress, SVCRMSalesType, SVCRMInvalidSalesType, 
			DealNumber, RepairOrderNumber, VistaCommonOrderNumber, SalesEmployeeCode, SalesEmployeeName, ServiceEmployeeCode, ServiceEmployeeName, 
			RecordChanged, CheckSumCalc, ConcatenatedData, PDIFlagSet, ContactPreferencesModel,ContactPreferencesPersist, OriginalPartySuppression,
			OriginalPostalSuppression, OriginalEmailSuppression, OriginalPhoneSuppression, OtherExclusion, OverrideFlag, GDPRflag, DealerPartyID, SelectionPostalID,
			SelectionEmailID, SelectionPhoneID, SelectionLandlineID, SelectionMobileID, SelectionEmail, SelectionPhone, SelectionLandline, SelectionMobile, @MarketRegion, InvalidDateOfLastContact, MatchedODSPrivEmailAddressID, SamplePrivEmailAddress,
			EmailExcludeBarred,EmailExcludeGeneric, EmailExcludeInvalid, CompanyExcludeBodyShop, CompanyExcludeLeasing, CompanyExcludeFleet, CompanyExcludeBarredCo, SubBrand, ModelCode, LeadVehSaleType, ModelVariant
	FROM SampleReport.Base
	
	END


	----------------------------------------------------------------------------------------
	-- Echo Sample Reporting on Sunday - Calculate RecordChangeField	v1.40
	----------------------------------------------------------------------------------------
	
	IF @EchoFeed = 1 OR @DailyEcho = 1
	BEGIN
	
	--V1.48 Only calculate value change and export data from LIVE date moving forward
	UPDATE SampleReport.Base
	SET OtherExclusion = NULL
	WHERE FileActionDate < @NewOtherExclusion
	
	------------------------------------------------------------------------------------------------
	-- V1.45 - Add in anonymity Echo website
	------------------------------------------------------------------------------------------------

	-- Insert records (records that have been flagged as changing) need to have value 'N/A'
	-- for the website to replace this value as a blank. Leaving just a blank value does not
	-- remove the original value already loaded to the website

	--V1.83 REMOVE UPDATE
        UPDATE  b
        SET     AnonymityDealer = c.AnonymityDealer ,
                AnonymityManufacturer = c.AnonymityManufacturer 
    --            VIN = 'N/A' ,
    --            OutputFileModelDescription = 'N/A' ,
    --            RegistrationNumber = 'N/A' ,
    --            OrganisationName = 'N/A' ,
    --            FullName = 'N/A',
    --            SampleEmailAddress = 'N/A' ,				--v1.4
    --            CaseEmailAddress = 'N/A',
    --            					--v1.4
    --            DealNumber = CASE WHEN DealNumber IS NOT NULL AND LTRIM(RTRIM(DealNumber)) <> ''
				--	THEN  'N/A'
				--	ELSE  DealNumber
				--END, 
				--RepairOrderNumber = CASE WHEN RepairOrderNumber IS NOT NULL AND LTRIM(RTRIM(RepairOrderNumber)) <> ''
				--	THEN 'N/A'
				--	ELSE RepairOrderNumber
				--END,
				--VistaCommonOrderNumber = CASE WHEN VistaCommonOrderNumber IS NOT NULL AND LTRIM(RTRIM(VistaCommonOrderNumber)) <> ''
				--	THEN 'N/A'
				--	ELSE VistaCommonOrderNumber
				--END,
				--CRMSalesmanName = CASE WHEN CRMSalesmanName IS NOT NULL AND LTRIM(RTRIM(CRMSalesmanName)) <> ''
				--	THEN 'N/A'
				--	ELSE CRMSalesmanName
				--END,
				--CRMSalesmanCode = CASE WHEN CRMSalesmanCode IS NOT NULL AND LTRIM(RTRIM(CRMSalesmanCode)) <> ''
				--	THEN 'N/A'
				--	ELSE CRMSalesmanCode
				--END,
				--ServiceTechnicianID = CASE WHEN ServiceTechnicianID IS NOT NULL AND LTRIM(RTRIM(ServiceTechnicianID)) <> ''
				--	THEN 'N/A'
				--	ELSE ServiceTechnicianID
				--END,
				--ServiceTechnicianName = CASE WHEN ServiceTechnicianName IS NOT NULL AND LTRIM(RTRIM(ServiceTechnicianName)) <> ''
				--	THEN 'N/A'
				--	ELSE ServiceTechnicianName
				--END,
				--ServiceAdvisorName = CASE WHEN ServiceAdvisorName IS NOT NULL AND LTRIM(RTRIM(ServiceAdvisorName)) <> ''
				--	THEN 'N/A'
				--	ELSE ServiceAdvisorName
				--END,
				--ServiceAdvisorID = CASE WHEN ServiceAdvisorID IS NOT NULL AND LTRIM(RTRIM(ServiceAdvisorID)) <> ''
				--	THEN 'N/A'
				--	ELSE ServiceAdvisorID
				--END,
				--SalesEmployeeCode = CASE WHEN SalesEmployeeCode IS NOT NULL AND LTRIM(RTRIM(SalesEmployeeCode)) <> ''
				--	THEN 'N/A'
				--	ELSE SalesEmployeeCode
				--END,
				--SalesEmployeeName = CASE WHEN SalesEmployeeName IS NOT NULL AND LTRIM(RTRIM(SalesEmployeeName)) <> ''
				--	THEN 'N/A'
				--	ELSE SalesEmployeeName
				--END,
				--ServiceEmployeeCode = CASE WHEN ServiceEmployeeCode IS NOT NULL AND LTRIM(RTRIM(ServiceEmployeeCode)) <> ''
				--	THEN 'N/A'
				--	ELSE ServiceEmployeeCode
				--END,
				--ServiceEmployeeName = CASE WHEN ServiceEmployeeName IS NOT NULL AND LTRIM(RTRIM(ServiceEmployeeName)) <> ''
				--	THEN 'N/A'
				--	ELSE ServiceEmployeeName
				--END
        FROM    SampleReport.Base b
                INNER JOIN [$(SampleDB)].Event.AutomotiveEventBasedInterviews aebi ON aebi.EventID = b.MatchedODSEventID
                INNER JOIN [$(SampleDB)].Event.Cases c ON c.CaseID = aebi.CaseID
        WHERE   ISNULL(c.AnonymityDealer, 0) = 1
                OR ISNULL(c.AnonymityManufacturer, 0) = 1;
                
     
    --V1.56
		UPDATE  b
        SET     VIN = '[GDPR - Erased]' ,
                OutputFileModelDescription = '[GDPR - Erased]' ,
                RegistrationNumber = '[GDPR - Erased]' ,
                OrganisationName = '[GDPR - Erased]' ,
                FullName = '[GDPR - Erased]',
                SampleEmailAddress = '[GDPR - Erased]' ,				
                CaseEmailAddress = '[GDPR - Erased]',
                					
                DealNumber = CASE WHEN DealNumber IS NOT NULL AND LTRIM(RTRIM(DealNumber)) <> ''
					THEN  '[GDPR - Erased]'
					ELSE  DealNumber
				END, 
				RepairOrderNumber = CASE WHEN RepairOrderNumber IS NOT NULL AND LTRIM(RTRIM(RepairOrderNumber)) <> ''
					THEN '[GDPR - Erased]'
					ELSE RepairOrderNumber
				END,
				VistaCommonOrderNumber = CASE WHEN VistaCommonOrderNumber IS NOT NULL AND LTRIM(RTRIM(VistaCommonOrderNumber)) <> ''
					THEN '[GDPR - Erased]'
					ELSE VistaCommonOrderNumber
				END,
				CRMSalesmanName = CASE WHEN CRMSalesmanName IS NOT NULL AND LTRIM(RTRIM(CRMSalesmanName)) <> ''
					THEN '[GDPR - Erased]'
					ELSE CRMSalesmanName
				END,
				CRMSalesmanCode = CASE WHEN CRMSalesmanCode IS NOT NULL AND LTRIM(RTRIM(CRMSalesmanCode)) <> ''
					THEN '[GDPR - Erased]'
					ELSE CRMSalesmanCode
				END,
				ServiceTechnicianID = CASE WHEN ServiceTechnicianID IS NOT NULL AND LTRIM(RTRIM(ServiceTechnicianID)) <> ''
					THEN '[GDPR - Erased]'
					ELSE ServiceTechnicianID
				END,
				ServiceTechnicianName = CASE WHEN ServiceTechnicianName IS NOT NULL AND LTRIM(RTRIM(ServiceTechnicianName)) <> ''
					THEN '[GDPR - Erased]'
					ELSE ServiceTechnicianName
				END,
				ServiceAdvisorName = CASE WHEN ServiceAdvisorName IS NOT NULL AND LTRIM(RTRIM(ServiceAdvisorName)) <> ''
					THEN '[GDPR - Erased]'
					ELSE ServiceAdvisorName
				END,
				ServiceAdvisorID = CASE WHEN ServiceAdvisorID IS NOT NULL AND LTRIM(RTRIM(ServiceAdvisorID)) <> ''
					THEN '[GDPR - Erased]'
					ELSE ServiceAdvisorID
				END,
				SalesEmployeeCode = CASE WHEN SalesEmployeeCode IS NOT NULL AND LTRIM(RTRIM(SalesEmployeeCode)) <> ''
					THEN '[GDPR - Erased]'
					ELSE SalesEmployeeCode
				END,
				SalesEmployeeName = CASE WHEN SalesEmployeeName IS NOT NULL AND LTRIM(RTRIM(SalesEmployeeName)) <> ''
					THEN '[GDPR - Erased]'
					ELSE SalesEmployeeName
				END,
				ServiceEmployeeCode = CASE WHEN ServiceEmployeeCode IS NOT NULL AND LTRIM(RTRIM(ServiceEmployeeCode)) <> ''
					THEN '[GDPR - Erased]'
					ELSE ServiceEmployeeCode
				END,
				ServiceEmployeeName = CASE WHEN ServiceEmployeeName IS NOT NULL AND LTRIM(RTRIM(ServiceEmployeeName)) <> ''
					THEN '[GDPR - Erased]'
					ELSE ServiceEmployeeName
				END
        FROM    SampleReport.Base b
		WHERE	b.GDPRflag = 1
                
                
    --V1.49 Remove in April 2018         
		UPDATE b
		SET	   DealerCode = '', DealerCodeGDD = ''
		FROM   SampleReport.Base b	
	

	--Add all fields exported to Echo files into String
	-- De-activated before V1.95 change
	--	UPDATE B
	--	SET B.ConcatenatedData = 
	--ISNULL(CAST([DealerCode] AS NVARCHAR),'') + '-' + ISNULL(CAST([DealerCodeGDD] AS NVARCHAR),'') + '-' + ISNULL(CAST([FullName] AS NVARCHAR), '') + '-' + ISNULL(CAST([OrganisationName] AS NVARCHAR), '') + '-' + ISNULL(CAST([CaseOutputType] AS NVARCHAR), '') + '-' + ISNULL(CAST([SentFlag] AS NVARCHAR), '') + '-' + ISNULL(CAST([SentDate] AS NVARCHAR), '') + '-' + ISNULL(CAST([RespondedFlag] AS NVARCHAR), '') + '-' + ISNULL(CAST([ClosureDate] AS NVARCHAR), '') + '-' + ISNULL(CAST([BouncebackFlag] AS NVARCHAR), '') + '-' + ISNULL(CAST([InvalidOwnershipCycle] AS NVARCHAR), '') + '-'
	--+ ISNULL(CAST([ManualRejectionFlag] AS NVARCHAR), '') + '-' + ISNULL(CAST([LoadedDate] AS NVARCHAR), '') + '-' + ISNULL(CAST([AuditItemID] AS NVARCHAR), '') + '-' + ISNULL(CAST([PartySuppression] AS NVARCHAR), '') + '-' + ISNULL(CAST([CountryID] AS NVARCHAR), '') + '-' + ISNULL(CAST([PostalSuppression] AS NVARCHAR), '') + '-' + ISNULL(CAST([EmailSuppression] AS NVARCHAR), '') + '-' + ISNULL(CAST([ODSEventTypeID] AS NVARCHAR), '') + '-' + ISNULL(CAST([CaseID] AS NVARCHAR), '') + '-'
	--+ ISNULL(CAST([Questionnaire] AS NVARCHAR), '') + '-' + ISNULL(CAST([SuppliedName] AS NVARCHAR), '') + '-' + ISNULL(CAST([SuppliedAddress] AS NVARCHAR), '') + '-' + ISNULL(CAST([SuppliedPhoneNumber] AS NVARCHAR), '') + '-' + ISNULL(CAST([SuppliedMobilePhone] AS NVARCHAR), '') + '-' + ISNULL(CAST([SuppliedVehicle] AS NVARCHAR), '') + '-' + ISNULL(CAST([UsableFlag] AS NVARCHAR), '') + '-' + ISNULL(CAST([EventDate] AS NVARCHAR), '') + '-'
	--+ ISNULL(CAST([SuppliedRegistration] AS NVARCHAR), '') + '-' + ISNULL(CAST([SuppliedEventDate] AS NVARCHAR), '') + '-' + ISNULL(CAST([EventDateOutOfDate] AS NVARCHAR), '') + '-' + ISNULL(CAST([EventNonSolicitation] AS NVARCHAR), '') + '-' + ISNULL(CAST([PartyNonSolicitation] AS NVARCHAR), '') + '-' + ISNULL(CAST([UnmatchedModel] AS NVARCHAR), '') + '-' + ISNULL(CAST([UncodedDealer] AS NVARCHAR), '') + '-' + ISNULL(CAST([EventAlreadySelected] AS NVARCHAR), '') + '-' + ISNULL(CAST([NonLatestEvent] AS NVARCHAR), '') + '-'
	--+ ISNULL(CAST([RecontactPeriod] AS NVARCHAR), '') + '-' + ISNULL(CAST([RelativeRecontactPeriod] AS NVARCHAR), '') + '-' + ISNULL(CAST([InvalidVehicleRole] AS NVARCHAR), '') + '-' + ISNULL(CAST([CrossBorderAddress] AS NVARCHAR), '') + '-' + ISNULL(CAST([CrossBorderDealer] AS NVARCHAR), '') + '-' + ISNULL(CAST([ExclusionListMatch] AS NVARCHAR), '') + '-' + ISNULL(CAST([InvalidEmailAddress] AS NVARCHAR), '') + '-' + ISNULL(CAST([BarredEmailAddress] AS NVARCHAR), '') + '-' + ISNULL(CAST([Unsubscribes] AS NVARCHAR), '') + '-'
	--+ ISNULL(CAST([WrongEventType] AS NVARCHAR), '') + '-' + ISNULL(CAST([MissingStreet] AS NVARCHAR), '') + '-' + ISNULL(CAST([MissingPostcode] AS NVARCHAR), '') + '-' + ISNULL(CAST([MissingEmail] AS NVARCHAR), '') + '-' + ISNULL(CAST([MissingTelephone] AS NVARCHAR), '') + '-' + ISNULL(CAST([MissingStreetAndEmail] AS NVARCHAR), '') + '-' + ISNULL(CAST([MissingTelephoneAndEmail] AS NVARCHAR), '') + '-' + ISNULL(CAST([MissingMobilePhone] AS NVARCHAR), '') + '-' + ISNULL(CAST([PrevSoftBounce] AS NVARCHAR), '') + '-'
	--+ ISNULL(CAST([MissingMobilePhoneAndEmail] AS NVARCHAR), '') + '-' + ISNULL(CAST([MissingPartyName] AS NVARCHAR), '') + '-' + ISNULL(CAST([MissingLanguage] AS NVARCHAR), '') + '-' + ISNULL(CAST([InvalidModel] AS NVARCHAR), '') + '-' + ISNULL(CAST([InvalidManufacturer] AS NVARCHAR), '') + '-' + ISNULL(CAST([InternalDealer] AS NVARCHAR), '') + '-' + ISNULL(CAST([RegistrationNumber] AS NVARCHAR), '') + '-' + ISNULL(CAST([RegistrationDate] AS NVARCHAR), '') + '-'
	--+ ISNULL(CAST([SampleEmailAddress] AS NVARCHAR), '') + '-' + ISNULL(CAST([CaseEmailAddress] AS NVARCHAR), '') + '-' + ISNULL(CAST([PreviousEventBounceBack] AS NVARCHAR), '') + '-' + ISNULL(CAST([EventDateTooYoung] AS NVARCHAR), '') + '-' + ISNULL(CAST([AFRLCode] AS NVARCHAR), '') + '-' + ISNULL(CAST([DealerExclusionListMatch] AS NVARCHAR), '') + '-' + ISNULL(CAST([DuplicateRowFlag] AS NVARCHAR), '') + '-' + ISNULL(CAST([VIN] AS NVARCHAR), '') + 
	--+ ISNULL(CAST([PhoneSuppression] AS NVARCHAR), '') + '-' + ISNULL(CAST([SalesType] AS NVARCHAR), '') + '-' + ISNULL(CAST([InvalidAFRLCode] AS NVARCHAR), '') + '-' + ISNULL(CAST([InvalidSalesType] AS NVARCHAR), '') + '-' + ISNULL(CAST([AgentCodeFlag] AS NVARCHAR), '') + '-' + ISNULL(CAST([DataSource] AS NVARCHAR), '') + '-' + ISNULL(CAST([HardBounce] AS NVARCHAR), '') + '-' + ISNULL(CAST([SoftBounce] AS NVARCHAR), '') + '-'
	--+ ISNULL(CAST([PrevHardBounce] AS NVARCHAR), '') + '-' + ISNULL(CAST([ServiceTechnicianID] AS NVARCHAR), '') + '-' + ISNULL(CAST([ServiceTechnicianName] AS NVARCHAR), '') + '-' + ISNULL(CAST([ServiceAdvisorName] AS NVARCHAR), '') + '-' + ISNULL(CAST([ServiceAdvisorID] AS NVARCHAR), '') + '-' + ISNULL(CAST([CRMSalesmanName] AS NVARCHAR), '') + '-' + ISNULL(CAST([CRMSalesmanCode] AS NVARCHAR), '') + '-'
	--+ ISNULL(CAST([SVCRMSalesType] AS NVARCHAR), '') + '-' + ISNULL(CAST([SVCRMInvalidSalesType] AS NVARCHAR), '') + '-' + ISNULL(CAST([DealNumber] AS NVARCHAR), '') + '-' + ISNULL(CAST([RepairOrderNumber] AS NVARCHAR), '') + '-' + ISNULL(CAST([VistaCommonOrderNumber] AS NVARCHAR), '') + '-'
	--+ ISNULL(CAST([SalesEmployeeCode] AS NVARCHAR), '') + '-' + ISNULL(CAST([SalesEmployeeName] AS NVARCHAR), '') + '-' + ISNULL(CAST([ServiceEmployeeCode] AS NVARCHAR), '') + '-' + ISNULL(CAST([ServiceEmployeeName] AS NVARCHAR), '') + '-' + ISNULL(CAST([MatchedODSEventID] AS NVARCHAR), '') + '-' + ISNULL(CAST([BarredDomain] AS NVARCHAR), '') + '-' + ISNULL(CAST([PDIFlagSet] AS NVARCHAR), '')  + '-'
	--+ ISNULL(CAST([ContactPreferencesSuppression] AS NVARCHAR), '')  + '-' + ISNULL(CAST([ContactPreferencesPartySuppress] AS NVARCHAR), '')  + '-' + ISNULL(CAST([ContactPreferencesEmailSuppress] AS NVARCHAR), '')  + '-' + ISNULL(CAST([ContactPreferencesPhoneSuppress] AS NVARCHAR), '')  + '-' + ISNULL(CAST([ContactPreferencesPostalSuppress] AS NVARCHAR), '')  + '-'
	--+ ISNULL(CAST([OriginalPartySuppression] AS NVARCHAR), '')  + '-' + ISNULL(CAST([OriginalPostalSuppression] AS NVARCHAR), '')  + '-' + ISNULL(CAST([OriginalEmailSuppression] AS NVARCHAR), '')  + '-' + ISNULL(CAST([OriginalPhoneSuppression] AS NVARCHAR), '')  + '-' + ISNULL(CAST([AnonymityDealer] AS NVARCHAR), '')  + '-' + ISNULL(CAST([AnonymityManufacturer] AS NVARCHAR), '')  + '-' + ISNULL(CAST([OtherExclusion] AS NVARCHAR), '')  + '-' + ISNULL(CAST([OverrideFlag] AS NVARCHAR), '')  + '-' + ISNULL(CAST([GDPRflag] AS NVARCHAR), '')  + '-' + ISNULL(CAST([DealerPartyID] AS NVARCHAR), '')
	--+ ISNULL(CAST([OutletPartyID] AS NVARCHAR), '')  + '-' + ISNULL(CAST([Dealer10DigitCode] AS NVARCHAR), '')  + '-' + ISNULL(CAST([OutletFunction] AS NVARCHAR), '')  + '-' + ISNULL(CAST([RoadsideAssistanceProvider] AS NVARCHAR), '')  + '-' + ISNULL(CAST([CRC_Owner] AS NVARCHAR), '')  + '-' + ISNULL(CAST([CountryIsoAlpha2] AS NVARCHAR), '')  + '-' + ISNULL(CAST([CRCMarketCode] AS NVARCHAR), '')  + '-' + ISNULL(CAST([InvalidDealerBrand] AS NVARCHAR), '') + '-' + ISNULL(CAST([SubBrand] AS NVARCHAR), '') + '-' 
	--+ ISNULL(CAST([ModelCode] AS NVARCHAR), '') + '-' + ISNULL(CAST([OutputFileModelDescription] AS NVARCHAR), '') + '-' + ISNULL(CAST([LeadVehSaleType] AS NVARCHAR), '')  + '-' + ISNULL(CAST([ModelVariant] AS NVARCHAR), '')
	--FROM SampleReport.Base B

	

	-- V1.95 - Removed Text outout from checking process
	--Add all fields exported to Echo files into String
		UPDATE B
		SET B.ConcatenatedData = 
	  ISNULL(CAST([CaseOutputType] AS NVARCHAR), '') + '-' + ISNULL(CAST([SentFlag] AS NVARCHAR), '') + '-' + ISNULL(CAST([SentDate] AS NVARCHAR), '') + '-' + ISNULL(CAST([RespondedFlag] AS NVARCHAR), '') + '-' + ISNULL(CAST([ClosureDate] AS NVARCHAR), '') + '-' + ISNULL(CAST([BouncebackFlag] AS NVARCHAR), '') + '-' + ISNULL(CAST([InvalidOwnershipCycle] AS NVARCHAR), '') + '-'
	+ ISNULL(CAST([ManualRejectionFlag] AS NVARCHAR), '') + '-' + ISNULL(CAST([LoadedDate] AS NVARCHAR), '') + '-' + ISNULL(CAST([AuditItemID] AS NVARCHAR), '') + '-' + ISNULL(CAST([PartySuppression] AS NVARCHAR), '') + '-' + ISNULL(CAST([CountryID] AS NVARCHAR), '') + '-' 
	+ ISNULL(CAST([EmailSuppression] AS NVARCHAR), '') + '-' + ISNULL(CAST([ODSEventTypeID] AS NVARCHAR), '') + '-' + ISNULL(CAST([CaseID] AS NVARCHAR), '') + '-'
	+ ISNULL(CAST([Questionnaire] AS NVARCHAR), '') + '-' + ISNULL(CAST([SuppliedName] AS NVARCHAR), '')  + '-' + ISNULL(CAST([SuppliedVehicle] AS NVARCHAR), '') + '-' + ISNULL(CAST([UsableFlag] AS NVARCHAR), '') + '-' + ISNULL(CAST([EventDate] AS NVARCHAR), '') + '-'
	+ ISNULL(CAST([SuppliedRegistration] AS NVARCHAR), '') + '-' + ISNULL(CAST([SuppliedEventDate] AS NVARCHAR), '') + '-' + ISNULL(CAST([EventDateOutOfDate] AS NVARCHAR), '') + '-' + ISNULL(CAST([EventNonSolicitation] AS NVARCHAR), '') + '-' + ISNULL(CAST([PartyNonSolicitation] AS NVARCHAR), '') + '-' + ISNULL(CAST([UnmatchedModel] AS NVARCHAR), '') + '-' + ISNULL(CAST([UncodedDealer] AS NVARCHAR), '') + '-' + ISNULL(CAST([EventAlreadySelected] AS NVARCHAR), '') + '-' + ISNULL(CAST([NonLatestEvent] AS NVARCHAR), '') + '-'
	+ ISNULL(CAST([RecontactPeriod] AS NVARCHAR), '') + '-' + ISNULL(CAST([RelativeRecontactPeriod] AS NVARCHAR), '') + '-' + ISNULL(CAST([InvalidVehicleRole] AS NVARCHAR), '') + '-' + ISNULL(CAST([CrossBorderAddress] AS NVARCHAR), '') + '-' + ISNULL(CAST([CrossBorderDealer] AS NVARCHAR), '') + '-' + ISNULL(CAST([ExclusionListMatch] AS NVARCHAR), '') + '-' + ISNULL(CAST([InvalidEmailAddress] AS NVARCHAR), '') + '-' + ISNULL(CAST([BarredEmailAddress] AS NVARCHAR), '') + '-' + ISNULL(CAST([Unsubscribes] AS NVARCHAR), '') + '-'
	+ ISNULL(CAST([WrongEventType] AS NVARCHAR), '') + '-' + ISNULL(CAST([MissingStreet] AS NVARCHAR), '') + '-' + ISNULL(CAST([MissingPostcode] AS NVARCHAR), '') + '-' + ISNULL(CAST([MissingEmail] AS NVARCHAR), '') + '-' + ISNULL(CAST([MissingStreetAndEmail] AS NVARCHAR), '') + '-' + ISNULL(CAST([MissingTelephoneAndEmail] AS NVARCHAR), '') + '-' + ISNULL(CAST([PrevSoftBounce] AS NVARCHAR), '') + '-'
	+ ISNULL(CAST([MissingMobilePhoneAndEmail] AS NVARCHAR), '') + '-' + ISNULL(CAST([MissingPartyName] AS NVARCHAR), '') + '-' + ISNULL(CAST([MissingLanguage] AS NVARCHAR), '') + '-' + ISNULL(CAST([InvalidModel] AS NVARCHAR), '') + '-' + ISNULL(CAST([InvalidManufacturer] AS NVARCHAR), '') + '-' + ISNULL(CAST([InternalDealer] AS NVARCHAR), '') + '-' + ISNULL(CAST([RegistrationDate] AS NVARCHAR), '') + '-'
	+ ISNULL(CAST([PreviousEventBounceBack] AS NVARCHAR), '') + '-' + ISNULL(CAST([EventDateTooYoung] AS NVARCHAR), '') + '-' + ISNULL(CAST([AFRLCode] AS NVARCHAR), '') + '-' + ISNULL(CAST([DealerExclusionListMatch] AS NVARCHAR), '') + '-' 
	+ ISNULL(CAST([PhoneSuppression] AS NVARCHAR), '') + '-' + ISNULL(CAST([SalesType] AS NVARCHAR), '') + '-' + ISNULL(CAST([InvalidAFRLCode] AS NVARCHAR), '') + '-' + ISNULL(CAST([InvalidSalesType] AS NVARCHAR), '') + '-' + ISNULL(CAST([AgentCodeFlag] AS NVARCHAR), '') + '-' + ISNULL(CAST([DataSource] AS NVARCHAR), '') + '-' + ISNULL(CAST([HardBounce] AS NVARCHAR), '') + '-' + ISNULL(CAST([SoftBounce] AS NVARCHAR), '') + '-'
	+ ISNULL(CAST([PrevHardBounce] AS NVARCHAR), '') + '-' + ISNULL(CAST([SVCRMInvalidSalesType] AS NVARCHAR), '') + '-'
	+ ISNULL(CAST([MatchedODSEventID] AS NVARCHAR), '') + '-' + ISNULL(CAST([BarredDomain] AS NVARCHAR), '') + '-' + ISNULL(CAST([PDIFlagSet] AS NVARCHAR), '')  + '-'
	+ ISNULL(CAST([ContactPreferencesSuppression] AS NVARCHAR), '')  + '-' + ISNULL(CAST([ContactPreferencesPartySuppress] AS NVARCHAR), '')  + '-' + ISNULL(CAST([ContactPreferencesEmailSuppress] AS NVARCHAR), '')  + '-' + ISNULL(CAST([ContactPreferencesPhoneSuppress] AS NVARCHAR), '')  + '-' + ISNULL(CAST([ContactPreferencesPostalSuppress] AS NVARCHAR), '')  + '-'
	+ ISNULL(CAST([OriginalPartySuppression] AS NVARCHAR), '') + '-' + ISNULL(CAST([OriginalEmailSuppression] AS NVARCHAR), '')  + '-' + ISNULL(CAST([AnonymityDealer] AS NVARCHAR), '')  + '-' + ISNULL(CAST([AnonymityManufacturer] AS NVARCHAR), '')  + '-' + ISNULL(CAST([OtherExclusion] AS NVARCHAR), '')  + '-' + ISNULL(CAST([OverrideFlag] AS NVARCHAR), '')  + '-' + ISNULL(CAST([GDPRflag] AS NVARCHAR), '')  + '-' + ISNULL(CAST([DealerPartyID] AS NVARCHAR), '') + '-'
	+ ISNULL(CAST([OutletPartyID] AS NVARCHAR), '')  + '-' + ISNULL(CAST([InvalidDealerBrand] AS NVARCHAR), '') + '-' + ISNULL(CAST([NoMatch_CRCAgent] AS NVARCHAR), '') + '-' + ISNULL(CAST([NoMatch_InviteBMQ] AS NVARCHAR), '') + '-' + ISNULL(CAST([NoMatch_InviteLanguage] AS NVARCHAR), '')
	FROM SampleReport.Base B
	

	--HASHBYTE 'MD5' algorithm has extremely low collision frequency when generating unique id for string, up to 8000 characters in length.
	UPDATE SampleReport.Base
	SET CheckSumCalc = HASHBYTES('MD5',  CONVERT(NVARCHAR(MAX), ConcatenatedData))
	
	--Remove records that havent changed from whats loaded already to website
	DELETE B
	FROM SampleReport.Base B
	INNER JOIN SampleReport.YearlyEchoHistory YH ON YH.AuditItemID = B.AuditItemID
	AND												YH.CheckSumCalc = B.CheckSumCalc
	
	--Flag records that have changed
	UPDATE B
	SET B.RecordChanged = 1
	FROM SampleReport.Base B
	INNER JOIN SampleReport.YearlyEchoHistory YH ON YH.AuditItemID = B.AuditItemID
	WHERE CONVERT(DATE,YH.ReportDate) < CONVERT(DATE,@ReportDate)

	
	-- V1.95 -- SET FLAG TO DEDUPE RECORDS LOADED AFTER FIRST EVENT
	UPDATE	B
	SET		B.DedupeHistoric = 1
	FROM	SampleReport.Base B	
	INNER JOIN	SampleReport.Base B2 ON B.MatchedODSEventID = B2.MatchedODSEventID
	WHERE	B2.AuditItemID < B.AuditItemID
	AND		B.SentFlag <> 1
	AND		B2.SentFlag <> 1


	-- V1.95 -- SET IF PREVIOUS EVENTS LOADED OUTSIDE OF DATE PERIOD OF RUN
	UPDATE B
	SET	   B.DedupeHistoric = 1
	FROM   SampleReport.Base B
	INNER JOIN SampleReport.YearlyEchoHistory Y ON B.MatchedODSEventID = Y.MatchedODSEventID
	WHERE	Y.AuditItemID < B.AuditItemID
	AND		B.SentFlag <> 1
	AND		Y.SentFlag <> 1
	AND		Y.CheckSumCalc = B.CheckSumCalc --STILL RE-EXPORT IF LATER AUDITITEMID AS CHANGED


	-- V1.95 -- SET FLAG TO DEDUPE RECORDS FOR ALL SENT EVENTS
	;WITH Sent_CTE (MatchedODSEventID)
	AS
		(
			SELECT  MatchedODSEventID
			FROM	SampleReport.Base B	
			WHERE	B.SentFlag = 1
			AND		B.CaseID IS NOT NULL
		)
	UPDATE B
	SET		B.DedupeHistoric = 1
	FROM	SampleReport.Base B	
	INNER JOIN	Sent_CTE C ON B.MatchedODSEventID = C.MatchedODSEventID


	-- V1.95 -- SET IF PREVIOUS EVENTS LOADED OUTSIDE OF DATE PERIOD OF RUN
	UPDATE B
	SET	   B.DedupeHistoric = 1
	FROM   SampleReport.Base B
	INNER JOIN SampleReport.YearlyEchoHistory Y ON B.MatchedODSEventID = Y.MatchedODSEventID
	WHERE	Y.SentFlag = 1
	AND		Y.CaseID IS NOT NULL


	-- V1.95 -- SET FLAG TO SEND TO MEDALLIA IF RECORD NOT OUTPUT AND FIRT UNIQUE EVENT
	UPDATE B
	SET	   B.MedalliaSent = 1
	FROM   SampleReport.Base B
	WHERE  B.DedupeHistoric IS NULL
	

	
	--Take a copy of duplicate record that has changed. Store older record for reference
	INSERT INTO SampleReport.YearlyEchoHistoryRecordChanged
	(	--v1.41 - named columns
				ReportDate, SuperNationalRegion, BusinessRegion, DealerMarket, SubNationalTerritory, SubNationalRegion, CombinedDealer, DealerName, -- v1.41 named columns
			DealerCode, DealerCodeGDD, FullName, OrganisationName, AnonymityDealer, AnonymityManufacturer, CaseCreationDate, CaseStatusType, 
			CaseOutputType, SentFlag, SentDate, RespondedFlag, ClosureDate, DuplicateRowFlag, BouncebackFlag, UsableFlag, ManualRejectionFlag, 
			FileName, FileActionDate, FileRowCount, LoadedDate, AuditID, AuditItemID, MatchedODSPartyID, MatchedODSPersonID, LanguageID, 
			PartySuppression, MatchedODSOrganisationID, MatchedODSAddressID, CountryID, PostalSuppression, EmailSuppression, MatchedODSVehicleID, 
			ODSRegistrationID, MatchedODSModelID, OwnershipCycle, MatchedODSEventID, ODSEventTypeID, WarrantyID, Brand, Market, Questionnaire, 
			QuestionnaireRequirementID, SuppliedName, SuppliedAddress, SuppliedPhoneNumber, SuppliedMobilePhone, SuppliedEmail, SuppliedVehicle, 
			SuppliedRegistration, SuppliedEventDate, EventDateOutOfDate, EventNonSolicitation, PartyNonSolicitation, UnmatchedModel, UncodedDealer, 
			EventAlreadySelected, NonLatestEvent, InvalidOwnershipCycle, RecontactPeriod, RelativeRecontactPeriod, InvalidVehicleRole, CrossBorderAddress, 
			CrossBorderDealer, ExclusionListMatch, InvalidEmailAddress, BarredEmailAddress, BarredDomain, CaseID, SampleRowProcessed, SampleRowProcessedDate, 
			WrongEventType, MissingStreet, MissingPostcode, MissingEmail, MissingTelephone, MissingStreetAndEmail, MissingTelephoneAndEmail, 
			MissingMobilePhone, MissingMobilePhoneAndEmail, MissingPartyName, MissingLanguage, InvalidModel, InvalidManufacturer, InternalDealer,
			RegistrationNumber, RegistrationDate, VIN, OutputFileModelDescription, EventDate, MatchedODSEmailAddressID, SampleEmailAddress, 
			CaseEmailAddress, PreviousEventBounceBack, EventDateTooYoung, PhysicalFileRow, DuplicateFileFlag, AFRLCode, DealerExclusionListMatch, 
			PhoneSuppression, SalesType, InvalidAFRLCode, InvalidSalesType, AgentCodeFlag, DataSource, HardBounce, [SoftBounce], DedupeEqualToEvents, 
			Unsubscribes, DateOfLeadCreation, PrevSoftBounce, PrevHardBounce, ServiceTechnicianID, ServiceTechnicianName, ServiceAdvisorName, 
			ServiceAdvisorID, CRMSalesmanName, CRMSalesmanCode, FOBCode, ContactPreferencesSuppression, ContactPreferencesPartySuppress, 
			ContactPreferencesEmailSuppress, ContactPreferencesPhoneSuppress, ContactPreferencesPostalSuppress, SVCRMSalesType, SVCRMInvalidSalesType, 
			DealNumber, RepairOrderNumber, VistaCommonOrderNumber, SalesEmployeeCode, SalesEmployeeName, ServiceEmployeeCode, ServiceEmployeeName, 
			RecordChanged, CheckSumCalc, ConcatenatedData, PDIFlagSet, ContactPreferencesModel,ContactPreferencesPersist, OriginalPartySuppression, OriginalPostalSuppression, OriginalEmailSuppression, OriginalPhoneSuppression, OtherExclusion, OverrideFlag, GDPRflag, DealerPartyID, SelectionPostalID, SelectionEmailID, SelectionPhoneID, SelectionLandlineID, SelectionMobileID, SelectionEmail, SelectionPhone, SelectionLandline, SelectionMobile, InvalidDateOfLastContact, MatchedODSPrivEmailAddressID, SamplePrivEmailAddress,
			EmailExcludeBarred,EmailExcludeGeneric, EmailExcludeInvalid, CompanyExcludeBodyShop, CompanyExcludeLeasing, CompanyExcludeFleet, CompanyExcludeBarredCo, ReExported, OutletPartyID, Dealer10DigitCode, OutletFunction, RoadsideAssistanceProvider, CRC_Owner, ClosedBy, Owner, CountryIsoAlpha2, CRCMarketCode, InvalidDealerBrand, SubBrand, ModelCode, LeadVehSaleType, ModelVariant, NoMatch_CRCAgent, NoMatch_InviteBMQ, NoMatch_InviteLanguage, DedupeHistoric, MedalliaSent)
			
			
			
	SELECT H.ReportDate, H.SuperNationalRegion, H.BusinessRegion, H.DealerMarket, H.SubNationalTerritory, H.SubNationalRegion, H.CombinedDealer, H.DealerName, -- v1.41 named columns
			H.DealerCode, H.DealerCodeGDD, H.FullName, H.OrganisationName, H.AnonymityDealer, H.AnonymityManufacturer, H.CaseCreationDate, H.CaseStatusType, 
			H.CaseOutputType, H.SentFlag, H.SentDate, H.RespondedFlag, H.ClosureDate, H.DuplicateRowFlag, H.BouncebackFlag, H.UsableFlag, H.ManualRejectionFlag, 
			H.FileName, H.FileActionDate, H.FileRowCount, H.LoadedDate, H.AuditID, H.AuditItemID, H.MatchedODSPartyID, H.MatchedODSPersonID, H.LanguageID, 
			H.PartySuppression, H.MatchedODSOrganisationID, H.MatchedODSAddressID, H.CountryID, H.PostalSuppression, H.EmailSuppression, H.MatchedODSVehicleID, 
			H.ODSRegistrationID, H.MatchedODSModelID, H.OwnershipCycle, H.MatchedODSEventID, H.ODSEventTypeID, H.WarrantyID, H.Brand, H.Market, H.Questionnaire, 
			H.QuestionnaireRequirementID, H.SuppliedName, H.SuppliedAddress, H.SuppliedPhoneNumber, H.SuppliedMobilePhone, H.SuppliedEmail, H.SuppliedVehicle, 
			H.SuppliedRegistration, H.SuppliedEventDate, H.EventDateOutOfDate, H.EventNonSolicitation, H.PartyNonSolicitation, H.UnmatchedModel, H.UncodedDealer, 
			H.EventAlreadySelected, H.NonLatestEvent, H.InvalidOwnershipCycle, H.RecontactPeriod, H.RelativeRecontactPeriod, H.InvalidVehicleRole, H.CrossBorderAddress, 
			H.CrossBorderDealer, H.ExclusionListMatch, H.InvalidEmailAddress, H.BarredEmailAddress, H.BarredDomain, H.CaseID, H.SampleRowProcessed, H.SampleRowProcessedDate, 
			H.WrongEventType, H.MissingStreet, H.MissingPostcode, H.MissingEmail, H.MissingTelephone, H.MissingStreetAndEmail, H.MissingTelephoneAndEmail, 
			H.MissingMobilePhone, H.MissingMobilePhoneAndEmail, H.MissingPartyName, H.MissingLanguage, H.InvalidModel, H.InvalidManufacturer, H.InternalDealer,
			H.RegistrationNumber, H.RegistrationDate, H.VIN, H.OutputFileModelDescription, H.EventDate, H.MatchedODSEmailAddressID, H.SampleEmailAddress, 
			H.CaseEmailAddress, H.PreviousEventBounceBack, H.EventDateTooYoung, H.PhysicalFileRow, H.DuplicateFileFlag, H.AFRLCode, H.DealerExclusionListMatch, 
			H.PhoneSuppression, H.SalesType, H.InvalidAFRLCode, H.InvalidSalesType, H.AgentCodeFlag, H.DataSource, H.HardBounce, H.[SoftBounce], H.DedupeEqualToEvents, 
			H.Unsubscribes, H.DateOfLeadCreation, H.PrevSoftBounce, H.PrevHardBounce, H.ServiceTechnicianID, H.ServiceTechnicianName, H.ServiceAdvisorName, 
			H.ServiceAdvisorID, H.CRMSalesmanName, H.CRMSalesmanCode, H.FOBCode, H.ContactPreferencesSuppression, H.ContactPreferencesPartySuppress, 
			H.ContactPreferencesEmailSuppress, H.ContactPreferencesPhoneSuppress, H.ContactPreferencesPostalSuppress, H.SVCRMSalesType, H.SVCRMInvalidSalesType, 
			H.DealNumber, H.RepairOrderNumber, H.VistaCommonOrderNumber, H.SalesEmployeeCode, H.SalesEmployeeName, H.ServiceEmployeeCode, H.ServiceEmployeeName, 
			H.RecordChanged, H.CheckSumCalc, H.ConcatenatedData, H.PDIFlagSet, H.ContactPreferencesModel,H.ContactPreferencesPersist, H.OriginalPartySuppression, H.OriginalPostalSuppression, H.OriginalEmailSuppression, H.OriginalPhoneSuppression, H.OtherExclusion, H.OverrideFlag, H.GDPRflag, H.DealerPartyID, H.SelectionPostalID, H.SelectionEmailID, H.SelectionPhoneID, H.SelectionLandlineID, H.SelectionMobileID, H.SelectionEmail, H.SelectionPhone, H.SelectionLandline, H.SelectionMobile, H.InvalidDateOfLastContact, H.MatchedODSPrivEmailAddressID, H.SamplePrivEmailAddress,
			H.EmailExcludeBarred,H.EmailExcludeGeneric, H.EmailExcludeInvalid, H.CompanyExcludeBodyShop, H.CompanyExcludeLeasing, H.CompanyExcludeFleet, H.CompanyExcludeBarredCo, H.ReExported, H.OutletPartyID, H.Dealer10DigitCode, H.OutletFunction, H.RoadsideAssistanceProvider, H.CRC_Owner, H.ClosedBy, H.Owner, H.CountryIsoAlpha2, H.CRCMarketCode, H.InvalidDealerBrand, H.SubBrand, H.ModelCode, H.LeadVehSaleType, H.ModelVariant, H.NoMatch_CRCAgent, H.NoMatch_InviteBMQ, H.NoMatch_InviteLanguage, H.DedupeHistoric, H.MedalliaSent
	FROM SampleReport.YearlyEchoHistory H
	INNER JOIN SampleReport.Base B ON B.AuditItemID = H.AuditItemID
	
	--Remove records that have changed so newest values of record can be appended for check
	DELETE WH
	FROM SampleReport.YearlyEchoHistory WH
	INNER JOIN SampleReport.Base B ON B.AuditItemID = WH.AuditItemID
	
	--Insert new records and newest changed records 
	INSERT INTO SampleReport.YearlyEchoHistory  
			(	--v1.41 - named columns
				ReportDate, SuperNationalRegion, BusinessRegion, DealerMarket, SubNationalTerritory, SubNationalRegion, CombinedDealer, DealerName, -- v1.41 named columns
			DealerCode, DealerCodeGDD, FullName, OrganisationName, AnonymityDealer, AnonymityManufacturer, CaseCreationDate, CaseStatusType, 
			CaseOutputType, SentFlag, SentDate, RespondedFlag, ClosureDate, DuplicateRowFlag, BouncebackFlag, UsableFlag, ManualRejectionFlag, 
			FileName, FileActionDate, FileRowCount, LoadedDate, AuditID, AuditItemID, MatchedODSPartyID, MatchedODSPersonID, LanguageID, 
			PartySuppression, MatchedODSOrganisationID, MatchedODSAddressID, CountryID, PostalSuppression, EmailSuppression, MatchedODSVehicleID, 
			ODSRegistrationID, MatchedODSModelID, OwnershipCycle, MatchedODSEventID, ODSEventTypeID, WarrantyID, Brand, Market, Questionnaire, 
			QuestionnaireRequirementID, SuppliedName, SuppliedAddress, SuppliedPhoneNumber, SuppliedMobilePhone, SuppliedEmail, SuppliedVehicle, 
			SuppliedRegistration, SuppliedEventDate, EventDateOutOfDate, EventNonSolicitation, PartyNonSolicitation, UnmatchedModel, UncodedDealer, 
			EventAlreadySelected, NonLatestEvent, InvalidOwnershipCycle, RecontactPeriod, RelativeRecontactPeriod, InvalidVehicleRole, CrossBorderAddress, 
			CrossBorderDealer, ExclusionListMatch, InvalidEmailAddress, BarredEmailAddress, BarredDomain, CaseID, SampleRowProcessed, SampleRowProcessedDate, 
			WrongEventType, MissingStreet, MissingPostcode, MissingEmail, MissingTelephone, MissingStreetAndEmail, MissingTelephoneAndEmail, 
			MissingMobilePhone, MissingMobilePhoneAndEmail, MissingPartyName, MissingLanguage, InvalidModel, InvalidManufacturer, InternalDealer,
			RegistrationNumber, RegistrationDate, VIN, OutputFileModelDescription, EventDate, MatchedODSEmailAddressID, SampleEmailAddress, 
			CaseEmailAddress, PreviousEventBounceBack, EventDateTooYoung, PhysicalFileRow, DuplicateFileFlag, AFRLCode, DealerExclusionListMatch, 
			PhoneSuppression, SalesType, InvalidAFRLCode, InvalidSalesType, AgentCodeFlag, DataSource, HardBounce, [SoftBounce], DedupeEqualToEvents, 
			Unsubscribes, DateOfLeadCreation, PrevSoftBounce, PrevHardBounce, ServiceTechnicianID, ServiceTechnicianName, ServiceAdvisorName, 
			ServiceAdvisorID, CRMSalesmanName, CRMSalesmanCode, FOBCode, ContactPreferencesSuppression, ContactPreferencesPartySuppress, 
			ContactPreferencesEmailSuppress, ContactPreferencesPhoneSuppress, ContactPreferencesPostalSuppress, SVCRMSalesType, SVCRMInvalidSalesType, 
			DealNumber, RepairOrderNumber, VistaCommonOrderNumber, SalesEmployeeCode, SalesEmployeeName, ServiceEmployeeCode, ServiceEmployeeName, 
			RecordChanged, CheckSumCalc, ConcatenatedData, PDIFlagSet, ContactPreferencesModel,ContactPreferencesPersist, OriginalPartySuppression, OriginalPostalSuppression, OriginalEmailSuppression, OriginalPhoneSuppression, OtherExclusion, OverrideFlag, GDPRflag, DealerPartyID, SelectionPostalID, SelectionEmailID, SelectionPhoneID, SelectionLandlineID, SelectionMobileID, SelectionEmail, SelectionPhone, SelectionLandline, SelectionMobile, InvalidDateOfLastContact, MatchedODSPrivEmailAddressID, SamplePrivEmailAddress,
			EmailExcludeBarred,EmailExcludeGeneric, EmailExcludeInvalid, CompanyExcludeBodyShop, CompanyExcludeLeasing, CompanyExcludeFleet, CompanyExcludeBarredCo, OutletPartyID, Dealer10DigitCode, OutletFunction, RoadsideAssistanceProvider, CRC_Owner, ClosedBy, Owner, CountryIsoAlpha2, CRCMarketCode, InvalidDealerBrand, SubBrand, ModelCode, LeadVehSaleType, ModelVariant, NoMatch_CRCAgent, NoMatch_InviteBMQ, NoMatch_InviteLanguage, DedupeHistoric, MedalliaSent)
			
	SELECT ReportDate, SuperNationalRegion, BusinessRegion, DealerMarket, SubNationalTerritory, SubNationalRegion, CombinedDealer, DealerName, -- v1.41 named columns
			DealerCode, DealerCodeGDD, FullName, OrganisationName, AnonymityDealer, AnonymityManufacturer, CaseCreationDate, CaseStatusType, 
			CaseOutputType, SentFlag, SentDate, RespondedFlag, ClosureDate, DuplicateRowFlag, BouncebackFlag, UsableFlag, ManualRejectionFlag, 
			FileName, FileActionDate, FileRowCount, LoadedDate, AuditID, AuditItemID, MatchedODSPartyID, MatchedODSPersonID, LanguageID, 
			PartySuppression, MatchedODSOrganisationID, MatchedODSAddressID, CountryID, PostalSuppression, EmailSuppression, MatchedODSVehicleID, 
			ODSRegistrationID, MatchedODSModelID, OwnershipCycle, MatchedODSEventID, ODSEventTypeID, WarrantyID, Brand, Market, Questionnaire, 
			QuestionnaireRequirementID, SuppliedName, SuppliedAddress, SuppliedPhoneNumber, SuppliedMobilePhone, SuppliedEmail, SuppliedVehicle, 
			SuppliedRegistration, SuppliedEventDate, EventDateOutOfDate, EventNonSolicitation, PartyNonSolicitation, UnmatchedModel, UncodedDealer, 
			EventAlreadySelected, NonLatestEvent, InvalidOwnershipCycle, RecontactPeriod, RelativeRecontactPeriod, InvalidVehicleRole, CrossBorderAddress, 
			CrossBorderDealer, ExclusionListMatch, InvalidEmailAddress, BarredEmailAddress, BarredDomain, CaseID, SampleRowProcessed, SampleRowProcessedDate, 
			WrongEventType, MissingStreet, MissingPostcode, MissingEmail, MissingTelephone, MissingStreetAndEmail, MissingTelephoneAndEmail, 
			MissingMobilePhone, MissingMobilePhoneAndEmail, MissingPartyName, MissingLanguage, InvalidModel, InvalidManufacturer, InternalDealer,
			RegistrationNumber, RegistrationDate, VIN, OutputFileModelDescription, EventDate, MatchedODSEmailAddressID, SampleEmailAddress, 
			CaseEmailAddress, PreviousEventBounceBack, EventDateTooYoung, PhysicalFileRow, DuplicateFileFlag, AFRLCode, DealerExclusionListMatch, 
			PhoneSuppression, SalesType, InvalidAFRLCode, InvalidSalesType, AgentCodeFlag, DataSource, HardBounce, [SoftBounce], DedupeEqualToEvents, 
			Unsubscribes, DateOfLeadCreation, PrevSoftBounce, PrevHardBounce, ServiceTechnicianID, ServiceTechnicianName, ServiceAdvisorName, 
			ServiceAdvisorID, CRMSalesmanName, CRMSalesmanCode, FOBCode, ContactPreferencesSuppression, ContactPreferencesPartySuppress, 
			ContactPreferencesEmailSuppress, ContactPreferencesPhoneSuppress, ContactPreferencesPostalSuppress, SVCRMSalesType, SVCRMInvalidSalesType, 
			DealNumber, RepairOrderNumber, VistaCommonOrderNumber, SalesEmployeeCode, SalesEmployeeName, ServiceEmployeeCode, ServiceEmployeeName, 
			RecordChanged, CheckSumCalc, ConcatenatedData, PDIFlagSet, ContactPreferencesModel,ContactPreferencesPersist, OriginalPartySuppression, OriginalPostalSuppression, OriginalEmailSuppression, OriginalPhoneSuppression, OtherExclusion, OverrideFlag, GDPRflag, DealerPartyID, SelectionPostalID, SelectionEmailID, SelectionPhoneID, SelectionLandlineID, SelectionMobileID, SelectionEmail, SelectionPhone, SelectionLandline, SelectionMobile, InvalidDateOfLastContact, MatchedODSPrivEmailAddressID, SamplePrivEmailAddress,
			EmailExcludeBarred,EmailExcludeGeneric, EmailExcludeInvalid, CompanyExcludeBodyShop, CompanyExcludeLeasing, CompanyExcludeFleet, CompanyExcludeBarredCo, OutletPartyID, Dealer10DigitCode, OutletFunction, RoadsideAssistanceProvider, CRC_Owner, ClosedBy, Owner, CountryIsoAlpha2, CRCMarketCode, InvalidDealerBrand, SubBrand, ModelCode, LeadVehSaleType, ModelVariant, NoMatch_CRCAgent, NoMatch_InviteBMQ, NoMatch_InviteLanguage, DedupeHistoric, MedalliaSent
	FROM SampleReport.Base
	

	-- V1.9 - LINK TO VIEW THAT OUTPUTS ONE FILE
	DELETE I
	FROM SampleReport.IndividualRowsCombined I
	WHERE CONVERT(DATE,ReportDate) < CONVERT(DATE,GETDATE())


	INSERT INTO SampleReport.IndividualRowsCombined 
				(ReportDate, SuperNationalRegion, BusinessRegion, DealerMarket, SubNationalTerritory, SubNationalRegion, CombinedDealer, DealerName, DealerCode, DealerCodeGDD, FullName, OrganisationName, AnonymityDealer, AnonymityManufacturer, CaseCreationDate, CaseStatusType, CaseOutputType, SentFlag, SentDate, RespondedFlag, ClosureDate, DuplicateRowFlag, BouncebackFlag, UsableFlag, ManualRejectionFlag, FileName, FileActionDate, FileRowCount, LoadedDate, AuditID, AuditItemID, MatchedODSPartyID, MatchedODSPersonID, LanguageID, PartySuppression, MatchedODSOrganisationID, MatchedODSAddressID, CountryID, PostalSuppression, EmailSuppression, MatchedODSVehicleID, ODSRegistrationID, MatchedODSModelID, OwnershipCycle, MatchedODSEventID, ODSEventTypeID, WarrantyID, Brand, Market, Questionnaire, QuestionnaireRequirementID, SuppliedName, SuppliedAddress, SuppliedPhoneNumber, SuppliedMobilePhone, SuppliedEmail, SuppliedVehicle, SuppliedRegistration, SuppliedEventDate, EventDateOutOfDate, EventNonSolicitation, PartyNonSolicitation, UnmatchedModel, UncodedDealer, EventAlreadySelected, NonLatestEvent, InvalidOwnershipCycle, RecontactPeriod, RelativeRecontactPeriod, InvalidVehicleRole, CrossBorderAddress, CrossBorderDealer, ExclusionListMatch, InvalidEmailAddress, BarredEmailAddress, BarredDomain, CaseID, SampleRowProcessed, SampleRowProcessedDate, WrongEventType, MissingStreet, MissingPostcode, MissingEmail, MissingTelephone, MissingStreetAndEmail, MissingTelephoneAndEmail, MissingMobilePhone, MissingMobilePhoneAndEmail, MissingPartyName, MissingLanguage, InvalidModel, InvalidManufacturer, InternalDealer, RegistrationNumber, RegistrationDate, VIN, OutputFileModelDescription, EventDate, SampleEmailAddress, CaseEmailAddress, PreviousEventBounceBack, EventDateTooYoung, AFRLCode, DealerExclusionListMatch, PhoneSuppression, SalesType, InvalidAFRLCode, InvalidSalesType, AgentCodeFlag, DedupeEqualToEvents,HardBounce,SoftBounce,Unsubscribes, DateOfLeadCreation, PrevSoftBounce, PrevHardBounce,ServiceTechnicianID,ServiceTechnicianName,ServiceAdvisorName,ServiceAdvisorID,CRMSalesmanName,CRMSalesmanCode, FOBCode, ContactPreferencesSuppression, ContactPreferencesPartySuppress, ContactPreferencesEmailSuppress, ContactPreferencesPhoneSuppress, ContactPreferencesPostalSuppress, SVCRMSalesType, SVCRMInvalidSalesType, DealNumber, RepairOrderNumber, VistaCommonOrderNumber, SalesEmployeeCode, SalesEmployeeName, ServiceEmployeeCode, ServiceEmployeeName, RecordChanged, PDIFlagSet, OriginalPartySuppression, OriginalPostalSuppression, OriginalEmailSuppression, OriginalPhoneSuppression, OtherExclusion, OverrideFlag, GDPRflag, SelectionPostalID, SelectionEmailID, SelectionPhoneID, SelectionLandlineID, SelectionMobileID, SelectionEmail, SelectionPhone, SelectionLandline, SelectionMobile, ContactPreferencesModel,ContactPreferencesPersist, InvalidDateOfLastContact, MatchedODSPrivEmailAddressID, SamplePrivEmailAddress, EmailExcludeBarred,EmailExcludeGeneric, EmailExcludeInvalid, CompanyExcludeBodyShop, CompanyExcludeLeasing, CompanyExcludeFleet, CompanyExcludeBarredCo, OutletPartyID, Dealer10DigitCode, OutletFunction, RoadsideAssistanceProvider, CRC_Owner, ClosedBy, Owner, CountryIsoAlpha2, CRCMarketCode, InvalidDealerBrand, SubBrand, ModelCode, LeadVehSaleType, ModelVariant, NoMatch_CRCAgent, NoMatch_InviteBMQ, NoMatch_InviteLanguage, DedupeHistoric, MedalliaSent)  --V1.12 'AgentCodeFlag' added, V1.13 DedupeEqualToEvents added, V1.14 HardBounce,SoftBounce,Unsubscribes added, V1.15 - DateOfLeadCreation added, V1.17, V1.18, V1.19, V1.21, V1.22, V1.23, V1.25, v1.26, V1.27, V1.30, V1.31, V1.32, V1.33, V1.37,V1.39, V1.40, V1.41, V1.42, V1.43, V1.44
	SELECT       ReportDate, SuperNationalRegion, BusinessRegion, DealerMarket, SubNationalTerritory, SubNationalRegion, CombinedDealer, DealerName, DealerCode, DealerCodeGDD, FullName, OrganisationName, AnonymityDealer, AnonymityManufacturer, CaseCreationDate, CaseStatusType, CaseOutputType, SentFlag, SentDate, RespondedFlag, ClosureDate, DuplicateRowFlag, BouncebackFlag, UsableFlag, ManualRejectionFlag, FileName, FileActionDate, FileRowCount, LoadedDate, AuditID, AuditItemID, MatchedODSPartyID, MatchedODSPersonID, LanguageID, PartySuppression, MatchedODSOrganisationID, MatchedODSAddressID, CountryID, PostalSuppression, EmailSuppression, MatchedODSVehicleID, ODSRegistrationID, MatchedODSModelID, OwnershipCycle, MatchedODSEventID, ODSEventTypeID, WarrantyID, Brand, Market, Questionnaire, QuestionnaireRequirementID, SuppliedName, SuppliedAddress, SuppliedPhoneNumber, SuppliedMobilePhone, SuppliedEmail, SuppliedVehicle, SuppliedRegistration, SuppliedEventDate, EventDateOutOfDate, EventNonSolicitation, PartyNonSolicitation, UnmatchedModel, UncodedDealer, EventAlreadySelected, NonLatestEvent, InvalidOwnershipCycle, RecontactPeriod, RelativeRecontactPeriod, InvalidVehicleRole, CrossBorderAddress, CrossBorderDealer, ExclusionListMatch, InvalidEmailAddress, BarredEmailAddress, BarredDomain, CaseID, SampleRowProcessed, SampleRowProcessedDate, WrongEventType, MissingStreet, MissingPostcode, MissingEmail, MissingTelephone, MissingStreetAndEmail, MissingTelephoneAndEmail, MissingMobilePhone, MissingMobilePhoneAndEmail, MissingPartyName, MissingLanguage, InvalidModel, InvalidManufacturer, InternalDealer, RegistrationNumber, RegistrationDate, VIN, OutputFileModelDescription, EventDate, SampleEmailAddress, CaseEmailAddress, PreviousEventBounceBack, EventDateTooYoung, AFRLCode, DealerExclusionListMatch, PhoneSuppression, SalesType, InvalidAFRLCode, InvalidSalesType, AgentCodeFlag, DedupeEqualToEvents,HardBounce,[SoftBounce],Unsubscribes, DateOfLeadCreation, PrevSoftBounce, PrevHardBounce,ServiceTechnicianID,ServiceTechnicianName,ServiceAdvisorName,ServiceAdvisorID,CRMSalesmanName,CRMSalesmanCode, FOBCode, ContactPreferencesSuppression, ContactPreferencesPartySuppress, ContactPreferencesEmailSuppress, ContactPreferencesPhoneSuppress, ContactPreferencesPostalSuppress, SVCRMSalesType, SVCRMInvalidSalesType, DealNumber, RepairOrderNumber, VistaCommonOrderNumber, SalesEmployeeCode, SalesEmployeeName, ServiceEmployeeCode, ServiceEmployeeName, RecordChanged, PDIFlagSet, OriginalPartySuppression, OriginalPostalSuppression, OriginalEmailSuppression, OriginalPhoneSuppression, OtherExclusion, OverrideFlag, GDPRflag, SelectionPostalID, SelectionEmailID, SelectionPhoneID, SelectionLandlineID, SelectionMobileID, SelectionEmail, SelectionPhone, SelectionLandline, SelectionMobile, ContactPreferencesModel,ContactPreferencesPersist, InvalidDateOfLastContact, MatchedODSPrivEmailAddressID, SamplePrivEmailAddress, EmailExcludeBarred,EmailExcludeGeneric, EmailExcludeInvalid, CompanyExcludeBodyShop, CompanyExcludeLeasing, CompanyExcludeFleet, CompanyExcludeBarredCo, OutletPartyID, Dealer10DigitCode, OutletFunction, RoadsideAssistanceProvider, CRC_Owner, ClosedBy, Owner, CountryIsoAlpha2, CRCMarketCode, InvalidDealerBrand, SubBrand, ModelCode, LeadVehSaleType, ModelVariant, NoMatch_CRCAgent, NoMatch_InviteBMQ, NoMatch_InviteLanguage, DedupeHistoric, MedalliaSent   --V1.12 'AgentCodeFlag' added, V1.13 DedupeEqualToEvents added, V1.14 HardBounce,SoftBounce,Unsubscribes added, V1.15 - DateOfLeadCreation added, V1.17, V1.18, V1.19, V1.21, V1.22, V1.23, V1.25, v1.26, V1.27, V1.30, V1.31, V1.32, V1.33, V1.37, V1.39, V1.40, V1.41, V1.42, V1.43, V1.44
	FROM SampleReport.Base
	WHERE	MedalliaSent = 1

	END

 END
 ELSE	
	BEGIN
		--V1.66
		--LAST 12 MONTHS STATIC ROLLING
		SELECT  @StartYearDate = dateadd(month, datediff(month, 0, @ReportDate) - 12, 0);
		
		SELECT @EndDate = dateadd(month, datediff(month, -1, @ReportDate) -  1, -1);
		
		TRUNCATE TABLE SampleReport.Base;
		
		-- ADD REGION TO Temporary Table
		IF (OBJECT_ID('tempdb..#MarketRegion2') IS NOT NULL)
		BEGIN
			DROP TABLE #MarketRegion2
		END

		CREATE TABLE #MarketRegion2
			(
				Market varchar (200) ,
				Region varchar(200)
			)
			
		INSERT INTO #MarketRegion2
		SELECT M.Market, R.Region
		FROM [$(SampleDB)].[dbo].Markets M 
		INNER JOIN [$(SampleDB)].[dbo].Regions R ON M.RegionID = R.RegionID
		GROUP BY M.Market, R.Region
		
		--GET DATA LOADED TO WEBSITE
		INSERT INTO SampleReport.Base
	    (	--v1.41 - named columns
			ReportDate, SuperNationalRegion, BusinessRegion, DealerMarket, SubNationalTerritory, SubNationalRegion, CombinedDealer, DealerName, -- v1.41 named columns
			DealerCode, DealerCodeGDD, FullName, OrganisationName, AnonymityDealer, AnonymityManufacturer, CaseCreationDate, CaseStatusType, 
			CaseOutputType, SentFlag, SentDate, RespondedFlag, ClosureDate, DuplicateRowFlag, BouncebackFlag, UsableFlag, ManualRejectionFlag, 
			FileName, FileActionDate, FileRowCount, LoadedDate, AuditID, AuditItemID, MatchedODSPartyID, MatchedODSPersonID, LanguageID, 
			PartySuppression, MatchedODSOrganisationID, MatchedODSAddressID, CountryID, PostalSuppression, EmailSuppression, MatchedODSVehicleID, 
			ODSRegistrationID, MatchedODSModelID, OwnershipCycle, MatchedODSEventID, ODSEventTypeID, WarrantyID, Brand, Market, Questionnaire, 
			QuestionnaireRequirementID, SuppliedName, SuppliedAddress, SuppliedPhoneNumber, SuppliedMobilePhone, SuppliedEmail, SuppliedVehicle, 
			SuppliedRegistration, SuppliedEventDate, EventDateOutOfDate, EventNonSolicitation, PartyNonSolicitation, UnmatchedModel, UncodedDealer, 
			EventAlreadySelected, NonLatestEvent, InvalidOwnershipCycle, RecontactPeriod, RelativeRecontactPeriod, InvalidVehicleRole, CrossBorderAddress, 
			CrossBorderDealer, ExclusionListMatch, InvalidEmailAddress, BarredEmailAddress, BarredDomain, CaseID, SampleRowProcessed, SampleRowProcessedDate, 
			WrongEventType, MissingStreet, MissingPostcode, MissingEmail, MissingTelephone, MissingStreetAndEmail, MissingTelephoneAndEmail, 
			MissingMobilePhone, MissingMobilePhoneAndEmail, MissingPartyName, MissingLanguage, InvalidModel, InvalidManufacturer, InternalDealer,
			RegistrationNumber, RegistrationDate, VIN, OutputFileModelDescription, EventDate, MatchedODSEmailAddressID, SampleEmailAddress, 
			CaseEmailAddress, PreviousEventBounceBack, EventDateTooYoung, PhysicalFileRow, DuplicateFileFlag, AFRLCode, DealerExclusionListMatch, 
			PhoneSuppression, SalesType, InvalidAFRLCode, InvalidSalesType, AgentCodeFlag, DataSource, HardBounce, [SoftBounce], DedupeEqualToEvents, 
			Unsubscribes, DateOfLeadCreation, PrevSoftBounce, PrevHardBounce, ServiceTechnicianID, ServiceTechnicianName, ServiceAdvisorName, 
			ServiceAdvisorID, CRMSalesmanName, CRMSalesmanCode, FOBCode, ContactPreferencesSuppression, ContactPreferencesPartySuppress, 
			ContactPreferencesEmailSuppress, ContactPreferencesPhoneSuppress, ContactPreferencesPostalSuppress, SVCRMSalesType, SVCRMInvalidSalesType, 
			DealNumber, RepairOrderNumber, VistaCommonOrderNumber, SalesEmployeeCode, SalesEmployeeName, ServiceEmployeeCode, ServiceEmployeeName, 
			RecordChanged, CheckSumCalc, ConcatenatedData, PDIFlagSet, ContactPreferencesModel,ContactPreferencesPersist, OriginalPartySuppression, OriginalPostalSuppression, OriginalEmailSuppression, OriginalPhoneSuppression, OtherExclusion, OverrideFlag, GDPRflag, DealerPartyID, SelectionPostalID, SelectionEmailID, SelectionPhoneID, SelectionLandlineID, SelectionMobileID, SelectionEmail, SelectionPhone, SelectionLandline, SelectionMobile, InvalidDateOfLastContact, MatchedODSPrivEmailAddressID, SamplePrivEmailAddress,
			EmailExcludeBarred,EmailExcludeGeneric, EmailExcludeInvalid, CompanyExcludeBodyShop, CompanyExcludeLeasing, CompanyExcludeFleet, CompanyExcludeBarredCo, OutletPartyID, Dealer10DigitCode, OutletFunction, RoadsideAssistanceProvider, CRC_Owner, ClosedBy, Owner, CountryIsoAlpha2, CRCMarketCode, InvalidDealerBrand, SubBrand, ModelCode, LeadVehSaleType, ModelVariant)
			
	SELECT   H.ReportDate, H.SuperNationalRegion, H.BusinessRegion, H.DealerMarket, H.SubNationalTerritory, H.SubNationalRegion, H.CombinedDealer, H.DealerName, -- v1.41 named columns
			H.DealerCode, H.DealerCodeGDD, H.FullName, H.OrganisationName, H.AnonymityDealer, H.AnonymityManufacturer, H.CaseCreationDate, H.CaseStatusType, 
			H.CaseOutputType, H.SentFlag, H.SentDate, H.RespondedFlag, H.ClosureDate, H.DuplicateRowFlag, H.BouncebackFlag, H.UsableFlag, H.ManualRejectionFlag, 
			H.FileName, H.FileActionDate, H.FileRowCount, H.LoadedDate, H.AuditID, H.AuditItemID, H.MatchedODSPartyID, H.MatchedODSPersonID, H.LanguageID, 
			H.PartySuppression, H.MatchedODSOrganisationID, H.MatchedODSAddressID, H.CountryID, H.PostalSuppression, H.EmailSuppression, H.MatchedODSVehicleID, 
			H.ODSRegistrationID, H.MatchedODSModelID, H.OwnershipCycle, H.MatchedODSEventID, H.ODSEventTypeID, H.WarrantyID, H.Brand, H.Market, H.Questionnaire, 
			H.QuestionnaireRequirementID, H.SuppliedName, H.SuppliedAddress, H.SuppliedPhoneNumber, H.SuppliedMobilePhone, H.SuppliedEmail, H.SuppliedVehicle, 
			H.SuppliedRegistration, H.SuppliedEventDate, H.EventDateOutOfDate, H.EventNonSolicitation, H.PartyNonSolicitation, H.UnmatchedModel, H.UncodedDealer, 
			H.EventAlreadySelected, H.NonLatestEvent, H.InvalidOwnershipCycle, H.RecontactPeriod, H.RelativeRecontactPeriod, H.InvalidVehicleRole, H.CrossBorderAddress, 
			H.CrossBorderDealer, H.ExclusionListMatch, H.InvalidEmailAddress, H.BarredEmailAddress, H.BarredDomain, H.CaseID, H.SampleRowProcessed, H.SampleRowProcessedDate, 
			H.WrongEventType, H.MissingStreet, H.MissingPostcode, H.MissingEmail, H.MissingTelephone, H.MissingStreetAndEmail, H.MissingTelephoneAndEmail, 
			H.MissingMobilePhone, H.MissingMobilePhoneAndEmail, H.MissingPartyName, H.MissingLanguage, H.InvalidModel, H.InvalidManufacturer, H.InternalDealer,
			H.RegistrationNumber, H.RegistrationDate, H.VIN, H.OutputFileModelDescription, H.EventDate, H.MatchedODSEmailAddressID, H.SampleEmailAddress, 
			H.CaseEmailAddress, H.PreviousEventBounceBack, H.EventDateTooYoung, H.PhysicalFileRow, H.DuplicateFileFlag, H.AFRLCode, H.DealerExclusionListMatch, 
			H.PhoneSuppression, H.SalesType, H.InvalidAFRLCode, H.InvalidSalesType, H.AgentCodeFlag, H.DataSource, H.HardBounce, H.[SoftBounce], H.DedupeEqualToEvents, 
			H.Unsubscribes, H.DateOfLeadCreation, H.PrevSoftBounce, H.PrevHardBounce, H.ServiceTechnicianID, H.ServiceTechnicianName, H.ServiceAdvisorName, 
			H.ServiceAdvisorID, H.CRMSalesmanName, H.CRMSalesmanCode, H.FOBCode, H.ContactPreferencesSuppression, H.ContactPreferencesPartySuppress, 
			H.ContactPreferencesEmailSuppress, H.ContactPreferencesPhoneSuppress, H.ContactPreferencesPostalSuppress, H.SVCRMSalesType, H.SVCRMInvalidSalesType, 
			H.DealNumber, H.RepairOrderNumber, H.VistaCommonOrderNumber, H.SalesEmployeeCode, H.SalesEmployeeName, H.ServiceEmployeeCode, H.ServiceEmployeeName, 
			H.RecordChanged, H.CheckSumCalc, H.ConcatenatedData, H.PDIFlagSet, H.ContactPreferencesModel,H.ContactPreferencesPersist, H.OriginalPartySuppression, H.OriginalPostalSuppression, H.OriginalEmailSuppression, H.OriginalPhoneSuppression, H.OtherExclusion, H.OverrideFlag, H.GDPRflag, H.DealerPartyID, H.SelectionPostalID, H.SelectionEmailID, H.SelectionPhoneID, H.SelectionLandlineID, H.SelectionMobileID, H.SelectionEmail, H.SelectionPhone, H.SelectionLandline, H.SelectionMobile, H.InvalidDateOfLastContact, H.MatchedODSPrivEmailAddressID, H.SamplePrivEmailAddress,
			H.EmailExcludeBarred,H.EmailExcludeGeneric, H.EmailExcludeInvalid, H.CompanyExcludeBodyShop, H.CompanyExcludeLeasing, H.CompanyExcludeFleet, H.CompanyExcludeBarredCo, H.OutletPartyID, H.Dealer10DigitCode, H.OutletFunction, H.RoadsideAssistanceProvider, H.CRC_Owner, H.ClosedBy, H.Owner, H.CountryIsoAlpha2, H.CRCMarketCode, H.InvalidDealerBrand, H.SubBrand, H.ModelCode, H.LeadVehSaleType, H.ModelVariant
	FROM SampleReport.YearlyEchoHistory H
	JOIN #MarketRegion2 MR ON H.Market = MR.Market
							AND MR.Market = CASE @ReportType							
								WHEN 'Market' THEN @MarketRegion ELSE MR.Market END
							AND MR.Region = CASE @ReportType							
								WHEN 'Region' THEN @MarketRegion ELSE MR.Region END
	WHERE H.LoadedDate >= @StartYearDate AND CONVERT(DATE,H.LoadedDate) <= @EndDate
	AND H.Brand = @Brand
	AND	H.Questionnaire = @Questionnaire 	
	
 END

    END TRY
    BEGIN CATCH

        SELECT  @ErrorNumber = ERROR_NUMBER() ,
                @ErrorSeverity = ERROR_SEVERITY() ,
                @ErrorState = ERROR_STATE() ,
                @ErrorLocation = ERROR_PROCEDURE() ,
                @ErrorLine = ERROR_LINE() ,
                @ErrorMessage = ERROR_MESSAGE();

        EXEC [$(ErrorDB)].[dbo].uspLogDatabaseError @ErrorNumber,
            @ErrorSeverity, @ErrorState, @ErrorLocation, @ErrorLine,
            @ErrorMessage;
		
        RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine);
		
    END CATCH;
