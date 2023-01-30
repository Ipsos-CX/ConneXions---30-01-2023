CREATE PROC SelectionOutput.uspAuditAllServiceOutput
(
	@FileName VARCHAR(255),
	@RussiaOutput INTEGER = 0		-- V1.12
)
AS

/*
	Purpose:	Audit the all service output for online
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created
	1.1				27-06-2012		Chris Ross			BUG 6940.  Corrected bug where checking for wrong ITYPE value 
														to determine On-line in SelectionOutput.OnlineOutput file.
														Should have been 'H' and not 'I'.
	1.2				05-02-2012		Chris Ross			Updated to include China/Russia/S.Africa.  Also, ensure ITYPE set correctly for 
														Telephone.
	1.3 			12-02-2012		Chris Ross			Change Password to PartyID														
	1.4				17-07-2015		Eddie Thomas		Filter out CaseIds associated to China sample supplied with responses
	1.5				02-11-2015		Eddie Thomas		11844 - Employee Reporting
	1.6				31-03-2016		Chris Ross			BUG 12407: Add ITYPE and PilotCode into Audit.SelectionOutput and update CaseOutputTypeID 
																	statement to use first char only for comparison.
	1.7				17-03-2017		Chris Ledger		BUG 13670: Add RepairOrderNumber	
	1.8				29-03-2017		Chris Ledger		BUG 13783: Add FOBCode and UnknownLang	
	1.9				24-10-2017		Chris Ledger		BUG 14245: Add BilingualFlag, langBilingual, DearNameBilingual, EmailSignatorTitleBilingual, EmailContactTextBilingual, EmailCompanyDetailsBilingual
	1.10			21-06-2018		Chris Ledger		BUG 14751: Add missing columns.	
	1.11			21-11-2018		Chris Ross			BUG 15079: Add in HotTopicCodes column.
	1.12			12-09-2019		Chris Ledger		BUG 15571: Separate Russia Output.
	1.14			28-01-2020		Chris Ledger		BUG 16891: Add field ServiceEventType
	1.15			27-05-2021		Chris Ledger		Remove China.Service_WithResponses
	1.16			02-07-2021		Chris Ledger		TASK 535: Add EventID
	1.17			20-07-2021		Chris Ledger		TASK 558: Add EngineType
	1.18			19-10-2021		Chris Ledger		TASK 664: Add PAGCode to EmployeeName, ServiceTechnicianName & ServiceAdvisorName fields
*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	BEGIN TRAN
	
		DECLARE @Date DATETIME
		SET @Date = GETDATE()

		DECLARE @NOW	DATETIME,	
			@dtCATI	DATETIME	-- V1.10
    
		SET		@NOW = GETDATE()
		SET		@dtCATI	= DATEADD(week, DATEDIFF(day, 0, @NOW)/7, 4) -- V1.10
			
		-- CREATE A TEMP TABLE TO HOLD EACH TYPE OF OUTPUT
		CREATE TABLE #OutputtedSelections
		(
			PhysicalRowID INT IDENTITY(1,1) NOT NULL,
			AuditID INT NULL,
			AuditItemID INT NULL,
			CaseID INT NULL,
			PartyID INT NULL,
			CaseOutputTypeID INT NULL
		)

		DECLARE @RowCount INT
		DECLARE @AuditID dbo.AuditID

		INSERT INTO #OutputtedSelections (CaseID, PartyID, CaseOutputTypeID)
		SELECT DISTINCT
			O.[ID] AS CaseID, 
			O.PartyID,
			CASE SUBSTRING(ITYPE,1,1)			-- V1.6
				WHEN 'H' THEN (SELECT CaseOutputTypeID FROM Event.CaseOutputTypes WHERE CaseOutputType = 'Online')
				WHEN 'T' THEN (SELECT CaseOutputTypeID FROM Event.CaseOutputTypes WHERE CaseOutputType = 'CATI')
				WHEN 'S' THEN (SELECT CaseOutputTypeID FROM Event.CaseOutputTypes WHERE CaseOutputType = 'SMS')
				ELSE (SELECT CaseOutputTypeID FROM Event.CaseOutputTypes WHERE CaseOutputType = 'Postal')
			END AS CaseOutputTypeID
		FROM SelectionOutput.OnlineOutput O
			INNER JOIN Event.vwEventTypes ET ON ET.EventTypeID = O.etype 
												AND ET.EventCategory = 'Service'
		--LEFT JOIN [$(ETLDB)].China.Service_WithResponses CSR ON O.ID = CSR.CaseID 	-- V1.15									
		WHERE ((@RussiaOutput = 1 AND ISNULL(O.CTRY,'') = 'Russian Federation') OR  (@RussiaOutput = 0 AND ISNULL(O.CTRY,'') <> 'Russian Federation'))	-- V1.12
		--AND CSR.CaseID IS NULL														-- V1.15
		--ND Market NOT IN ('CHN', 'RUS','ZAF')	-- V1.2
		
		
		
		-- get the RowCount
		SET @RowCount = (SELECT COUNT(*) FROM #OutputtedSelections)

		IF @RowCount > 0
		BEGIN
		
			EXEC SelectionOutput.uspAudit @FileName, @RowCount, @Date, @AuditID OUTPUT

			;WITH CTE_CRMInfo AS												-- V1.10
			(
				SELECT SL.CaseID, 
					MAX(SL.AuditItemID) AS AuditItemID
				FROM SelectionOutput.OnlineOutput O
					INNER JOIN Event.vwEventTypes ET ON ET.EventTypeID = O.etype 
														AND	ET.EventCategory = 'Service'
					INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL ON SL.CaseID = O.ID
					INNER JOIN [$(ETLDB)].CRM.DMS_Repair_Service DRS ON SL.AudititemID = DRS.AudititemID
					--LEFT JOIN [$(ETLDB)].China.Service_WithResponses CSR ON O.ID = CSR.CaseID		-- V1.15										
				--WHERE   CSR.CaseID IS NULL														-- V1.15
				GROUP BY SL.CaseID
			)			
			INSERT INTO [$(AuditDB)].Audit.SelectionOutput
			(
				AuditID, 
				AuditItemID, 
				SelectionOutputTypeID, 
				PartyID, 
				CaseID, 
				FullModel, 
				Model, 
				sType, 
				CarReg, 
				Title, 
				Initial, 
				Surname, 
				Fullname, 
				DearName, 
				CoName, 
				Add1, 
				Add2, 
				Add3, 
				Add4, 
				Add5, 
				Add6, 
				Add7, 
				Add8, 
				Add9, 
				CTRY, 
				EmailAddress, 
				Dealer, 
				sno, 
				ccode, 
				modelcode, 
				lang, 
				manuf, 
				gender, 
				qver, 
				blank, 
				etype, 
				reminder, 
				week, 
				test, 
				SampleFlag, 
				SalesServiceFile,
				Expired,
				DateOutput,
				EmployeeCode,					-- V1.5
				EmployeeName,					-- V1.5
				ITYPE,							-- V1.6
				PilotCode,						-- V1.6
				RepairOrderNumber,				-- V1.7
				FOBCode,						-- V1.8
				UnknownLang,					-- V1.8
				BilingualFlag,					-- V1.9
				langBilingual,					-- V1.9
				DearNameBilingual,				-- V1.9
				EmailSignatorTitleBilingual,	-- V1.9
				EmailContactTextBilingual,		-- V1.9
				EmailCompanyDetailsBilingual,	-- V1.9
				VIN,							-- V.10
				EventDate,						-- V.10
				DealerCode,						-- V.10
				Telephone,						-- V.10
				WorkTel,						-- V.10
				MobilePhone,					-- V.10
				ManufacturerDealerCode,			-- V.10
				ModelYear,						-- V.10
				CustomerIdentifier,				-- V.10
				OwnershipCycle,					-- V.10
				OutletPartyID,					-- V.10
				GDDDealerCode,					-- V.10
				ReportingDealerPartyID,			-- V.10
				VariantID,						-- V.10
				ModelVariant,					-- V.10
				SelectionDate,					-- V.10
				CampaignID,						-- V.10
				EmailSignator,					-- V.10
				EmailSignatorTitle,				-- V.10
				EmailContactText,				-- V.10
				EmailCompanyDetails,			-- V.10
				JLRCompanyname,					-- V.10
				ServiceTechnicianID,			-- V.10
				ServiceTechnicianName,			-- V.10
				ServiceAdvisorName,				-- V.10
				ServiceAdvisorID,				-- V.10
				RockarDealer,					-- V.10
				SVOvehicle,						-- V.10
				SVODealer,						-- V.10
				HotTopicCodes,					-- V1.11
				ServiceEventType,				-- V1.14
				EventID,						-- V1.16
				EngineType						-- V1.17
			)
			SELECT DISTINCT
				O.AuditID, 
				O.AuditItemID, 
				(SELECT SelectionOutputTypeID FROM [$(AuditDB)].dbo.SelectionOutputTypes WHERE SelectionOutputType = 'All') AS SelectionOutputTypeID,
				S.PartyID, 
				S.[ID] AS CaseID, 
				S.FullModel, 
				S.Model, 
				S.sType, 
				S.CarReg, 
				S.Title, 
				S.Initial, 
				S.Surname, 
				S.Fullname, 
				S.DearName, 
				S.CoName, 
				S.Add1, 
				S.Add2, 
				S.Add3, 
				S.Add4, 
				S.Add5, 
				S.Add6, 
				S.Add7, 
				S.Add8, 
				S.Add9, 
				S.CTRY, 
				S.EmailAddress, 
				S.Dealer, 
				S.sno, 
				S.ccode, 
				S.modelcode, 
				S.lang, 
				S.manuf, 
				S.gender, 
				S.qver, 
				S.blank, 
				S.etype, 
				S.reminder, 
				S.week, 
				S.test, 
				S.SampleFlag, 
				S.SalesServiceFile,
				S.Expired,
				@Date AS OutputDate,
				CASE	WHEN DRS.AudititemID IS NULL THEN S.EmployeeCode 
						ELSE '' END AS EmployeeCode,
				CASE	WHEN DRS.AudititemID IS NULL THEN CASE	WHEN D.PAGCode IS NULL THEN S.EmployeeName									-- V1.18
																WHEN LEN(S.EmployeeName) > 0 THEN S.EmployeeName + ' (' + D.PAGCode + ')'	-- V1.18
																ELSE '' END																	-- V1.18
						ELSE '' END AS EmployeeName,	
				S.ITYPE,						-- V1.6
				S.Pilotcode,					-- V1.6
				S.RepairOrderNumber,			-- V1.7
				S.FOBCode,						-- V1.8
				S.UnknownLang,					-- V1.8
				S.BilingualFlag,				-- V1.9
				S.langBilingual,				-- V1.9
				S.DearNameBilingual,			-- V1.9
				S.EmailSignatorTitleBilingual,	-- V1.9
				S.EmailContactTextBilingual,	-- V1.9
				S.EmailCompanyDetailsBilingual,	-- V1.9
				REPLACE(S.VIN, CHAR(9), '') AS VIN,																-- V1.10
				REPLACE(CONVERT(VARCHAR(10), S.EventDate, 102), '.', '-') AS EventDate,							-- V1.10
				S.DealerCode,																					-- V1.10	
				REPLACE(S.Telephone, CHAR(9), '') AS Telephone,													-- V1.10
				REPLACE(S.WorkTel, CHAR(9), '') AS WorkTel,														-- V1.10
				REPLACE(S.MobilePhone, CHAR(9), '') AS MobilePhone,												-- V1.10
				S.ManufacturerDealerCode,																		-- V1.10
				S.ModelYear,																					-- V1.10
				REPLACE(S.CustomerIdentifier, CHAR(9), '') AS CustomerIdentifier,								-- V1.10
				S.OwnershipCycle,																				-- V1.10
				S.OutletPartyID,																				-- V1.10
				S.GDDDealerCode,																				-- V1.10
				S.ReportingDealerPartyID,																		-- V1.10
				S.VariantID,																					-- V1.10
				S.ModelVariant,																					-- V1.10
				CASE	WHEN S.Itype ='T' THEN CONVERT(NVARCHAR(10), @dtCATI, 121)								-- V1.10
						ELSE CONVERT(NVARCHAR(10), @NOW, 121) END AS SelectionDate,								-- V1.10
				CONVERT(NVARCHAR(100), CONVERT(VARCHAR(10), ISNULL(S.etype, ''))
					+ '_' + CASE WHEN ISNULL(S.ITYPE, '') = '' THEN 'blank'
								 ELSE S.ITYPE END + '_' 
					+ CONVERT(VARCHAR(10), ISNULL(S.ccode, ''))
					+ '_' + CASE WHEN S.manuf = 2 THEN 'J'
								 WHEN S.manuf = 3 THEN 'L'
								 ELSE 'UknownManufacturer' END 
					+ '_' + CONVERT(VARCHAR(10), ISNULL(S.lang, ''))) AS CampaignId,							-- V1.10
				REPLACE(S.EmailSignator, CHAR(10), '<br/>') AS EmailSignator,									-- V1.10
				REPLACE(S.EmailSignatorTitle, CHAR(10), '<br/>') AS EmailSignatorTitle,							-- V1.10	
				REPLACE(S.EmailContactText, CHAR(10), '<br/>') AS EmailContactText,								-- V1.10
				REPLACE(S.EmailCompanyDetails, CHAR(10), '<br/>') AS EmailCompanyDetails,						-- V1.10
				REPLACE(S.JLRCompanyname, CHAR(10), '<br/>') AS JLRCompanyname,									-- V1.10
				ISNULL(COALESCE(DRS.DMS_TECHNICIAN_ID, S.TechnicianID), '') AS ServiceTechnicianID,				-- V1.10
				CASE	WHEN D.PAGCode IS NULL THEN ISNULL(COALESCE(DRS.DMS_TECHNICIAN, S.TechnicianName), '')																		-- V1.18
						WHEN LEN(ISNULL(COALESCE(DRS.DMS_TECHNICIAN, S.TechnicianName), ''))>0 THEN COALESCE(DRS.DMS_TECHNICIAN, S.TechnicianName) + ' (' + D.PAGCode + ')'			-- V1.18
						ELSE '' END AS ServiceTechnicianName,																														-- V1.18
				CASE	WHEN D.PAGCode IS NULL THEN ISNULL(COALESCE(DRS.DMS_SERVICE_ADVISOR, S.ServiceAdvisorName), '')																				-- V1.18
						WHEN LEN(ISNULL(COALESCE(DRS.DMS_SERVICE_ADVISOR, S.ServiceAdvisorName), ''))>0 THEN COALESCE(DRS.DMS_SERVICE_ADVISOR, S.ServiceAdvisorName) + ' (' + D.PAGCode + ')'		-- V1.18
						ELSE '' END AS ServiceAdvisorName,																																			-- V1.18
				ISNULL(COALESCE(DRS.DMS_SERVICE_ADVISOR_ID, S.ServiceAdvisorID), '') AS ServiceAdvisorID,		-- V1.10
				ISNULL(S.RockarDealer,0) AS RockarDealer,														-- V1.10
				ISNULL(S.SVOvehicle,0) As SVOvehicle,															-- V1.10
				ISNULL(S.SVODealer,0) AS SVODealer,
				S.HotTopicCodes,																				-- V1.11
				S.ServiceEventType,																				-- V1.14
				S.EventID,																						-- V1.16
				S.EngineType																					-- V1.17
			FROM #OutputtedSelections O
				INNER JOIN SelectionOutput.OnlineOutput S ON O.CaseID = S.[ID]
															AND O.PartyID = S.PartyID
				INNER JOIN Event.EventTypes ET1 ON ET1.EventTypeID = S.etype										-- V1.18
				LEFT JOIN dbo.DW_JLRCSPDealers D ON S.OutletPartyID = D.OutletPartyID								-- V1.18
													AND ET1.RelatedOutletFunctionID = D.OutletFunctionID			-- V1.18
				LEFT JOIN CTE_CRMInfo CRM ON CRM.CaseID = S.ID
				LEFT JOIN [$(ETLDB)].CRM.DMS_Repair_Service DRS ON DRS.AuditItemID = CRM.AuditItemID
				--LEFT JOIN [$(ETLDB)].China.Service_WithResponses CSR ON S.ID = CSR.CaseID 					-- V1.15									
			--WHERE CSR.CaseID IS NULL																			-- V1.15
			ORDER BY O.AuditItemID
		END

		-- DROP THE TEMPORARY TABLE
		DROP TABLE #OutputtedSelections
		
	COMMIT TRAN
		
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
		
	IF @@TRANCOUNT > 0
	BEGIN
		ROLLBACK TRAN
	END
		
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH