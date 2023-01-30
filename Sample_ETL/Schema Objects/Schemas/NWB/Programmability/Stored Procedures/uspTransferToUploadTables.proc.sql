CREATE PROCEDURE NWB.uspTransferToUploadTables
	
AS

/*
	Purpose:	Transfer the staged Selection Files to the NWB Upload tables and create
				NWB Upload Request.
	
	Version			Date			Developer			Comment
	1.0				17-07-2019		Chris Ross			BUG 15430.  Original version.
	1.1				09-09-2019		Chris Ledger		BUG 15571 - Add Russia Questionnaires
	1.2				18-09-2019		Chris Ledger		BUG 15571 - Add Russia Bodyshop, CQI and IAssistance Questionnaires
	1.3				09-10-2019		Chris Ross			BUG 15646 - Add in CATISales and CATIService files.  Also update audit update step to include missing CQI columns.
	1.4				29-10-2019		Chris Ledger		BUG 15490 - Add DealerType field for LostLeads
	1.5				10-01-2020		Chris Ledger		BUG 15372 - Fix Hard coded references to databases
	1.6				06-02-2020		Chris Ledger		BUG 16891 - Add ServiceEventType field for Service.
	1.7				06-02-2020		Chris Ledger		BUG 16819 - Add Queue field for LostLeads.
	1.8				13-03-2020		Chris Ledger		BUG 16891 - Add ServiceEventType field for CATIService.
	1.9				17-03-2020		Chris Ledger		BUG 18002 - Add Powertrain for CQI.
	1.10			29-03-2021		Chris Ledger		Remove Powertrain for CQI.
	1.11			02-07-2021		Chris Ledger		Task 535 - Add EventID.
	1.12			06-07-2021		Chris Ledger		Task 548 - Add CRC General Enquiry.
	1.13			12-07-2021		Chris Ledger		Task 553 - Add CDSID for CRC & CRC General Enquiry.
	1.14			20-07-2021		Chris Ledger		Task 558 - Add EngineType field.
	1.15			21-07/2021		Chris Ledger		Task 552 - Add SVOvehicle field.
*/


SET NOCOUNT ON

	DECLARE @ErrorNumber INT
	DECLARE @ErrorSeverity INT
	DECLARE @ErrorState INT
	DECLARE @ErrorLocation NVARCHAR(500)
	DECLARE @ErrorLine INT
	DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	
		-----------------------------------------------------------------------------
		-- Error checks 
		-----------------------------------------------------------------------------

		-- Check LocalServer info record present for this server
		IF (SELECT COUNT(*) FROM NWB.LocalServers WHERE LocalServerName = @@SERVERNAME) = 0
		RAISERROR ('ERROR (NWB.uspTransferToUploadTables) : Local server information missing.',  16, 1) 


		-- Check all records have AuditItemIDs
		IF (SELECT COUNT(*) FROM NWB.SelectionOutputsStaging S WHERE S.AuditItemID IS NULL) > 0
		RAISERROR ('ERROR (NWB.uspTransferToUploadTables) : Metadata update failure. AuditItemIDs with NULL values present.',  16, 1) 


		-- Check ProjectIDs present for all records
		IF (SELECT COUNT(*) FROM NWB.SelectionOutputsStaging S
			WHERE NOT EXISTS (SELECT SUI.ProjectId FROM NWB.SurveyUploadInfo SUI 
								WHERE SUI.Questionnaire = S.Questionnaire
								AND SUI.LocalServerName = @@SERVERNAME
							  )
			) > 0
		RAISERROR ('ERROR (NWB.uspTransferToUploadTables) : ProjectIds missing for some records.',  16, 1) 

		-- Check there are no uncleared records in the staging table
		IF (SELECT COUNT(*) FROM NWB.SelectionOutputsStaging S
			WHERE S.NwbSampleUploadRequestKey IS NOT NULL
			) > 0
		RAISERROR ('ERROR (NWB.uspTransferToUploadTables) : Uncleared records in Selection Output Staging table.',  16, 1) 



	BEGIN TRAN
		
		-----------------------------------------------------------------------------
		-- Create list of Questionnaires for transfer
		-----------------------------------------------------------------------------
		DROP TABLE IF EXISTS #QuestionnairesForTransfer

		CREATE TABLE #QuestionnairesForTransfer
		(
			ID				INT IDENTITY(1, 1),
			Questionnaire	VARCHAR(255) NOT NULL
		)

		INSERT INTO #QuestionnairesForTransfer (Questionnaire)
		SELECT DISTINCT S.Questionnaire
		FROM NWB.SelectionOutputsStaging S
		


		-----------------------------------------------------------------------------
		-- Set up transfer proc param's and variables
		-----------------------------------------------------------------------------

		DECLARE @p_projectId			NVARCHAR(512), 
				@p_connectionString		NVARCHAR(512), 
				@p_tableName			NVARCHAR(512), 
				@p_hubName				NVARCHAR(512), 
				@p_targetServerName		NVARCHAR(512), 
				@p_reRandomizeSortId	BIT,

				@NwbSampleUploadRequestKey INT,
				@NwbCreatedTimestamp		DATETIME


		-- Set the local server info
		SELECT	@p_connectionString  = p_connectionString
		FROM NWB.LocalServers WHERE LocalServerName = @@SERVERNAME
		
		
		-----------------------------------------------------------------------------
		-- TRANSFERS - Loop through the #QuestionnairesForTransfer table
		-----------------------------------------------------------------------------
		
		-- Variables for loop
		DECLARE @Counter INT,
				@LoopMax INT,
				@CurrentQuestionnaire VARCHAR(255),
				@ProjectID NVARCHAR(512)


		SELECT @LoopMax = MAX(ID) FROM #QuestionnairesForTransfer
		SET @Counter = 1

		
		WHILE @Counter <= @LoopMax
		BEGIN ------------------------------------------------------------------------------

				-- Get the current Questionnaire
				SELECT @CurrentQuestionnaire = Questionnaire 
				FROM #QuestionnairesForTransfer 
				WHERE ID = @Counter


				-- Get the NWB Request Metadata 
				SELECT @p_projectId = SUI.ProjectId, 
					@p_tableName = SUI.UploadTableName,
					@p_hubName = TS.p_hubName,
					@p_targetServerName	= TS.p_targetServerName,
					@p_reRandomizeSortId = TS.p_reRandomizeSortId
				FROM NWB.SurveyUploadInfo SUI
					INNER JOIN NWB.TargetServers TS ON TS.TargetServerName = SUI.TargetServerName
				WHERE SUI.Questionnaire = @CurrentQuestionnaire
					AND SUI.LocalServerName = @@SERVERNAME

				
				-- FAILED or PENDING check --  Only action the upload if there are no pending Requests for this Table V1.1 Remove Questionnaire (ProjectId)
				IF 0 = (	SELECT COUNT(*) 
							FROM [$(NwbSampleUpload)].[dbo].[NwbSampleUpload_ut_Request] 
							WHERE InputParameter = @p_tableName
								--AND ProjectId = @p_projectId			V1.1						
								AND (ISNULL(fkSampleUploadStatusKey, 0) = 0 OR CompletedTimestamp IS NULL))
				
				BEGIN 

						------------------------------------------------------------------------------------
						-- Run Questionnaire specific updates
						------------------------------------------------------------------------------------

						IF @CurrentQuestionnaire = 'Sales'
						BEGIN 
							-- Clear down Upload table prior to population
							DELETE FROM [$(NwbSampleUpload)].SelectionUpload.Sales
							
							-- Populate upload table with new records
							INSERT INTO [$(NwbSampleUpload)].SelectionUpload.Sales ([PartyID], [ID], [FullModel], [Model], [sType], [CarReg], [Title], [Initial], [Surname], [Fullname], [DearName], [CoName], [Add1], [Add2], [Add3], [Add4], [Add5], [Add6], [Add7], [Add8], [Add9], [CTRY], [EmailAddress], [Dealer], [sno], [ccode], [modelcode], [lang], [manuf], [gender], [qver], [blank], [etype], [reminder], [week], [test], [SampleFlag], [PURCHASEsurveyfile], [ITYPE], [Expired], [EventDate], [VIN], [DealerCode], [GlobalDealerCode], [HomeNumber], [WorkNumber], [MobileNumber], [ModelYear], [CustomerUniqueID], [OwnershipCycle], [SalesEmployeeCode], [SalesEmployeeName], [ServiceEmployeeCode], [ServiceEmployeeName], [CRMSalesmanCode], [CRMSalesmanName], [CRMSalesmanCodeBlank], [CRMSalesmanNameBlank], [DealerPartyID], [Password], [ReportingDealerPartyID], [ModelVariantCode], [ModelVariantDescription], [SelectionDate], [CampaignId], [PilotCode], [EmailSignator], [EmailSignatorTitle], [EmailContactText], [EmailCompanyDetails], [JLRPrivacyPolicy], [JLRCompanyname], [RockarDealer], [SVOvehicle], [SVODealer], [VistaContractOrderNumber], [DealNo], [FOBCode], [UnknownLang], [BilingualFlag], [langBilingual], [DearNameBilingual], [EmailSignatorTitleBilingual], [EmailContactTextBilingual], [EmailCompanyDetailsBilingual], [JLRPrivacyPolicyBilingual], [HotTopicCodes], [EventID], [EngineType])	-- V1.11 V1.14
							SELECT [PartyID], [CaseID], [FullModel], [Model], [sType], [CarReg], [Title], [Initial], [Surname], [Fullname], [DearName], [CoName], [Add1], [Add2], [Add3], [Add4], [Add5], [Add6], [Add7], [Add8], [Add9], [CTRY], [EmailAddress], [Dealer], [sno], [ccode], [modelcode], [lang], [manuf], [gender], [qver], [blank], [etype], [reminder], [week], [test], [SampleFlag], [Surveyfile], [ITYPE], [Expired], [EventDate], [VIN], [DealerCode], [GlobalDealerCode], [HomeNumber], [WorkNumber], [MobileNumber], [ModelYear], [CustomerUniqueID], [OwnershipCycle], [SalesEmployeeCode], [SalesEmployeeName], [ServiceEmployeeCode], [ServiceEmployeeName], [CRMSalesmanCode], [CRMSalesmanName], [CRMSalesmanCodeBlank], [CRMSalesmanNameBlank], [DealerPartyID], [Password], [ReportingDealerPartyID], [ModelVariantCode], [ModelVariantDescription], [SelectionDate], [CampaignId], [PilotCode], [EmailSignator], [EmailSignatorTitle], [EmailContactText], [EmailCompanyDetails], [JLRPrivacyPolicy], [JLRCompanyname], [RockarDealer], [SVOvehicle], [SVODealer], [VistaContractOrderNumber], [DealNo], [FOBCode], [UnknownLang], [BilingualFlag], [langBilingual], [DearNameBilingual], [EmailSignatorTitleBilingual], [EmailContactTextBilingual], [EmailCompanyDetailsBilingual], [JLRPrivacyPolicyBilingual], [HotTopicCodes], [EventID], [EngineType]															-- V1.11 V1.14
							FROM NWB.SelectionOutputsStaging SOS 
							WHERE SOS.Questionnaire = 'Sales'
						END 

						IF @CurrentQuestionnaire = 'SalesRussia'	-- V1.1
						BEGIN 
							-- Clear down Upload table prior to population
							DELETE FROM [$(NwbSampleUpload)].SelectionUpload.Sales
							
							-- Populate upload table with new records
							INSERT INTO [$(NwbSampleUpload)].SelectionUpload.Sales ([PartyID], [ID], [FullModel], [Model], [sType], [CarReg], [Title], [Initial], [Surname], [Fullname], [DearName], [CoName], [Add1], [Add2], [Add3], [Add4], [Add5], [Add6], [Add7], [Add8], [Add9], [CTRY], [EmailAddress], [Dealer], [sno], [ccode], [modelcode], [lang], [manuf], [gender], [qver], [blank], [etype], [reminder], [week], [test], [SampleFlag], [PURCHASEsurveyfile], [ITYPE], [Expired], [EventDate], [VIN], [DealerCode], [GlobalDealerCode], [HomeNumber], [WorkNumber], [MobileNumber], [ModelYear], [CustomerUniqueID], [OwnershipCycle], [SalesEmployeeCode], [SalesEmployeeName], [ServiceEmployeeCode], [ServiceEmployeeName], [CRMSalesmanCode], [CRMSalesmanName], [CRMSalesmanCodeBlank], [CRMSalesmanNameBlank], [DealerPartyID], [Password], [ReportingDealerPartyID], [ModelVariantCode], [ModelVariantDescription], [SelectionDate], [CampaignId], [PilotCode], [EmailSignator], [EmailSignatorTitle], [EmailContactText], [EmailCompanyDetails], [JLRPrivacyPolicy], [JLRCompanyname], [RockarDealer], [SVOvehicle], [SVODealer], [VistaContractOrderNumber], [DealNo], [FOBCode], [UnknownLang], [BilingualFlag], [langBilingual], [DearNameBilingual], [EmailSignatorTitleBilingual], [EmailContactTextBilingual], [EmailCompanyDetailsBilingual], [JLRPrivacyPolicyBilingual], [HotTopicCodes], [EventID], [EngineType])	-- V1.11 V1.14
							SELECT [PartyID], [CaseID], [FullModel], [Model], [sType], [CarReg], [Title], [Initial], [Surname], [Fullname], [DearName], [CoName], [Add1], [Add2], [Add3], [Add4], [Add5], [Add6], [Add7], [Add8], [Add9], [CTRY], [EmailAddress], [Dealer], [sno], [ccode], [modelcode], [lang], [manuf], [gender], [qver], [blank], [etype], [reminder], [week], [test], [SampleFlag], [Surveyfile], [ITYPE], [Expired], [EventDate], [VIN], [DealerCode], [GlobalDealerCode], [HomeNumber], [WorkNumber], [MobileNumber], [ModelYear], [CustomerUniqueID], [OwnershipCycle], [SalesEmployeeCode], [SalesEmployeeName], [ServiceEmployeeCode], [ServiceEmployeeName], [CRMSalesmanCode], [CRMSalesmanName], [CRMSalesmanCodeBlank], [CRMSalesmanNameBlank], [DealerPartyID], [Password], [ReportingDealerPartyID], [ModelVariantCode], [ModelVariantDescription], [SelectionDate], [CampaignId], [PilotCode], [EmailSignator], [EmailSignatorTitle], [EmailContactText], [EmailCompanyDetails], [JLRPrivacyPolicy], [JLRCompanyname], [RockarDealer], [SVOvehicle], [SVODealer], [VistaContractOrderNumber], [DealNo], [FOBCode], [UnknownLang], [BilingualFlag], [langBilingual], [DearNameBilingual], [EmailSignatorTitleBilingual], [EmailContactTextBilingual], [EmailCompanyDetailsBilingual], [JLRPrivacyPolicyBilingual], [HotTopicCodes], [EventID], [EngineType]															-- V1.11 V1.14
							FROM NWB.SelectionOutputsStaging SOS 
							WHERE SOS.Questionnaire = 'SalesRussia'
						END 

						IF @CurrentQuestionnaire = 'Service'
						BEGIN 
							-- Clear down Upload table prior to population
							DELETE FROM [$(NwbSampleUpload)].SelectionUpload.Service
							
							-- Populate upload table with new records
							INSERT INTO [$(NwbSampleUpload)].SelectionUpload.Service ([PartyID], [ID], [FullModel], [Model], [sType], [CarReg], [Title], [Initial], [Surname], [Fullname], [DearName], [CoName], [Add1], [Add2], [Add3], [Add4], [Add5], [Add6], [Add7], [Add8], [Add9], [CTRY], [EmailAddress], [Dealer], [sno], [ccode], [modelcode], [lang], [manuf], [gender], [qver], [blank], [etype], [reminder], [week], [test], [SampleFlag], [SERVICEsurveyfile], [ITYPE], [Expired], [EventDate], [VIN], [DealerCode], [GlobalDealerCode], [HomeNumber], [WorkNumber], [MobileNumber], [ModelYear], [CustomerUniqueID], [OwnershipCycle], [SalesEmployeeCode], [SalesEmployeeName], [ServiceEmployeeCode], [ServiceEmployeeName], [ServiceTechnicianID], [ServiceTechnicianName], [ServiceAdvisorID], [ServiceAdvisorName], [DealerPartyID], [Password], [ReportingDealerPartyID], [ModelVariantCode], [ModelVariantDescription], [SelectionDate], [CampaignId], [PilotCode], [EmailSignator], [EmailSignatorTitle], [EmailContactText], [EmailCompanyDetails], [JLRPrivacyPolicy], [JLRCompanyname], [RockarDealer], [SVOvehicle], [SVODealer], [RepairOrderNumber], [FOBCode], [UnknownLang], [BilingualFlag], [langBilingual], [DearNameBilingual], [EmailSignatorTitleBilingual], [EmailContactTextBilingual], [EmailCompanyDetailsBilingual], [JLRPrivacyPolicyBilingual], [HotTopicCodes], [ServiceEventType], [EventID], [EngineType])	-- V1.6 V1.11 V1.14
							SELECT [PartyID], [CaseID], [FullModel], [Model], [sType], [CarReg], [Title], [Initial], [Surname], [Fullname], [DearName], [CoName], [Add1], [Add2], [Add3], [Add4], [Add5], [Add6], [Add7], [Add8], [Add9], [CTRY], [EmailAddress], [Dealer], [sno], [ccode], [modelcode], [lang], [manuf], [gender], [qver], [blank], [etype], [reminder], [week], [test], [SampleFlag], [Surveyfile], [ITYPE], [Expired], [EventDate], [VIN], [DealerCode], [GlobalDealerCode], [HomeNumber], [WorkNumber], [MobileNumber], [ModelYear], [CustomerUniqueID], [OwnershipCycle], [SalesEmployeeCode], [SalesEmployeeName], [ServiceEmployeeCode], [ServiceEmployeeName], [ServiceTechnicianID], [ServiceTechnicianName], [ServiceAdvisorID], [ServiceAdvisorName], [DealerPartyID], [Password], [ReportingDealerPartyID], [ModelVariantCode], [ModelVariantDescription], [SelectionDate], [CampaignId], [PilotCode], [EmailSignator], [EmailSignatorTitle], [EmailContactText], [EmailCompanyDetails], [JLRPrivacyPolicy], [JLRCompanyname], [RockarDealer], [SVOvehicle], [SVODealer], [RepairOrderNumber], [FOBCode], [UnknownLang], [BilingualFlag], [langBilingual], [DearNameBilingual], [EmailSignatorTitleBilingual], [EmailContactTextBilingual], [EmailCompanyDetailsBilingual], [JLRPrivacyPolicyBilingual], [HotTopicCodes], [ServiceEventType], [EventID], [EngineType]															-- V1.6 V1.11 V1.14
							FROM NWB.SelectionOutputsStaging SOS 
							WHERE SOS.Questionnaire = 'Service'
						END 

						IF @CurrentQuestionnaire = 'ServiceRussia'		-- V1.1
						BEGIN 
							-- Clear down Upload table prior to population
							DELETE FROM [$(NwbSampleUpload)].SelectionUpload.Service
							
							-- Populate upload table with new records
							INSERT INTO [$(NwbSampleUpload)].SelectionUpload.Service ([PartyID], [ID], [FullModel], [Model], [sType], [CarReg], [Title], [Initial], [Surname], [Fullname], [DearName], [CoName], [Add1], [Add2], [Add3], [Add4], [Add5], [Add6], [Add7], [Add8], [Add9], [CTRY], [EmailAddress], [Dealer], [sno], [ccode], [modelcode], [lang], [manuf], [gender], [qver], [blank], [etype], [reminder], [week], [test], [SampleFlag], [SERVICEsurveyfile], [ITYPE], [Expired], [EventDate], [VIN], [DealerCode], [GlobalDealerCode], [HomeNumber], [WorkNumber], [MobileNumber], [ModelYear], [CustomerUniqueID], [OwnershipCycle], [SalesEmployeeCode], [SalesEmployeeName], [ServiceEmployeeCode], [ServiceEmployeeName], [ServiceTechnicianID], [ServiceTechnicianName], [ServiceAdvisorID], [ServiceAdvisorName], [DealerPartyID], [Password], [ReportingDealerPartyID], [ModelVariantCode], [ModelVariantDescription], [SelectionDate], [CampaignId], [PilotCode], [EmailSignator], [EmailSignatorTitle], [EmailContactText], [EmailCompanyDetails], [JLRPrivacyPolicy], [JLRCompanyname], [RockarDealer], [SVOvehicle], [SVODealer], [RepairOrderNumber], [FOBCode], [UnknownLang], [BilingualFlag], [langBilingual], [DearNameBilingual], [EmailSignatorTitleBilingual], [EmailContactTextBilingual], [EmailCompanyDetailsBilingual], [JLRPrivacyPolicyBilingual], [HotTopicCodes], [ServiceEventType], [EventID], [EngineType])	-- V1.6 V1.11 V1.14
							SELECT [PartyID], [CaseID], [FullModel], [Model], [sType], [CarReg], [Title], [Initial], [Surname], [Fullname], [DearName], [CoName], [Add1], [Add2], [Add3], [Add4], [Add5], [Add6], [Add7], [Add8], [Add9], [CTRY], [EmailAddress], [Dealer], [sno], [ccode], [modelcode], [lang], [manuf], [gender], [qver], [blank], [etype], [reminder], [week], [test], [SampleFlag], [Surveyfile], [ITYPE], [Expired], [EventDate], [VIN], [DealerCode], [GlobalDealerCode], [HomeNumber], [WorkNumber], [MobileNumber], [ModelYear], [CustomerUniqueID], [OwnershipCycle], [SalesEmployeeCode], [SalesEmployeeName], [ServiceEmployeeCode], [ServiceEmployeeName], [ServiceTechnicianID], [ServiceTechnicianName], [ServiceAdvisorID], [ServiceAdvisorName], [DealerPartyID], [Password], [ReportingDealerPartyID], [ModelVariantCode], [ModelVariantDescription], [SelectionDate], [CampaignId], [PilotCode], [EmailSignator], [EmailSignatorTitle], [EmailContactText], [EmailCompanyDetails], [JLRPrivacyPolicy], [JLRCompanyname], [RockarDealer], [SVOvehicle], [SVODealer], [RepairOrderNumber], [FOBCode], [UnknownLang], [BilingualFlag], [langBilingual], [DearNameBilingual], [EmailSignatorTitleBilingual], [EmailContactTextBilingual], [EmailCompanyDetailsBilingual], [JLRPrivacyPolicyBilingual], [HotTopicCodes], [ServiceEventType], [EventID], [EngineType]															-- V1.6 V1.11 V1.14
							FROM NWB.SelectionOutputsStaging SOS 
							WHERE SOS.Questionnaire = 'ServiceRussia'
						END 

						IF @CurrentQuestionnaire = 'Bodyshop'
						BEGIN 
							-- Clear down Upload table prior to population
							DELETE FROM [$(NwbSampleUpload)].SelectionUpload.Bodyshop
							
							-- Populate upload table with new records
							INSERT INTO [$(NwbSampleUpload)].SelectionUpload.Bodyshop ([PartyID], [ID], [FullModel], [Model], [sType], [CarReg], [Title], [Initial], [Surname], [Fullname], [DearName], [CoName], [Add1], [Add2], [Add3], [Add4], [Add5], [Add6], [Add7], [Add8], [Add9], [CTRY], [EmailAddress], [Dealer], [sno], [ccode], [modelcode], [lang], [manuf], [gender], [qver], [blank], [etype], [reminder], [week], [test], [SampleFlag], [BODYSHOPsurveyfile], [ITYPE], [Expired], [EventDate], [VIN], [DealerCode], [GlobalDealerCode], [HomeNumber], [WorkNumber], [MobileNumber], [ModelYear], [CustomerUniqueID], [OwnershipCycle], [SalesEmployeeCode], [SalesEmployeeName], [ServiceEmployeeCode], [ServiceEmployeeName], [ServiceTechnicianID], [ServiceTechnicianName], [ServiceAdvisorID], [ServiceAdvisorName], [DealerPartyID], [Password], [ReportingDealerPartyID], [ModelVariantCode], [ModelVariantDescription], [SelectionDate], [CampaignId], [PilotCode], [EmailSignator], [EmailSignatorTitle], [EmailContactText], [EmailCompanyDetails], [JLRPrivacyPolicy], [JLRCompanyname], [RockarDealer], [SVOvehicle], [SVODealer], [RepairOrderNumber], [FOBCode], [UnknownLang], [BilingualFlag], [langBilingual], [DearNameBilingual], [EmailSignatorTitleBilingual], [EmailContactTextBilingual], [EmailCompanyDetailsBilingual], [JLRPrivacyPolicyBilingual])
							SELECT [PartyID], [CaseID], [FullModel], [Model], [sType], [CarReg], [Title], [Initial], [Surname], [Fullname], [DearName], [CoName], [Add1], [Add2], [Add3], [Add4], [Add5], [Add6], [Add7], [Add8], [Add9], [CTRY], [EmailAddress], [Dealer], [sno], [ccode], [modelcode], [lang], [manuf], [gender], [qver], [blank], [etype], [reminder], [week], [test], [SampleFlag], [Surveyfile], [ITYPE], [Expired], [EventDate], [VIN], [DealerCode], [GlobalDealerCode], [HomeNumber], [WorkNumber], [MobileNumber], [ModelYear], [CustomerUniqueID], [OwnershipCycle], [SalesEmployeeCode], [SalesEmployeeName], [ServiceEmployeeCode], [ServiceEmployeeName], [ServiceTechnicianID], [ServiceTechnicianName], [ServiceAdvisorID], [ServiceAdvisorName], [DealerPartyID], [Password], [ReportingDealerPartyID], [ModelVariantCode], [ModelVariantDescription], [SelectionDate], [CampaignId], [PilotCode], [EmailSignator], [EmailSignatorTitle], [EmailContactText], [EmailCompanyDetails], [JLRPrivacyPolicy], [JLRCompanyname], [RockarDealer], [SVOvehicle], [SVODealer], [RepairOrderNumber], [FOBCode], [UnknownLang], [BilingualFlag], [langBilingual], [DearNameBilingual], [EmailSignatorTitleBilingual], [EmailContactTextBilingual], [EmailCompanyDetailsBilingual], [JLRPrivacyPolicyBilingual]
							FROM NWB.SelectionOutputsStaging SOS 
							WHERE SOS.Questionnaire = 'Bodyshop'
						END 

						IF @CurrentQuestionnaire = 'BodyshopRussia'		-- V1.2
						BEGIN 
							-- Clear down Upload table prior to population
							DELETE FROM [$(NwbSampleUpload)].SelectionUpload.Bodyshop
							
							-- Populate upload table with new records
							INSERT INTO [$(NwbSampleUpload)].SelectionUpload.Bodyshop ([PartyID], [ID], [FullModel], [Model], [sType], [CarReg], [Title], [Initial], [Surname], [Fullname], [DearName], [CoName], [Add1], [Add2], [Add3], [Add4], [Add5], [Add6], [Add7], [Add8], [Add9], [CTRY], [EmailAddress], [Dealer], [sno], [ccode], [modelcode], [lang], [manuf], [gender], [qver], [blank], [etype], [reminder], [week], [test], [SampleFlag], [BODYSHOPsurveyfile], [ITYPE], [Expired], [EventDate], [VIN], [DealerCode], [GlobalDealerCode], [HomeNumber], [WorkNumber], [MobileNumber], [ModelYear], [CustomerUniqueID], [OwnershipCycle], [SalesEmployeeCode], [SalesEmployeeName], [ServiceEmployeeCode], [ServiceEmployeeName], [ServiceTechnicianID], [ServiceTechnicianName], [ServiceAdvisorID], [ServiceAdvisorName], [DealerPartyID], [Password], [ReportingDealerPartyID], [ModelVariantCode], [ModelVariantDescription], [SelectionDate], [CampaignId], [PilotCode], [EmailSignator], [EmailSignatorTitle], [EmailContactText], [EmailCompanyDetails], [JLRPrivacyPolicy], [JLRCompanyname], [RockarDealer], [SVOvehicle], [SVODealer], [RepairOrderNumber], [FOBCode], [UnknownLang], [BilingualFlag], [langBilingual], [DearNameBilingual], [EmailSignatorTitleBilingual], [EmailContactTextBilingual], [EmailCompanyDetailsBilingual], [JLRPrivacyPolicyBilingual])
							SELECT [PartyID], [CaseID], [FullModel], [Model], [sType], [CarReg], [Title], [Initial], [Surname], [Fullname], [DearName], [CoName], [Add1], [Add2], [Add3], [Add4], [Add5], [Add6], [Add7], [Add8], [Add9], [CTRY], [EmailAddress], [Dealer], [sno], [ccode], [modelcode], [lang], [manuf], [gender], [qver], [blank], [etype], [reminder], [week], [test], [SampleFlag], [Surveyfile], [ITYPE], [Expired], [EventDate], [VIN], [DealerCode], [GlobalDealerCode], [HomeNumber], [WorkNumber], [MobileNumber], [ModelYear], [CustomerUniqueID], [OwnershipCycle], [SalesEmployeeCode], [SalesEmployeeName], [ServiceEmployeeCode], [ServiceEmployeeName], [ServiceTechnicianID], [ServiceTechnicianName], [ServiceAdvisorID], [ServiceAdvisorName], [DealerPartyID], [Password], [ReportingDealerPartyID], [ModelVariantCode], [ModelVariantDescription], [SelectionDate], [CampaignId], [PilotCode], [EmailSignator], [EmailSignatorTitle], [EmailContactText], [EmailCompanyDetails], [JLRPrivacyPolicy], [JLRCompanyname], [RockarDealer], [SVOvehicle], [SVODealer], [RepairOrderNumber], [FOBCode], [UnknownLang], [BilingualFlag], [langBilingual], [DearNameBilingual], [EmailSignatorTitleBilingual], [EmailContactTextBilingual], [EmailCompanyDetailsBilingual], [JLRPrivacyPolicyBilingual]
							FROM NWB.SelectionOutputsStaging SOS 
							WHERE SOS.Questionnaire = 'BodyshopRussia'
						END 

						IF @CurrentQuestionnaire = 'CRC'
						BEGIN 
							-- Clear down Upload table prior to population
							DELETE FROM [$(NwbSampleUpload)].SelectionUpload.CRC
							
							-- Populate upload table with new records
							INSERT INTO [$(NwbSampleUpload)].SelectionUpload.CRC ([PartyID], [ID], [FullModel], [Model], [sType], [CarReg], [Title], [Initial], [Surname], [Fullname], [DearName], [CoName], [Add1], [Add2], [Add3], [Add4], [Add5], [Add6], [Add7], [Add8], [Add9], [CTRY], [EmailAddress], [Dealer], [sno], [ccode], [modelcode], [lang], [manuf], [gender], [qver], [blank], [etype], [reminder], [week], [test], [SampleFlag], [CRCsurveyfile], [ITYPE], [Expired], [EventDate], [VIN], [DealerCode], [GlobalDealerCode], [HomeNumber], [WorkNumber], [MobileNumber], [ModelYear], [CustomerUniqueID], [OwnershipCycle], [SalesEmployeeCode], [SalesEmployeeName], [ServiceEmployeeCode], [ServiceEmployeeName], [DealerPartyID], [Password], [ReportingDealerPartyID], [ModelVariantCode], [ModelVariantDescription], [SelectionDate], [CampaignId], [PilotCode], [EmailSignator], [EmailSignatorTitle], [EmailContactText], [EmailCompanyDetails], [JLRPrivacyPolicy], [JLRCompanyname], [BilingualFlag], [langBilingual], [DearNameBilingual], [EmailSignatorTitleBilingual], [EmailContactTextBilingual], [EmailCompanyDetailsBilingual], [JLRPrivacyPolicyBilingual], [OwnerCode], [CRCCode], [MarketCode], [SampleYear], [VehicleMileage], [VehicleMonthsinService], [RowId], [SRNumber], [EventID], [CDSID], [EngineType], [SVOvehicle])	-- V1.11 V1.13 V1.14 V1.15
							SELECT [PartyID], [CaseID], [FullModel], [Model], [sType], [CarReg], [Title], [Initial], [Surname], [Fullname], [DearName], [CoName], [Add1], [Add2], [Add3], [Add4], [Add5], [Add6], [Add7], [Add8], [Add9], [CTRY], [EmailAddress], [Dealer], [sno], [ccode], [modelcode], [lang], [manuf], [gender], [qver], [blank], [etype], [reminder], [week], [test], [SampleFlag], [Surveyfile], [ITYPE], [Expired], [EventDate], [VIN], [DealerCode], [GlobalDealerCode], [HomeNumber], [WorkNumber], [MobileNumber], [ModelYear], [CustomerUniqueID], [OwnershipCycle], [SalesEmployeeCode], [SalesEmployeeName], [ServiceEmployeeCode], [ServiceEmployeeName], [DealerPartyID], [Password], [ReportingDealerPartyID], [ModelVariantCode], [ModelVariantDescription], [SelectionDate], [CampaignId], [PilotCode], [EmailSignator], [EmailSignatorTitle], [EmailContactText], [EmailCompanyDetails], [JLRPrivacyPolicy], [JLRCompanyname], [BilingualFlag], [langBilingual], [DearNameBilingual], [EmailSignatorTitleBilingual], [EmailContactTextBilingual], [EmailCompanyDetailsBilingual], [JLRPrivacyPolicyBilingual], [OwnerCode], [CRCCode], [MarketCode], [SampleYear], [VehicleMileage], [VehicleMonthsinService], [RowId], [SRNumber], [EventID], [CDSID], [EngineType], [SVOvehicle]												-- V1.11 V1.13 V1.14 V1.15
							FROM NWB.SelectionOutputsStaging SOS 
							WHERE SOS.Questionnaire = 'CRC'
						END 

						IF @CurrentQuestionnaire = 'CRCRussia'		-- V1.1
						BEGIN 
							-- Clear down Upload table prior to population
							DELETE FROM [$(NwbSampleUpload)].SelectionUpload.CRC
							
							-- Populate upload table with new records
							INSERT INTO [$(NwbSampleUpload)].SelectionUpload.CRC ([PartyID], [ID], [FullModel], [Model], [sType], [CarReg], [Title], [Initial], [Surname], [Fullname], [DearName], [CoName], [Add1], [Add2], [Add3], [Add4], [Add5], [Add6], [Add7], [Add8], [Add9], [CTRY], [EmailAddress], [Dealer], [sno], [ccode], [modelcode], [lang], [manuf], [gender], [qver], [blank], [etype], [reminder], [week], [test], [SampleFlag], [CRCsurveyfile], [ITYPE], [Expired], [EventDate], [VIN], [DealerCode], [GlobalDealerCode], [HomeNumber], [WorkNumber], [MobileNumber], [ModelYear], [CustomerUniqueID], [OwnershipCycle], [SalesEmployeeCode], [SalesEmployeeName], [ServiceEmployeeCode], [ServiceEmployeeName], [DealerPartyID], [Password], [ReportingDealerPartyID], [ModelVariantCode], [ModelVariantDescription], [SelectionDate], [CampaignId], [PilotCode], [EmailSignator], [EmailSignatorTitle], [EmailContactText], [EmailCompanyDetails], [JLRPrivacyPolicy], [JLRCompanyname], [BilingualFlag], [langBilingual], [DearNameBilingual], [EmailSignatorTitleBilingual], [EmailContactTextBilingual], [EmailCompanyDetailsBilingual], [JLRPrivacyPolicyBilingual], [OwnerCode], [CRCCode], [MarketCode], [SampleYear], [VehicleMileage], [VehicleMonthsinService], [RowId], [SRNumber], [EventID], [CDSID], [EngineType], [SVOvehicle])	-- V1.11 V1.13 V1.14 V1.15
							SELECT [PartyID], [CaseID], [FullModel], [Model], [sType], [CarReg], [Title], [Initial], [Surname], [Fullname], [DearName], [CoName], [Add1], [Add2], [Add3], [Add4], [Add5], [Add6], [Add7], [Add8], [Add9], [CTRY], [EmailAddress], [Dealer], [sno], [ccode], [modelcode], [lang], [manuf], [gender], [qver], [blank], [etype], [reminder], [week], [test], [SampleFlag], [Surveyfile], [ITYPE], [Expired], [EventDate], [VIN], [DealerCode], [GlobalDealerCode], [HomeNumber], [WorkNumber], [MobileNumber], [ModelYear], [CustomerUniqueID], [OwnershipCycle], [SalesEmployeeCode], [SalesEmployeeName], [ServiceEmployeeCode], [ServiceEmployeeName], [DealerPartyID], [Password], [ReportingDealerPartyID], [ModelVariantCode], [ModelVariantDescription], [SelectionDate], [CampaignId], [PilotCode], [EmailSignator], [EmailSignatorTitle], [EmailContactText], [EmailCompanyDetails], [JLRPrivacyPolicy], [JLRCompanyname], [BilingualFlag], [langBilingual], [DearNameBilingual], [EmailSignatorTitleBilingual], [EmailContactTextBilingual], [EmailCompanyDetailsBilingual], [JLRPrivacyPolicyBilingual], [OwnerCode], [CRCCode], [MarketCode], [SampleYear], [VehicleMileage], [VehicleMonthsinService], [RowId], [SRNumber], [EventID], [CDSID], [EngineType], [SVOvehicle]												-- V1.11 V1.13 V1.14 V1.15
							FROM NWB.SelectionOutputsStaging SOS 
							WHERE SOS.Questionnaire = 'CRCRussia'
						END 

						IF @CurrentQuestionnaire = 'PreOwned'
						BEGIN 
							-- Clear down Upload table prior to population
							DELETE FROM [$(NwbSampleUpload)].SelectionUpload.PreOwned
							
							-- Populate upload table with new records
							INSERT INTO [$(NwbSampleUpload)].SelectionUpload.PreOwned ([PartyID], [ID], [FullModel], [Model], [sType], [CarReg], [Title], [Initial], [Surname], [Fullname], [DearName], [CoName], [Add1], [Add2], [Add3], [Add4], [Add5], [Add6], [Add7], [Add8], [Add9], [CTRY], [EmailAddress], [Dealer], [sno], [ccode], [modelcode], [lang], [manuf], [gender], [qver], [blank], [etype], [reminder], [week], [test], [SampleFlag], [PREOWNEDsurveyfile], [ITYPE], [Expired], [EventDate], [VIN], [DealerCode], [GlobalDealerCode], [HomeNumber], [WorkNumber], [MobileNumber], [ModelYear], [CustomerUniqueID], [OwnershipCycle], [SalesEmployeeCode], [SalesEmployeeName], [ServiceEmployeeCode], [ServiceEmployeeName], [DealerPartyID], [Password], [ReportingDealerPartyID], [ModelVariantCode], [ModelVariantDescription], [SelectionDate], [CampaignId], [EmailSignator], [EmailSignatorTitle], [EmailContactText], [EmailCompanyDetails], [JLRPrivacyPolicy], [JLRCompanyname], [SVOvehicle], [FOBCode], [BilingualFlag], [langBilingual], [DearNameBilingual], [EmailSignatorTitleBilingual], [EmailContactTextBilingual], [EmailCompanyDetailsBilingual], [JLRPrivacyPolicyBilingual], [HotTopicCodes], [Approved], [EventID], [EngineType])	-- V1.11 V1.14
							SELECT [PartyID], [CaseID], [FullModel], [Model], [sType], [CarReg], [Title], [Initial], [Surname], [Fullname], [DearName], [CoName], [Add1], [Add2], [Add3], [Add4], [Add5], [Add6], [Add7], [Add8], [Add9], [CTRY], [EmailAddress], [Dealer], [sno], [ccode], [modelcode], [lang], [manuf], [gender], [qver], [blank], [etype], [reminder], [week], [test], [SampleFlag], [Surveyfile], [ITYPE], [Expired], [EventDate], [VIN], [DealerCode], [GlobalDealerCode], [HomeNumber], [WorkNumber], [MobileNumber], [ModelYear], [CustomerUniqueID], [OwnershipCycle], [SalesEmployeeCode], [SalesEmployeeName], [ServiceEmployeeCode], [ServiceEmployeeName], [DealerPartyID], [Password], [ReportingDealerPartyID], [ModelVariantCode], [ModelVariantDescription], [SelectionDate], [CampaignId], [EmailSignator], [EmailSignatorTitle], [EmailContactText], [EmailCompanyDetails], [JLRPrivacyPolicy], [JLRCompanyname], [SVOvehicle], [FOBCode], [BilingualFlag], [langBilingual], [DearNameBilingual], [EmailSignatorTitleBilingual], [EmailContactTextBilingual], [EmailCompanyDetailsBilingual], [JLRPrivacyPolicyBilingual], [HotTopicCodes], [Approved], [EventID], [EngineType]															-- V1.11 V1.14
							FROM NWB.SelectionOutputsStaging SOS 
							WHERE SOS.Questionnaire = 'PreOwned'
						END 
						
						IF @CurrentQuestionnaire = 'PreOwnedRussia'		-- V1.1
						BEGIN 
							-- Clear down Upload table prior to population
							DELETE FROM [$(NwbSampleUpload)].SelectionUpload.PreOwned
							
							-- Populate upload table with new records
							INSERT INTO [$(NwbSampleUpload)].SelectionUpload.PreOwned ([PartyID], [ID], [FullModel], [Model], [sType], [CarReg], [Title], [Initial], [Surname], [Fullname], [DearName], [CoName], [Add1], [Add2], [Add3], [Add4], [Add5], [Add6], [Add7], [Add8], [Add9], [CTRY], [EmailAddress], [Dealer], [sno], [ccode], [modelcode], [lang], [manuf], [gender], [qver], [blank], [etype], [reminder], [week], [test], [SampleFlag], [PREOWNEDsurveyfile], [ITYPE], [Expired], [EventDate], [VIN], [DealerCode], [GlobalDealerCode], [HomeNumber], [WorkNumber], [MobileNumber], [ModelYear], [CustomerUniqueID], [OwnershipCycle], [SalesEmployeeCode], [SalesEmployeeName], [ServiceEmployeeCode], [ServiceEmployeeName], [DealerPartyID], [Password], [ReportingDealerPartyID], [ModelVariantCode], [ModelVariantDescription], [SelectionDate], [CampaignId], [EmailSignator], [EmailSignatorTitle], [EmailContactText], [EmailCompanyDetails], [JLRPrivacyPolicy], [JLRCompanyname], [SVOvehicle], [FOBCode], [BilingualFlag], [langBilingual], [DearNameBilingual], [EmailSignatorTitleBilingual], [EmailContactTextBilingual], [EmailCompanyDetailsBilingual], [JLRPrivacyPolicyBilingual], [HotTopicCodes], [Approved], [EventID], [EngineType])	-- V1.11 V1.14
							SELECT [PartyID], [CaseID], [FullModel], [Model], [sType], [CarReg], [Title], [Initial], [Surname], [Fullname], [DearName], [CoName], [Add1], [Add2], [Add3], [Add4], [Add5], [Add6], [Add7], [Add8], [Add9], [CTRY], [EmailAddress], [Dealer], [sno], [ccode], [modelcode], [lang], [manuf], [gender], [qver], [blank], [etype], [reminder], [week], [test], [SampleFlag], [Surveyfile], [ITYPE], [Expired], [EventDate], [VIN], [DealerCode], [GlobalDealerCode], [HomeNumber], [WorkNumber], [MobileNumber], [ModelYear], [CustomerUniqueID], [OwnershipCycle], [SalesEmployeeCode], [SalesEmployeeName], [ServiceEmployeeCode], [ServiceEmployeeName], [DealerPartyID], [Password], [ReportingDealerPartyID], [ModelVariantCode], [ModelVariantDescription], [SelectionDate], [CampaignId], [EmailSignator], [EmailSignatorTitle], [EmailContactText], [EmailCompanyDetails], [JLRPrivacyPolicy], [JLRCompanyname], [SVOvehicle], [FOBCode], [BilingualFlag], [langBilingual], [DearNameBilingual], [EmailSignatorTitleBilingual], [EmailContactTextBilingual], [EmailCompanyDetailsBilingual], [JLRPrivacyPolicyBilingual], [HotTopicCodes], [Approved], [EventID], [EngineType]															-- V1.11 V1.14
							FROM NWB.SelectionOutputsStaging SOS 
							WHERE SOS.Questionnaire = 'PreOwnedRussia'
						END 

						IF @CurrentQuestionnaire = 'LostLeads'
						BEGIN 
							-- Clear down Upload table prior to population
							DELETE FROM [$(NwbSampleUpload)].SelectionUpload.LostLeads
							
							-- Populate upload table with new records
							INSERT INTO [$(NwbSampleUpload)].SelectionUpload.LostLeads ([PartyID], [ID], [FullModel], [Model], [sType], [CarReg], [Title], [Initial], [Surname], [Fullname], [DearName], [CoName], [Add1], [Add2], [Add3], [Add4], [Add5], [Add6], [Add7], [Add8], [Add9], [CTRY], [EmailAddress], [Dealer], [sno], [ccode], [modelcode], [lang], [manuf], [gender], [qver], [blank], [etype], [reminder], [week], [test], [SampleFlag], [LOSTLEADSsurveyfile], [ITYPE], [Expired], [EventDate], [VIN], [DealerCode], [GlobalDealerCode], [HomeNumber], [WorkNumber], [MobileNumber], [ModelYear], [CustomerUniqueID], [OwnershipCycle], [SalesEmployeeCode], [SalesEmployeeName], [ServiceEmployeeCode], [ServiceEmployeeName], [DealerPartyID], [Password], [ReportingDealerPartyID], [ModelVariantCode], [ModelVariantDescription], [SelectionDate], [CampaignId], [EmailSignator], [EmailSignatorTitle], [EmailContactText], [EmailCompanyDetails], [JLRPrivacyPolicy], [JLRCompanyname], [SVOvehicle], [FOBCode], [BilingualFlag], [langBilingual], [DearNameBilingual], [EmailSignatorTitleBilingual], [EmailContactTextBilingual], [EmailCompanyDetailsBilingual], [JLRPrivacyPolicyBilingual], [NSCFlag], [JLREventType], [DealerType], [Queue], [EventID], [EngineType])	-- V1.7 V1.11 V1.14
							SELECT [PartyID], [CaseID], [FullModel], [Model], [sType], [CarReg], [Title], [Initial], [Surname], [Fullname], [DearName], [CoName], [Add1], [Add2], [Add3], [Add4], [Add5], [Add6], [Add7], [Add8], [Add9], [CTRY], [EmailAddress], [Dealer], [sno], [ccode], [modelcode], [lang], [manuf], [gender], [qver], [blank], [etype], [reminder], [week], [test], [SampleFlag], [Surveyfile], [ITYPE], [Expired], [EventDate], [VIN], [DealerCode], [GlobalDealerCode], [HomeNumber], [WorkNumber], [MobileNumber], [ModelYear], [CustomerUniqueID], [OwnershipCycle], [SalesEmployeeCode], [SalesEmployeeName], [ServiceEmployeeCode], [ServiceEmployeeName], [DealerPartyID], [Password], [ReportingDealerPartyID], [ModelVariantCode], [ModelVariantDescription], [SelectionDate], [CampaignId], [EmailSignator], [EmailSignatorTitle], [EmailContactText], [EmailCompanyDetails], [JLRPrivacyPolicy], [JLRCompanyname], [SVOvehicle], [FOBCode], [BilingualFlag], [langBilingual], [DearNameBilingual], [EmailSignatorTitleBilingual], [EmailContactTextBilingual], [EmailCompanyDetailsBilingual], [JLRPrivacyPolicyBilingual], [NSCFlag], [JLREventType], [DealerType], [Queue], [EventID], [EngineType]																-- V1.7	V1.11 V1.14
							FROM NWB.SelectionOutputsStaging SOS 
							WHERE SOS.Questionnaire = 'LostLeads'
						END 
								
						IF @CurrentQuestionnaire = 'LostLeadsRussia'	-- V1.1
						BEGIN 
							-- Clear down Upload table prior to population
							DELETE FROM [$(NwbSampleUpload)].SelectionUpload.LostLeads
							
							-- Populate upload table with new records
							INSERT INTO [$(NwbSampleUpload)].SelectionUpload.LostLeads ([PartyID], [ID], [FullModel], [Model], [sType], [CarReg], [Title], [Initial], [Surname], [Fullname], [DearName], [CoName], [Add1], [Add2], [Add3], [Add4], [Add5], [Add6], [Add7], [Add8], [Add9], [CTRY], [EmailAddress], [Dealer], [sno], [ccode], [modelcode], [lang], [manuf], [gender], [qver], [blank], [etype], [reminder], [week], [test], [SampleFlag], [LOSTLEADSsurveyfile], [ITYPE], [Expired], [EventDate], [VIN], [DealerCode], [GlobalDealerCode], [HomeNumber], [WorkNumber], [MobileNumber], [ModelYear], [CustomerUniqueID], [OwnershipCycle], [SalesEmployeeCode], [SalesEmployeeName], [ServiceEmployeeCode], [ServiceEmployeeName], [DealerPartyID], [Password], [ReportingDealerPartyID], [ModelVariantCode], [ModelVariantDescription], [SelectionDate], [CampaignId], [EmailSignator], [EmailSignatorTitle], [EmailContactText], [EmailCompanyDetails], [JLRPrivacyPolicy], [JLRCompanyname], [SVOvehicle], [FOBCode], [BilingualFlag], [langBilingual], [DearNameBilingual], [EmailSignatorTitleBilingual], [EmailContactTextBilingual], [EmailCompanyDetailsBilingual], [JLRPrivacyPolicyBilingual], [NSCFlag], [JLREventType], [DealerType], [Queue], [EventID], [EngineType])	-- V1.7 V1.11 V1.14
							SELECT [PartyID], [CaseID], [FullModel], [Model], [sType], [CarReg], [Title], [Initial], [Surname], [Fullname], [DearName], [CoName], [Add1], [Add2], [Add3], [Add4], [Add5], [Add6], [Add7], [Add8], [Add9], [CTRY], [EmailAddress], [Dealer], [sno], [ccode], [modelcode], [lang], [manuf], [gender], [qver], [blank], [etype], [reminder], [week], [test], [SampleFlag], [Surveyfile], [ITYPE], [Expired], [EventDate], [VIN], [DealerCode], [GlobalDealerCode], [HomeNumber], [WorkNumber], [MobileNumber], [ModelYear], [CustomerUniqueID], [OwnershipCycle], [SalesEmployeeCode], [SalesEmployeeName], [ServiceEmployeeCode], [ServiceEmployeeName], [DealerPartyID], [Password], [ReportingDealerPartyID], [ModelVariantCode], [ModelVariantDescription], [SelectionDate], [CampaignId], [EmailSignator], [EmailSignatorTitle], [EmailContactText], [EmailCompanyDetails], [JLRPrivacyPolicy], [JLRCompanyname], [SVOvehicle], [FOBCode], [BilingualFlag], [langBilingual], [DearNameBilingual], [EmailSignatorTitleBilingual], [EmailContactTextBilingual], [EmailCompanyDetailsBilingual], [JLRPrivacyPolicyBilingual], [NSCFlag], [JLREventType], [DealerType], [Queue], [EventID], [EngineType]																-- V1.7 V1.11 V1.14														
							FROM NWB.SelectionOutputsStaging SOS 
							WHERE SOS.Questionnaire = 'LostLeadsRussia'
						END 
							
						IF @CurrentQuestionnaire = 'LostLeadsUS'
						BEGIN 
							-- Clear down Upload table prior to population
							DELETE FROM [$(NwbSampleUpload)].SelectionUpload.LostLeadsUS
							
							-- Populate upload table with new records
							INSERT INTO [$(NwbSampleUpload)].SelectionUpload.LostLeadsUS ([PartyID], [ID], [FullModel], [Model], [sType], [CarReg], [Title], [Initial], [Surname], [Fullname], [DearName], [CoName], [Add1], [Add2], [Add3], [Add4], [Add5], [Add6], [Add7], [Add8], [Add9], [CTRY], [EmailAddress], [Dealer], [sno], [ccode], [modelcode], [lang], [manuf], [gender], [qver], [blank], [etype], [reminder], [week], [test], [SampleFlag], [LOSTLEADSsurveyfile], [ITYPE], [Expired], [EventDate], [VIN], [DealerCode], [GlobalDealerCode], [HomeNumber], [WorkNumber], [MobileNumber], [ModelYear], [CustomerUniqueID], [OwnershipCycle], [SalesEmployeeCode], [SalesEmployeeName], [ServiceEmployeeCode], [ServiceEmployeeName], [DealerPartyID], [Password], [ReportingDealerPartyID], [ModelVariantCode], [ModelVariantDescription], [SelectionDate], [CampaignId], [EmailSignator], [EmailSignatorTitle], [EmailContactText], [EmailCompanyDetails], [JLRPrivacyPolicy], [JLRCompanyname], [SVOvehicle], [FOBCode], [BilingualFlag], [langBilingual], [DearNameBilingual], [EmailSignatorTitleBilingual], [EmailContactTextBilingual], [EmailCompanyDetailsBilingual], [JLRPrivacyPolicyBilingual], [NSCFlag], [JLREventType], [DealerType])
							SELECT [PartyID], [CaseID], [FullModel], [Model], [sType], [CarReg], [Title], [Initial], [Surname], [Fullname], [DearName], [CoName], [Add1], [Add2], [Add3], [Add4], [Add5], [Add6], [Add7], [Add8], [Add9], [CTRY], [EmailAddress], [Dealer], [sno], [ccode], [modelcode], [lang], [manuf], [gender], [qver], [blank], [etype], [reminder], [week], [test], [SampleFlag], [Surveyfile], [ITYPE], [Expired], [EventDate], [VIN], [DealerCode], [GlobalDealerCode], [HomeNumber], [WorkNumber], [MobileNumber], [ModelYear], [CustomerUniqueID], [OwnershipCycle], [SalesEmployeeCode], [SalesEmployeeName], [ServiceEmployeeCode], [ServiceEmployeeName], [DealerPartyID], [Password], [ReportingDealerPartyID], [ModelVariantCode], [ModelVariantDescription], [SelectionDate], [CampaignId], [EmailSignator], [EmailSignatorTitle], [EmailContactText], [EmailCompanyDetails], [JLRPrivacyPolicy], [JLRCompanyname], [SVOvehicle], [FOBCode], [BilingualFlag], [langBilingual], [DearNameBilingual], [EmailSignatorTitleBilingual], [EmailContactTextBilingual], [EmailCompanyDetailsBilingual], [JLRPrivacyPolicyBilingual], [NSCFlag], [JLREventType], [DealerType]
							FROM NWB.SelectionOutputsStaging SOS 
							WHERE SOS.Questionnaire = 'LostLeadsUS'
						END 
								
						IF @CurrentQuestionnaire = 'CQI'
						BEGIN 
							-- Clear down Upload table prior to population
							DELETE FROM [$(NwbSampleUpload)].SelectionUpload.CQI
							
							-- Populate upload table with new records
							INSERT INTO [$(NwbSampleUpload)].SelectionUpload.CQI (PartyID, ID, FullModel, Model, sType, CarReg, Title, Initial, Surname, Fullname, DearName, CoName, Add1, Add2, Add3, Add4, Add5, Add6, Add7, Add8, Add9, CTRY, EmailAddress, Dealer, sno, ccode, modelcode, lang, manuf, gender, qver, blank, etype, reminder, week, test, SampleFlag, TGWsurveyfile, ITYPE, Expired, EventDate, VIN, DealerCode, GlobalDealerCode, HomeNumber, WorkNumber, MobileNumber, ModelYear, CustomerUniqueID, OwnershipCycle, SalesEmployeeCode, SalesEmployeeName, ServiceEmployeeCode, ServiceEmployeeName, DealerPartyID, Password, ReportingDealerPartyID, ModelVariantCode, ModelVariantDescription, SelectionDate, CampaignId, EmailSignator, EmailSignatorTitle, JLRPrivacyPolicy, JLRCompanyname, EmailContactText, EmailCompanyDetails, ModelSummary, LanguageID, IntervalPeriod, ProductionDate, ProductionMonth, CTRYSold, Plant, WarrantyStartDate, VehicleLine, BodyStyle, Drive, Transmission, Engine, UnknownLang)	
							SELECT PartyID, CaseID, FullModel, Model, sType, CarReg, Title, Initial, Surname, Fullname, DearName, CoName, Add1, Add2, Add3, Add4, Add5, Add6, Add7, Add8, Add9, CTRY, EmailAddress, Dealer, sno, ccode, modelcode, lang, manuf, gender, qver, blank, etype, reminder, week, test, SampleFlag, Surveyfile, ITYPE, Expired, EventDate, VIN, DealerCode, GlobalDealerCode, HomeNumber, WorkNumber, MobileNumber, ModelYear, CustomerUniqueID, OwnershipCycle, SalesEmployeeCode, SalesEmployeeName, ServiceEmployeeCode, ServiceEmployeeName, DealerPartyID, Password, ReportingDealerPartyID, ModelVariantCode, ModelVariantDescription, SelectionDate, CampaignId, EmailSignator, EmailSignatorTitle, JLRPrivacyPolicy, JLRCompanyname, EmailContactText, EmailCompanyDetails, ModelSummary, LanguageID, IntervalPeriod, ProductionDate, ProductionMonth, CTRYSold, Plant, WarrantyStartDate, VehicleLine, BodyStyle, Drive, Transmission, Engine, UnknownLang
							FROM NWB.SelectionOutputsStaging SOS 
							WHERE SOS.Questionnaire = 'CQI'
						END 

						IF @CurrentQuestionnaire = 'CQIRussia'		-- V1.2
						BEGIN 
							-- Clear down Upload table prior to population
							DELETE FROM [$(NwbSampleUpload)].SelectionUpload.CQI
							
							-- Populate upload table with new records
							INSERT INTO [$(NwbSampleUpload)].SelectionUpload.CQI (PartyID, ID, FullModel, Model, sType, CarReg, Title, Initial, Surname, Fullname, DearName, CoName, Add1, Add2, Add3, Add4, Add5, Add6, Add7, Add8, Add9, CTRY, EmailAddress, Dealer, sno, ccode, modelcode, lang, manuf, gender, qver, blank, etype, reminder, week, test, SampleFlag, TGWsurveyfile, ITYPE, Expired, EventDate, VIN, DealerCode, GlobalDealerCode, HomeNumber, WorkNumber, MobileNumber, ModelYear, CustomerUniqueID, OwnershipCycle, SalesEmployeeCode, SalesEmployeeName, ServiceEmployeeCode, ServiceEmployeeName, DealerPartyID, Password, ReportingDealerPartyID, ModelVariantCode, ModelVariantDescription, SelectionDate, CampaignId, EmailSignator, EmailSignatorTitle, JLRPrivacyPolicy, JLRCompanyname, EmailContactText, EmailCompanyDetails, ModelSummary, LanguageID, IntervalPeriod, ProductionDate, ProductionMonth, CTRYSold, Plant, WarrantyStartDate, VehicleLine, BodyStyle, Drive, Transmission, Engine, UnknownLang)
							SELECT PartyID, CaseID, FullModel, Model, sType, CarReg, Title, Initial, Surname, Fullname, DearName, CoName, Add1, Add2, Add3, Add4, Add5, Add6, Add7, Add8, Add9, CTRY, EmailAddress, Dealer, sno, ccode, modelcode, lang, manuf, gender, qver, blank, etype, reminder, week, test, SampleFlag, Surveyfile, ITYPE, Expired, EventDate, VIN, DealerCode, GlobalDealerCode, HomeNumber, WorkNumber, MobileNumber, ModelYear, CustomerUniqueID, OwnershipCycle, SalesEmployeeCode, SalesEmployeeName, ServiceEmployeeCode, ServiceEmployeeName, DealerPartyID, Password, ReportingDealerPartyID, ModelVariantCode, ModelVariantDescription, SelectionDate, CampaignId, EmailSignator, EmailSignatorTitle, JLRPrivacyPolicy, JLRCompanyname, EmailContactText, EmailCompanyDetails, ModelSummary, LanguageID, IntervalPeriod, ProductionDate, ProductionMonth, CTRYSold, Plant, WarrantyStartDate, VehicleLine, BodyStyle, Drive, Transmission, Engine, UnknownLang
							FROM NWB.SelectionOutputsStaging SOS 
							WHERE SOS.Questionnaire = 'CQIRussia'
						END 

						IF @CurrentQuestionnaire = 'Roadside'
						BEGIN 
							-- Clear down Upload table prior to population
							DELETE FROM [$(NwbSampleUpload)].SelectionUpload.Roadside
							
							-- Populate upload table with new records
							INSERT INTO [$(NwbSampleUpload)].SelectionUpload.Roadside ([PartyID], [ID], [FullModel], [Model], [sType], [CarReg], [Title], [Initial], [Surname], [Fullname], [DearName], [CoName], [Add1], [Add2], [Add3], [Add4], [Add5], [Add6], [Add7], [Add8], [Add9], [CTRY], [EmailAddress], [Dealer], [sno], [ccode], [modelcode], [lang], [manuf], [gender], [qver], [blank], [etype], [reminder], [week], [test], [SampleFlag], [ROADSIDEsurveyfile], [ITYPE], [Expired], [VIN], [HomeNumber], [WorkNumber], [MobileNumber], [Password], [SelectionDate], [EmailSignator], [EmailSignatorTitle], [EmailContactText], [EmailCompanyDetails], [JLRPrivacyPolicy], [JLRCompanyname], [BilingualFlag], [langBilingual], [DearNameBilingual], [EmailSignatorTitleBilingual], [EmailContactTextBilingual], [EmailCompanyDetailsBilingual], [JLRPrivacyPolicyBilingual], [BreakdownDate], [BreakdownCountry], [BreakdownCountryID], [BreakdownCaseId], [CarHireStartDate], [ReasonForHire], [HireGroupBranch], [CarHireTicketNumber], [HireJobNumber], [RepairingDealer], [DataSource], [ReplacementVehicleMake], [ReplacementVehicleModel], [CarHireStartTime], [RepairingDealerCountry], [RoadsideAssistanceProvider], [BreakdownAttendingResource], [CarHireProvider], [VehicleOriginCountry], [EventID], [EngineType], [SVOvehicle])	-- V1.11 V1.14 V1.15
							SELECT [PartyID], [CaseID], [FullModel], [Model], [sType], [CarReg], [Title], [Initial], [Surname], [Fullname], [DearName], [CoName], [Add1], [Add2], [Add3], [Add4], [Add5], [Add6], [Add7], [Add8], [Add9], [CTRY], [EmailAddress], [Dealer], [sno], [ccode], [modelcode], [lang], [manuf], [gender], [qver], [blank], [etype], [reminder], [week], [test], [SampleFlag], [surveyfile], [ITYPE], [Expired], [VIN], [HomeNumber], [WorkNumber], [MobileNumber], [Password], [SelectionDate], [EmailSignator], [EmailSignatorTitle], [EmailContactText], [EmailCompanyDetails], [JLRPrivacyPolicy], [JLRCompanyname], [BilingualFlag], [langBilingual], [DearNameBilingual], [EmailSignatorTitleBilingual], [EmailContactTextBilingual], [EmailCompanyDetailsBilingual], [JLRPrivacyPolicyBilingual], [BreakdownDate], [BreakdownCountry], [BreakdownCountryID], [BreakdownCaseId], [CarHireStartDate], [ReasonForHire], [HireGroupBranch], [CarHireTicketNumber], [HireJobNumber], [RepairingDealer], [DataSource], [ReplacementVehicleMake], [ReplacementVehicleModel], [CarHireStartTime], [RepairingDealerCountry], [RoadsideAssistanceProvider], [BreakdownAttendingResource], [CarHireProvider], [VehicleOriginCountry], [EventID], [EngineType], [SVOvehicle]															-- V1.11 V1.14 V1.15
							FROM NWB.SelectionOutputsStaging SOS 
							WHERE SOS.Questionnaire = 'Roadside'
						END 

						IF @CurrentQuestionnaire = 'RoadsideRussia'	-- V1.1
						BEGIN 
							-- Clear down Upload table prior to population
							DELETE FROM [$(NwbSampleUpload)].SelectionUpload.Roadside
							
							-- Populate upload table with new records
							INSERT INTO [$(NwbSampleUpload)].SelectionUpload.Roadside ([PartyID], [ID], [FullModel], [Model], [sType], [CarReg], [Title], [Initial], [Surname], [Fullname], [DearName], [CoName], [Add1], [Add2], [Add3], [Add4], [Add5], [Add6], [Add7], [Add8], [Add9], [CTRY], [EmailAddress], [Dealer], [sno], [ccode], [modelcode], [lang], [manuf], [gender], [qver], [blank], [etype], [reminder], [week], [test], [SampleFlag], [ROADSIDEsurveyfile], [ITYPE], [Expired], [VIN], [HomeNumber], [WorkNumber], [MobileNumber], [Password], [SelectionDate], [EmailSignator], [EmailSignatorTitle], [EmailContactText], [EmailCompanyDetails], [JLRPrivacyPolicy], [JLRCompanyname], [BilingualFlag], [langBilingual], [DearNameBilingual], [EmailSignatorTitleBilingual], [EmailContactTextBilingual], [EmailCompanyDetailsBilingual], [JLRPrivacyPolicyBilingual], [BreakdownDate], [BreakdownCountry], [BreakdownCountryID], [BreakdownCaseId], [CarHireStartDate], [ReasonForHire], [HireGroupBranch], [CarHireTicketNumber], [HireJobNumber], [RepairingDealer], [DataSource], [ReplacementVehicleMake], [ReplacementVehicleModel], [CarHireStartTime], [RepairingDealerCountry], [RoadsideAssistanceProvider], [BreakdownAttendingResource], [CarHireProvider], [VehicleOriginCountry], [EventID], [EngineType], [SVOvehicle])	-- V1.11 V1.14 V1.15
							SELECT [PartyID], [CaseID], [FullModel], [Model], [sType], [CarReg], [Title], [Initial], [Surname], [Fullname], [DearName], [CoName], [Add1], [Add2], [Add3], [Add4], [Add5], [Add6], [Add7], [Add8], [Add9], [CTRY], [EmailAddress], [Dealer], [sno], [ccode], [modelcode], [lang], [manuf], [gender], [qver], [blank], [etype], [reminder], [week], [test], [SampleFlag], [surveyfile], [ITYPE], [Expired], [VIN], [HomeNumber], [WorkNumber], [MobileNumber], [Password], [SelectionDate], [EmailSignator], [EmailSignatorTitle], [EmailContactText], [EmailCompanyDetails], [JLRPrivacyPolicy], [JLRCompanyname], [BilingualFlag], [langBilingual], [DearNameBilingual], [EmailSignatorTitleBilingual], [EmailContactTextBilingual], [EmailCompanyDetailsBilingual], [JLRPrivacyPolicyBilingual], [BreakdownDate], [BreakdownCountry], [BreakdownCountryID], [BreakdownCaseId], [CarHireStartDate], [ReasonForHire], [HireGroupBranch], [CarHireTicketNumber], [HireJobNumber], [RepairingDealer], [DataSource], [ReplacementVehicleMake], [ReplacementVehicleModel], [CarHireStartTime], [RepairingDealerCountry], [RoadsideAssistanceProvider], [BreakdownAttendingResource], [CarHireProvider], [VehicleOriginCountry], [EventID], [EngineType], [SVOvehicle]															-- V1.11 V1.14 V1.15
							FROM NWB.SelectionOutputsStaging SOS 
							WHERE SOS.Questionnaire = 'RoadsideRussia'
						END 

						IF @CurrentQuestionnaire = 'IAssistance'
						BEGIN 
							-- Clear down Upload table prior to population
							DELETE FROM [$(NwbSampleUpload)].SelectionUpload.IAssistance
							
							-- Populate upload table with new records
							INSERT INTO [$(NwbSampleUpload)].SelectionUpload.IAssistance ([PartyID], [ID], [FullModel], [Model], [sType], [CarReg], [Title], [Initial], [Surname], [Fullname], [DearName], [CoName], [Add1], [Add2], [Add3], [Add4], [Add5], [Add6], [Add7], [Add8], [Add9], [CTRY], [EmailAddress], [Dealer], [sno], [ccode], [modelcode], [lang], [manuf], [gender], [qver], [blank], [etype], [reminder], [week], [test], [SampleFlag], [IAssistanceSurveyFile], [ITYPE], [Expired], [EventDate], [VIN], [HomeNumber], [WorkNumber], [MobileNumber], [Password], [SelectionDate], [EmailSignator], [EmailSignatorTitle], [EmailContactText], [EmailCompanyDetails], [JLRPrivacyPolicy], [JLRCompanyname], [BilingualFlag], [langBilingual], [DearNameBilingual], [EmailSignatorTitleBilingual], [EmailContactTextBilingual], [EmailCompanyDetailsBilingual], [JLRPrivacyPolicyBilingual], [IAssistanceProvider], [IAssistanceCallID], [IAssistanceCallStartDate], [IAssistanceCallCloseDate], [IAssistanceHelpdeskAdvisorName], [IAssistanceHelpdeskAdvisorID], [IAssistanceCallMethod], [ModelSummary])
							SELECT [PartyID], [CaseID], [FullModel], [Model], [sType], [CarReg], [Title], [Initial], [Surname], [Fullname], [DearName], [CoName], [Add1], [Add2], [Add3], [Add4], [Add5], [Add6], [Add7], [Add8], [Add9], [CTRY], [EmailAddress], [Dealer], [sno], [ccode], [modelcode], [lang], [manuf], [gender], [qver], [blank], [etype], [reminder], [week], [test], [SampleFlag], [SurveyFile], [ITYPE], [Expired], [EventDate], [VIN], [HomeNumber], [WorkNumber], [MobileNumber], [Password], [SelectionDate], [EmailSignator], [EmailSignatorTitle], [EmailContactText], [EmailCompanyDetails], [JLRPrivacyPolicy], [JLRCompanyname], [BilingualFlag], [langBilingual], [DearNameBilingual], [EmailSignatorTitleBilingual], [EmailContactTextBilingual], [EmailCompanyDetailsBilingual], [JLRPrivacyPolicyBilingual], [IAssistanceProvider], [IAssistanceCallID], [IAssistanceCallStartDate], [IAssistanceCallCloseDate], [IAssistanceHelpdeskAdvisorName], [IAssistanceHelpdeskAdvisorID], [IAssistanceCallMethod], [ModelSummary]
							FROM NWB.SelectionOutputsStaging SOS 
							WHERE SOS.Questionnaire = 'IAssistance'
						END 

						IF @CurrentQuestionnaire = 'IAssistanceRussia'		-- V1.2
						BEGIN 
							-- Clear down Upload table prior to population
							DELETE FROM [$(NwbSampleUpload)].SelectionUpload.IAssistance
							
							-- Populate upload table with new records
							INSERT INTO [$(NwbSampleUpload)].SelectionUpload.IAssistance ([PartyID], [ID], [FullModel], [Model], [sType], [CarReg], [Title], [Initial], [Surname], [Fullname], [DearName], [CoName], [Add1], [Add2], [Add3], [Add4], [Add5], [Add6], [Add7], [Add8], [Add9], [CTRY], [EmailAddress], [Dealer], [sno], [ccode], [modelcode], [lang], [manuf], [gender], [qver], [blank], [etype], [reminder], [week], [test], [SampleFlag], [IAssistanceSurveyFile], [ITYPE], [Expired], [EventDate], [VIN], [HomeNumber], [WorkNumber], [MobileNumber], [Password], [SelectionDate], [EmailSignator], [EmailSignatorTitle], [EmailContactText], [EmailCompanyDetails], [JLRPrivacyPolicy], [JLRCompanyname], [BilingualFlag], [langBilingual], [DearNameBilingual], [EmailSignatorTitleBilingual], [EmailContactTextBilingual], [EmailCompanyDetailsBilingual], [JLRPrivacyPolicyBilingual], [IAssistanceProvider], [IAssistanceCallID], [IAssistanceCallStartDate], [IAssistanceCallCloseDate], [IAssistanceHelpdeskAdvisorName], [IAssistanceHelpdeskAdvisorID], [IAssistanceCallMethod], [ModelSummary])
							SELECT [PartyID], [CaseID], [FullModel], [Model], [sType], [CarReg], [Title], [Initial], [Surname], [Fullname], [DearName], [CoName], [Add1], [Add2], [Add3], [Add4], [Add5], [Add6], [Add7], [Add8], [Add9], [CTRY], [EmailAddress], [Dealer], [sno], [ccode], [modelcode], [lang], [manuf], [gender], [qver], [blank], [etype], [reminder], [week], [test], [SampleFlag], [SurveyFile], [ITYPE], [Expired], [EventDate], [VIN], [HomeNumber], [WorkNumber], [MobileNumber], [Password], [SelectionDate], [EmailSignator], [EmailSignatorTitle], [EmailContactText], [EmailCompanyDetails], [JLRPrivacyPolicy], [JLRCompanyname], [BilingualFlag], [langBilingual], [DearNameBilingual], [EmailSignatorTitleBilingual], [EmailContactTextBilingual], [EmailCompanyDetailsBilingual], [JLRPrivacyPolicyBilingual], [IAssistanceProvider], [IAssistanceCallID], [IAssistanceCallStartDate], [IAssistanceCallCloseDate], [IAssistanceHelpdeskAdvisorName], [IAssistanceHelpdeskAdvisorID], [IAssistanceCallMethod], [ModelSummary]
							FROM NWB.SelectionOutputsStaging SOS 
							WHERE SOS.Questionnaire = 'IAssistanceRussia'
						END 

						IF @CurrentQuestionnaire = 'CATISales'											-- V1.3
						BEGIN 
							-- Clear down Upload table prior to population
							DELETE FROM [$(NwbSampleUpload)].SelectionUpload.CATISales
							
							-- Populate upload table with new records
							INSERT INTO [$(NwbSampleUpload)].SelectionUpload.CATISales (PartyID, ID, FullModel, Model, sType, CarReg, Title, Initial, Surname, Fullname, DearName, CoName, Add1, Add2, Add3, Add4, Add5, Add6, Add7, Add8, Add9, CTRY, EmailAddress, Dealer, sno, ccode, modelcode, lang, manuf, gender, qver, blank, etype, reminder, week, test, SampleFlag, NewSurveyFile, ITYPE, Expired, EventDate, VIN, DealerCode, GlobalDealerCode, HomeNumber, WorkNumber, MobileNumber, ModelYear, CustomerUniqueID, OwnershipCycle, SalesEmployeeCode, SalesEmployeeName, ServiceEmployeeCode, ServiceEmployeeName, DealerPartyID, Password, ReportingDealerPartyID, ModelVariantCode, ModelVariantDescription, SVOvehicle, FOBCode, SurveyURL, CATIType, Filedate, Queue, AssignedMode, RequiresManualDial, CallRecordingsCount, TimeZone, CallOutcome, PhoneNumber, PhoneSource, Language, ExpirationTime, HomePhoneNumber, WorkPhoneNumber, MobilePhoneNumber, SampleFileName)
							SELECT PartyID, CaseID, FullModel, Model, sType, CarReg, Title, Initial, Surname, Fullname, DearName, CoName, Add1, Add2, Add3, Add4, Add5, Add6, Add7, Add8, Add9, CTRY, EmailAddress, Dealer, sno, ccode, modelcode, lang, manuf, gender, qver, blank, etype, reminder, week, test, SampleFlag, SurveyFile, ITYPE, Expired, EventDate, VIN, DealerCode, GlobalDealerCode, HomeNumber, WorkNumber, MobileNumber, ModelYear, CustomerUniqueID, OwnershipCycle, SalesEmployeeCode, SalesEmployeeName, ServiceEmployeeCode, ServiceEmployeeName, DealerPartyID, Password, ReportingDealerPartyID, ModelVariantCode, ModelVariantDescription, SVOvehicle, FOBCode, SurveyURL, CATIType, Filedate, Queue, AssignedMode, RequiresManualDial, CallRecordingsCount, TimeZone, CallOutcome, PhoneNumber, PhoneSource, Language, ExpirationTime, HomePhoneNumber, WorkPhoneNumber, MobilePhoneNumber, SampleFileName
							FROM NWB.SelectionOutputsStaging SOS 
							WHERE SOS.Questionnaire = 'CATISales'
						END 

						IF @CurrentQuestionnaire = 'CATIService'										-- V1.3
						BEGIN 
							-- Clear down Upload table prior to population
							DELETE FROM [$(NwbSampleUpload)].SelectionUpload.CATIService
							
							-- Populate upload table with new records
							INSERT INTO [$(NwbSampleUpload)].SelectionUpload.CATIService (PartyID, ID, FullModel, Model, sType, CarReg, Title, Initial, Surname, Fullname, DearName, CoName, Add1, Add2, Add3, Add4, Add5, Add6, Add7, Add8, Add9, CTRY, EmailAddress, Dealer, sno, ccode, modelcode, lang, manuf, gender, qver, blank, etype, reminder, week, test, SampleFlag, NewSurveyFile, ITYPE, Expired, EventDate, VIN, DealerCode, GlobalDealerCode, HomeNumber, WorkNumber, MobileNumber, ModelYear, CustomerUniqueID, OwnershipCycle, SalesEmployeeCode, SalesEmployeeName, ServiceEmployeeCode, ServiceEmployeeName, DealerPartyID, Password, ReportingDealerPartyID, ModelVariantCode, ModelVariantDescription, SVOvehicle, FOBCode, SurveyURL, CATIType, Filedate, Queue, AssignedMode, RequiresManualDial, CallRecordingsCount, TimeZone, CallOutcome, PhoneNumber, PhoneSource, Language, ExpirationTime, HomePhoneNumber, WorkPhoneNumber, MobilePhoneNumber, SampleFileName, ServiceEventType)	-- V1.8
							SELECT PartyID, CaseID, FullModel, Model, sType, CarReg, Title, Initial, Surname, Fullname, DearName, CoName, Add1, Add2, Add3, Add4, Add5, Add6, Add7, Add8, Add9, CTRY, EmailAddress, Dealer, sno, ccode, modelcode, lang, manuf, gender, qver, blank, etype, reminder, week, test, SampleFlag, SurveyFile, ITYPE, Expired, EventDate, VIN, DealerCode, GlobalDealerCode, HomeNumber, WorkNumber, MobileNumber, ModelYear, CustomerUniqueID, OwnershipCycle, SalesEmployeeCode, SalesEmployeeName, ServiceEmployeeCode, ServiceEmployeeName, DealerPartyID, Password, ReportingDealerPartyID, ModelVariantCode, ModelVariantDescription, SVOvehicle, FOBCode, SurveyURL, CATIType, Filedate, Queue, AssignedMode, RequiresManualDial, CallRecordingsCount, TimeZone, CallOutcome, PhoneNumber, PhoneSource, Language, ExpirationTime, HomePhoneNumber, WorkPhoneNumber, MobilePhoneNumber, SampleFileName, ServiceEventType	-- V1.8
							FROM NWB.SelectionOutputsStaging SOS 
							WHERE SOS.Questionnaire = 'CATIService'
						END 

						IF @CurrentQuestionnaire = 'CRCGeneralEnquiry'			-- V1.12
						BEGIN 
							-- Clear down Upload table prior to population
							DELETE FROM [$(NwbSampleUpload)].SelectionUpload.CRCGeneralEnquiry
							
							-- Populate upload table with new records
							INSERT INTO [$(NwbSampleUpload)].SelectionUpload.CRCGeneralEnquiry ([PartyID], [ID], [FullModel], [Model], [sType], [CarReg], [Title], [Initial], [Surname], [Fullname], [DearName], [CoName], [Add1], [Add2], [Add3], [Add4], [Add5], [Add6], [Add7], [Add8], [Add9], [CTRY], [EmailAddress], [Dealer], [sno], [ccode], [modelcode], [lang], [manuf], [gender], [qver], [blank], [etype], [reminder], [week], [test], [SampleFlag], [CRCsurveyfile], [ITYPE], [Expired], [EventDate], [VIN], [DealerCode], [GlobalDealerCode], [HomeNumber], [WorkNumber], [MobileNumber], [ModelYear], [CustomerUniqueID], [OwnershipCycle], [SalesEmployeeCode], [SalesEmployeeName], [ServiceEmployeeCode], [ServiceEmployeeName], [DealerPartyID], [Password], [ReportingDealerPartyID], [ModelVariantCode], [ModelVariantDescription], [SelectionDate], [CampaignId], [PilotCode], [EmailSignator], [EmailSignatorTitle], [EmailContactText], [EmailCompanyDetails], [JLRPrivacyPolicy], [JLRCompanyname], [BilingualFlag], [langBilingual], [DearNameBilingual], [EmailSignatorTitleBilingual], [EmailContactTextBilingual], [EmailCompanyDetailsBilingual], [JLRPrivacyPolicyBilingual], [OwnerCode], [CRCCode], [MarketCode], [SampleYear], [VehicleMileage], [VehicleMonthsinService], [RowId], [SRNumber], [EventID], [CDSID], [EngineType], [SVOvehicle])	-- V1.11 V1.13 V1.14 V1.15
							SELECT [PartyID], [CaseID], [FullModel], [Model], [sType], [CarReg], [Title], [Initial], [Surname], [Fullname], [DearName], [CoName], [Add1], [Add2], [Add3], [Add4], [Add5], [Add6], [Add7], [Add8], [Add9], [CTRY], [EmailAddress], [Dealer], [sno], [ccode], [modelcode], [lang], [manuf], [gender], [qver], [blank], [etype], [reminder], [week], [test], [SampleFlag], [Surveyfile], [ITYPE], [Expired], [EventDate], [VIN], [DealerCode], [GlobalDealerCode], [HomeNumber], [WorkNumber], [MobileNumber], [ModelYear], [CustomerUniqueID], [OwnershipCycle], [SalesEmployeeCode], [SalesEmployeeName], [ServiceEmployeeCode], [ServiceEmployeeName], [DealerPartyID], [Password], [ReportingDealerPartyID], [ModelVariantCode], [ModelVariantDescription], [SelectionDate], [CampaignId], [PilotCode], [EmailSignator], [EmailSignatorTitle], [EmailContactText], [EmailCompanyDetails], [JLRPrivacyPolicy], [JLRCompanyname], [BilingualFlag], [langBilingual], [DearNameBilingual], [EmailSignatorTitleBilingual], [EmailContactTextBilingual], [EmailCompanyDetailsBilingual], [JLRPrivacyPolicyBilingual], [OwnerCode], [CRCCode], [MarketCode], [SampleYear], [VehicleMileage], [VehicleMonthsinService], [RowId], [SRNumber], [EventID], [CDSID], [EngineType], [SVOvehicle]																-- V1.11 V1.13 V1.14 V1.15
							FROM NWB.SelectionOutputsStaging SOS 
							WHERE SOS.Questionnaire = 'CRCGeneralEnquiry'
						END 

						IF @CurrentQuestionnaire = 'CRCGeneralEnquiryRussia'	-- V1.12
						BEGIN 
							-- Clear down Upload table prior to population
							DELETE FROM [$(NwbSampleUpload)].SelectionUpload.CRCGeneralEnquiry
							
							-- Populate upload table with new records
							INSERT INTO [$(NwbSampleUpload)].SelectionUpload.CRCGeneralEnquiry ([PartyID], [ID], [FullModel], [Model], [sType], [CarReg], [Title], [Initial], [Surname], [Fullname], [DearName], [CoName], [Add1], [Add2], [Add3], [Add4], [Add5], [Add6], [Add7], [Add8], [Add9], [CTRY], [EmailAddress], [Dealer], [sno], [ccode], [modelcode], [lang], [manuf], [gender], [qver], [blank], [etype], [reminder], [week], [test], [SampleFlag], [CRCsurveyfile], [ITYPE], [Expired], [EventDate], [VIN], [DealerCode], [GlobalDealerCode], [HomeNumber], [WorkNumber], [MobileNumber], [ModelYear], [CustomerUniqueID], [OwnershipCycle], [SalesEmployeeCode], [SalesEmployeeName], [ServiceEmployeeCode], [ServiceEmployeeName], [DealerPartyID], [Password], [ReportingDealerPartyID], [ModelVariantCode], [ModelVariantDescription], [SelectionDate], [CampaignId], [PilotCode], [EmailSignator], [EmailSignatorTitle], [EmailContactText], [EmailCompanyDetails], [JLRPrivacyPolicy], [JLRCompanyname], [BilingualFlag], [langBilingual], [DearNameBilingual], [EmailSignatorTitleBilingual], [EmailContactTextBilingual], [EmailCompanyDetailsBilingual], [JLRPrivacyPolicyBilingual], [OwnerCode], [CRCCode], [MarketCode], [SampleYear], [VehicleMileage], [VehicleMonthsinService], [RowId], [SRNumber], [EventID], [CDSID], [EngineType], [SVOvehicle])	-- V1.11 V1.13 V1.14 V1.15
							SELECT [PartyID], [CaseID], [FullModel], [Model], [sType], [CarReg], [Title], [Initial], [Surname], [Fullname], [DearName], [CoName], [Add1], [Add2], [Add3], [Add4], [Add5], [Add6], [Add7], [Add8], [Add9], [CTRY], [EmailAddress], [Dealer], [sno], [ccode], [modelcode], [lang], [manuf], [gender], [qver], [blank], [etype], [reminder], [week], [test], [SampleFlag], [Surveyfile], [ITYPE], [Expired], [EventDate], [VIN], [DealerCode], [GlobalDealerCode], [HomeNumber], [WorkNumber], [MobileNumber], [ModelYear], [CustomerUniqueID], [OwnershipCycle], [SalesEmployeeCode], [SalesEmployeeName], [ServiceEmployeeCode], [ServiceEmployeeName], [DealerPartyID], [Password], [ReportingDealerPartyID], [ModelVariantCode], [ModelVariantDescription], [SelectionDate], [CampaignId], [PilotCode], [EmailSignator], [EmailSignatorTitle], [EmailContactText], [EmailCompanyDetails], [JLRPrivacyPolicy], [JLRCompanyname], [BilingualFlag], [langBilingual], [DearNameBilingual], [EmailSignatorTitleBilingual], [EmailContactTextBilingual], [EmailCompanyDetailsBilingual], [JLRPrivacyPolicyBilingual], [OwnerCode], [CRCCode], [MarketCode], [SampleYear], [VehicleMileage], [VehicleMonthsinService], [RowId], [SRNumber], [EventID], [CDSID], [EngineType], [SVOvehicle]																-- V1.11 V1.13 V1.14 V1.15
							FROM NWB.SelectionOutputsStaging SOS 
							WHERE SOS.Questionnaire = 'CRCGeneralEnquiryRussia'
						END 


						-- Create NWB Upload Request
						EXEC [$(NwbSampleUpload)].dbo.NwbSampleUploadRequest_sp_Set @p_projectId, @p_connectionString, @p_tableName, @p_hubName, @p_targetServerName, @p_reRandomizeSortId

			
						-- Update the NWB.SelectionOutputStaging records with the request details
						SELECT @NwbSampleUploadRequestKey = UR.pkNwbSampleUploadRequestKey, 
							@NwbCreatedTimestamp = UR.CreatedTimestamp 
						FROM [$(NwbSampleUpload)].dbo.NwbSampleUpload_ut_Request UR
						WHERE UR.ProjectId = @p_projectId
						  AND UR.InputParameter = @p_tableName
						  AND UR.fkSampleUploadStatusKey IS NULL
						  
						UPDATE NWB.SelectionOutputsStaging 
						SET NwbSampleUploadRequestKey = @NwbSampleUploadRequestKey,
							NwbCreatedTimestamp = @NwbCreatedTimestamp
						WHERE Questionnaire = @CurrentQuestionnaire
			
				END -- of failed or pending request check
						
				-- Increment the loop counter
				SET @Counter += 1

		END -- of loop


		-------------------------------------------------------------------------------------------------------------------------------
		-- Move all "transferred" records to Audit  i.e. all the records we have added to the NWB load tables and created a request for.
		-------------------------------------------------------------------------------------------------------------------------------

		INSERT INTO [$(AuditDB)].Audit.NWB_SelectionOutputsStaging (ID, AuditID, AuditItemID, PhysicalRowID, Questionnaire, NwbSampleUploadRequestKey, NwbCreatedTimestamp, PartyID, CaseID, FullModel, Model, sType, CarReg, Title, Initial, Surname, Fullname, DearName, CoName, Add1, Add2, Add3, Add4, Add5, Add6, Add7, Add8, Add9, CTRY, EmailAddress, Dealer, sno, ccode, modelcode, lang, manuf, gender, qver, blank, etype, reminder, week, test, SampleFlag, SurveyFile, ITYPE, Expired, EventDate, VIN, DealerCode, GlobalDealerCode, HomeNumber, WorkNumber, MobileNumber, ModelYear, CustomerUniqueID, OwnershipCycle, SalesEmployeeCode, SalesEmployeeName, ServiceEmployeeCode, ServiceEmployeeName, CRMSalesmanCode, CRMSalesmanName, CRMSalesmanCodeBlank, CRMSalesmanNameBlank, ServiceTechnicianID, ServiceTechnicianName, ServiceAdvisorID, ServiceAdvisorName, DealerPartyID, Password, ReportingDealerPartyID, ModelVariantCode, ModelVariantDescription, SelectionDate, CampaignId, PilotCode, EmailSignator, EmailSignatorTitle, EmailContactText, EmailCompanyDetails, JLRPrivacyPolicy, JLRCompanyname, RockarDealer, SVOvehicle, SVODealer, VistaContractOrderNumber, RepairOrderNumber, DealNo, FOBCode, UnknownLang, BilingualFlag, langBilingual, DearNameBilingual, EmailSignatorTitleBilingual, EmailContactTextBilingual, EmailCompanyDetailsBilingual, JLRPrivacyPolicyBilingual, HotTopicCodes, NSCFlag, JLREventType, Approved, OwnerCode, CRCCode, MarketCode, SampleYear, VehicleMileage, VehicleMonthsinService, RowId, SRNumber, IAssistanceProvider, IAssistanceCallID, IAssistanceCallStartDate, IAssistanceCallCloseDate, IAssistanceHelpdeskAdvisorName, IAssistanceHelpdeskAdvisorID, IAssistanceCallMethod, ModelSummary, BreakdownDate, BreakdownCountry, BreakdownCountryID, BreakdownCaseId, CarHireStartDate, ReasonForHire, HireGroupBranch, CarHireTicketNumber, HireJobNumber, RepairingDealer, DataSource, ReplacementVehicleMake, ReplacementVehicleModel, CarHireStartTime, RepairingDealerCountry, RoadsideAssistanceProvider, BreakdownAttendingResource, CarHireProvider, VehicleOriginCountry,
																	LanguageID, IntervalPeriod, ProductionDate, ProductionMonth, CTRYSold, Plant, WarrantyStartDate, VehicleLine, BodyStyle, Drive, Transmission, Engine, SurveyURL, CATIType, Filedate, Queue, AssignedMode, RequiresManualDial, CallRecordingsCount, TimeZone, CallOutcome, PhoneNumber, PhoneSource, Language, ExpirationTime, HomePhoneNumber, WorkPhoneNumber, MobilePhoneNumber, SampleFileName, DealerType, ServiceEventType, EventID, CDSID, EngineType)   -- V1.3 V1.6 V1.7 V1.8 V1.11 V1.13
		SELECT  ID, AuditID, AuditItemID, PhysicalRowID, Questionnaire, NwbSampleUploadRequestKey, NwbCreatedTimestamp, PartyID, CaseID, FullModel, Model, sType, CarReg, Title, Initial, Surname, Fullname, DearName, CoName, Add1, Add2, Add3, Add4, Add5, Add6, Add7, Add8, Add9, CTRY, EmailAddress, Dealer, sno, ccode, modelcode, lang, manuf, gender, qver, blank, etype, reminder, week, test, SampleFlag, SurveyFile, ITYPE, Expired, EventDate, VIN, DealerCode, GlobalDealerCode, HomeNumber, WorkNumber, MobileNumber, ModelYear, CustomerUniqueID, OwnershipCycle, SalesEmployeeCode, SalesEmployeeName, ServiceEmployeeCode, ServiceEmployeeName, CRMSalesmanCode, CRMSalesmanName, CRMSalesmanCodeBlank, CRMSalesmanNameBlank, ServiceTechnicianID, ServiceTechnicianName, ServiceAdvisorID, ServiceAdvisorName, DealerPartyID, Password, ReportingDealerPartyID, ModelVariantCode, ModelVariantDescription, SelectionDate, CampaignId, PilotCode, EmailSignator, EmailSignatorTitle, EmailContactText, EmailCompanyDetails, JLRPrivacyPolicy, JLRCompanyname, RockarDealer, SVOvehicle, SVODealer, VistaContractOrderNumber, RepairOrderNumber, DealNo, FOBCode, UnknownLang, BilingualFlag, langBilingual, DearNameBilingual, EmailSignatorTitleBilingual, EmailContactTextBilingual, EmailCompanyDetailsBilingual, JLRPrivacyPolicyBilingual, HotTopicCodes, NSCFlag, JLREventType, Approved, OwnerCode, CRCCode, MarketCode, SampleYear, VehicleMileage, VehicleMonthsinService, RowId, SRNumber, IAssistanceProvider, IAssistanceCallID, IAssistanceCallStartDate, IAssistanceCallCloseDate, IAssistanceHelpdeskAdvisorName, IAssistanceHelpdeskAdvisorID, IAssistanceCallMethod, ModelSummary, BreakdownDate, BreakdownCountry, BreakdownCountryID, BreakdownCaseId, CarHireStartDate, ReasonForHire, HireGroupBranch, CarHireTicketNumber, HireJobNumber, RepairingDealer, DataSource, ReplacementVehicleMake, ReplacementVehicleModel, CarHireStartTime, RepairingDealerCountry, RoadsideAssistanceProvider, BreakdownAttendingResource, CarHireProvider, VehicleOriginCountry,
				LanguageID, IntervalPeriod, ProductionDate, ProductionMonth, CTRYSold, Plant, WarrantyStartDate, VehicleLine, BodyStyle, Drive, Transmission, Engine, SurveyURL, CATIType, Filedate, Queue, AssignedMode, RequiresManualDial, CallRecordingsCount, TimeZone, CallOutcome, PhoneNumber, PhoneSource, Language, ExpirationTime, HomePhoneNumber, WorkPhoneNumber, MobilePhoneNumber, SampleFileName, DealerType, ServiceEventType, EventID, CDSID, EngineType   -- V1.3 V1.6 V1.7 V1.8 V1.11 V1.13
		FROM NWB.SelectionOutputsStaging
		WHERE NwbSampleUploadRequestKey IS NOT NULL
		
		DELETE FROM NWB.SelectionOutputsStaging
		WHERE NwbSampleUploadRequestKey IS NOT NULL

	COMMIT TRAN

END TRY
BEGIN CATCH

	IF @@TRANCOUNT > 0
	BEGIN
		ROLLBACK TRAN
	END

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
GO
