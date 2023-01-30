CREATE PROC SelectionOutput.uspAuditAllSalesOutput
(
	@FileName VARCHAR(255),
	@RussiaOutput INTEGER = 0		-- V1.13
)
AS

/*
	Purpose:	Audit the all sales output for online
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)	Simon Peacock		Created
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
	1.7				27-01-2017		Chris Ledger		BUG 13160: Add ModelSummary and Interval
	1.8				17-03-2017		Chris Ledger		BUG 13670: Add VistaContractOrderNumber & DealNo
	1.9				29-03-2017		Chris Ledger		BUG 13783: Add FOBCode and UnknownLang
	1.10			24-10-2017		Chris Ledger		BUG 14245: Add BilingualFlag, langBilingual, DearNameBilingual, EmailSignatorTitleBilingual, EmailContactTextBilingual, EmailCompanyDetailsBilingual
	1.11			20-06-2018		Chris Ledger		BUG 14571: Add missing fields
	1.12			21-11-2018		Chris Ross			BUG 15079: Add in HotTopicCodes column.
	1.13			12-09-2019		Chris Ledger		BUG 15571: Separate Russia Output.
	1.14			26-05-2021		Chris Ledger		TASK 441: Add CQI and remove China.Sales_WithResponses
	1.15			02-07-2021		Chris Ledger		TASK 535: Add EventID
	1.16			20-07-2021		Chris Ledger		TASK 558: Add EngineType
	1.17			19-10-2021		Chris Ledger		TASK 664: Add PAGCode to EmployeeName & CRMEmployeeName fields
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
				@dtCATI	DATETIME	-- V1.11
	    
		SET	@NOW = GETDATE()
		SET	@dtCATI	= DATEADD(week, DATEDIFF(day, 0, @NOW)/7, 4) -- V1.11
		
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
			CASE SUBSTRING(ITYPE, 1,1)			-- V1.6
				WHEN 'H' THEN (SELECT CaseOutputTypeID FROM Event.CaseOutputTypes WHERE CaseOutputType = 'Online')
				WHEN 'T' THEN (SELECT CaseOutputTypeID FROM Event.CaseOutputTypes WHERE CaseOutputType = 'CATI')
				WHEN 'S' THEN (SELECT CaseOutputTypeID FROM Event.CaseOutputTypes WHERE CaseOutputType = 'SMS')
				ELSE (SELECT CaseOutputTypeID FROM Event.CaseOutputTypes WHERE CaseOutputType = 'Postal')
			END AS CaseOutputTypeID
		FROM SelectionOutput.OnlineOutput O
			INNER JOIN Event.vwEventTypes ET ON ET.EventTypeID = O.etype 
												AND ET.EventCategory IN ('Sales','CQI 3MIS','CQI 24MIS')		-- V1.14
			--LEFT JOIN [$(ETLDB)].China.Sales_WithResponses CSR ON O.ID = CSR.CaseID 							-- V1.4 -- V1.14							
		WHERE ((@RussiaOutput = 1 AND ISNULL(O.CTRY,'') = 'Russian Federation') OR  (@RussiaOutput = 0 AND ISNULL(O.CTRY,'') <> 'Russian Federation'))	-- V1.13
			--AND CSR.CaseID IS NULL					-- V1.14
			--AND Market NOT IN ('CHN', 'RUS','ZAF')	-- V1.2
	
		
		-- get the RowCount
		SET @RowCount = (SELECT COUNT(*) FROM #OutputtedSelections)

		IF @RowCount > 0
		BEGIN
		
			EXEC SelectionOutput.uspAudit @FileName, @RowCount, @Date, @AuditID OUTPUT

			;WITH CTE_CRMInfo AS									-- V1.11
			(
				SELECT SL.CaseID, 
					MAX(SL.AuditItemID) AS AuditItemID
				FROM SelectionOutput.OnlineOutput O
					INNER JOIN Event.vwEventTypes ET ON ET.EventTypeID = O.etype 
														AND ET.EventCategory IN ('Sales','CQI 3MIS','CQI 24MIS')	-- V1.14
					INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL ON SL.CaseID = O.ID
					LEFT JOIN [$(ETLDB)].CRM.Vista_Contract_Sales S ON SL.AuditItemID = S.AudititemID
					LEFT JOIN [$(ETLDB)].CRM.CQI C ON SL.AuditItemID = C.AudititemID								-- V1.14				
					--LEFT JOIN [$(ETLDB)].China.Sales_WithResponses CSR ON O.ID = CSR.CaseID 						-- V1.2		-- V1.14								
				WHERE S.AuditItemID IS NOT NULL																		-- V1.14
					OR C.AuditItemID IS NOT NULL																	-- V1.14
					--AND CSR.CaseID IS NULL																		-- V1.14
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
				ModelSummary,					-- V1.7
				IntervalPeriod,					-- V1.7
				VistaContractOrderNumber,		-- V1.8
				DealNo,							-- V1.8
				FOBCode,						-- V1.9
				UnknownLang,					-- V1.9
				BilingualFlag,					-- V1.10
				langBilingual,					-- V1.10
				DearNameBilingual,				-- V1.10
				EmailSignatorTitleBilingual,	-- V1.10
				EmailContactTextBilingual,		-- V1.10
				EmailCompanyDetailsBilingual,	-- V1.10
				VIN,							-- V1.11
				EventDate,						-- V1.11
				DealerCode,						-- V1.11
				Telephone,						-- V1.11
				WorkTel,						-- V1.11
				MobilePhone,					-- V1.11
				ManufacturerDealerCode,			-- V1.11
				ModelYear,						-- V1.11
				CustomerIdentifier,				-- V1.11
				OwnershipCycle,					-- V1.11
				OutletPartyID,					-- V1.11
				GDDDealerCode,					-- V1.11
				ReportingDealerPartyID,			-- V1.11
				VariantID,						-- V1.11
				ModelVariant,					-- V1.11
				SelectionDate,					-- V1.11
				CampaignID,						-- V1.11
				EmailSignator,					-- V1.11
				EmailSignatorTitle,				-- V1.11
				EmailContactText,				-- V1.11
				EmailCompanyDetails,			-- V1.11
				JLRCompanyname,					-- V1.11
				CRMSalesmanName,				-- V1.11
				CRMSalesmanCode,				-- V1.11
				RockarDealer,					-- V1.11
				SVOvehicle,						-- V1.11
				SVODealer,						-- V1.11
				HotTopicCodes,					-- V1.12
				EventID,						-- V1.15
				EngineType						-- V1.16
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
				CASE	WHEN VCS.AudititemID IS NULL THEN S.EmployeeCode 
						ELSE '' END AS EmployeeCode,
				CASE	WHEN VCS.AudititemID IS NULL THEN CASE	WHEN D.PAGCode IS NULL THEN S.EmployeeName									-- V1.17
																WHEN LEN(S.EmployeeName) > 0 THEN S.EmployeeName + ' (' + D.PAGCode + ')'	-- V1.17
																ELSE '' END																	-- V1.17
						ELSE '' END AS EmployeeName,																						-- V1.17
				S.ITYPE,						-- V1.6
				S.PilotCode,					-- V1.6
				S.ModelSummary,					-- V1.7
				S.IntervalPeriod,				-- V1.7
				S.VistaContractOrderNumber,		-- V1.8
				S.DealNo,						-- V1.8
				S.FOBCode,						-- V1.9
				S.UnknownLang,					-- V1.9
				S.BilingualFlag,				-- V1.10
				S.langBilingual,				-- V1.10
				S.DearNameBilingual,			-- V1.10
				S.EmailSignatorTitleBilingual,	-- V1.10
				S.EmailContactTextBilingual,	-- V1.10
				S.EmailCompanyDetailsBilingual,	-- V1.10
				REPLACE(S.VIN, CHAR(9), '') AS VIN,										-- V1.11
				REPLACE(CONVERT(VARCHAR(10), S.EventDate, 102), '.', '-') AS EventDate,	-- V1.11
				S.DealerCode,															-- V1.11
				REPLACE(S.Telephone, CHAR(9), '') AS Telephone,							-- V1.11
				REPLACE(S.WorkTel, CHAR(9), '') AS WorkTel,								-- V1.11
				REPLACE(S.MobilePhone, CHAR(9), '') AS MobilePhone,						-- V1.11
				S.ManufacturerDealerCode,												-- V1.11
				S.ModelYear,															-- V1.11
				REPLACE(S.CustomerIdentifier, CHAR(9), '') AS CustomerIdentifier,		-- V1.11
				S.OwnershipCycle,														-- V1.11
				S.OutletPartyID,														-- V1.11
				S.GDDDealerCode,														-- V1.11
				S.ReportingDealerPartyID,												-- V1.11
				S.VariantID,															-- V1.11
				S.ModelVariant,															-- V1.11
				CASE	WHEN S.Itype ='T' THEN  CONVERT(NVARCHAR(10), @dtCATI, 121)
						ELSE CONVERT(NVARCHAR(10), @NOW, 121) END AS SelectionDate,		-- V1.11
				CONVERT(NVARCHAR(100), CONVERT(VARCHAR(10), ISNULL(S.etype, '')) + '_' 
					+ CASE	WHEN ISNULL(S.ITYPE, '') = '' THEN 'blank'
							ELSE S.ITYPE END + '_' 
					+ CONVERT(VARCHAR(10), ISNULL(S.ccode, '')) + '_' 
					+ CASE	WHEN S.manuf = 2 THEN 'J'
							WHEN S.manuf = 3 THEN 'L'
							ELSE 'UknownManufacturer' END + '_' 
					+ CONVERT(VARCHAR(10), ISNULL(S.lang, ''))) AS CampaignId,										-- V1.11
				REPLACE(S.EmailSignator, CHAR(10), '<br/>') AS EmailSignator,										-- V1.11
				REPLACE(S.EmailSignatorTitle, CHAR(10), '<br/>') AS EmailSignatorTitle,								-- V1.11	
				REPLACE(S.EmailContactText, CHAR(10), '<br/>') AS EmailContactText,									-- V1.11	
				REPLACE(S.EmailCompanyDetails, CHAR(10), '<br/>') AS EmailCompanyDetails,							-- V1.11
				REPLACE(S.JLRCompanyname, CHAR(10), '<br/>') AS JLRCompanyname,										-- V1.11
				CASE	WHEN D.PAGCode IS NULL THEN ISNULL(COALESCE(VCS.VISTACONTRACT_SALES_MAN_FULNAM, C.VISTACONTRACT_SALES_MAN_FULNAM, S.SalesAdvisorName), '')																			-- V1.17
						WHEN LEN(ISNULL(COALESCE(VCS.VISTACONTRACT_SALES_MAN_FULNAM, C.VISTACONTRACT_SALES_MAN_FULNAM, S.SalesAdvisorName), ''))>0 THEN COALESCE(VCS.VISTACONTRACT_SALES_MAN_FULNAM, C.VISTACONTRACT_SALES_MAN_FULNAM, S.SalesAdvisorName) + ' (' + D.PAGCode + ')'	-- V1.17
						ELSE '' END AS CRMSalesmanName,																																						-- V1.17
				ISNULL(COALESCE(VCS.VISTACONTRACT_SALESMAN_CODE, C.VISTACONTRACT_SALESMAN_CODE, S.SalesAdvisorID), '') AS CRMSalesmanCode,			-- V1.11
				ISNULL(S.RockarDealer,0) AS RockarDealer,															-- V1.11
				ISNULL(S.SVOvehicle,0) As SVOvehicle,																-- V1.11
				ISNULL(S.SVODealer,0) AS SVODealer,																	-- V1.11	
				S.HotTopicCodes,																					-- V1.12
				S.EventID,																							-- V1.15
				S.EngineType																						-- V1.16
			FROM #OutputtedSelections O
				INNER JOIN SelectionOutput.OnlineOutput S ON O.CaseID = S.ID
															AND O.PartyID = S.PartyID
				INNER JOIN Event.vwEventTypes ET ON ET.EventTypeID = S.etype										-- V1.11
													AND ET.EventCategory IN ('Sales','CQI 3MIS','CQI 24MIS')		-- V1.14
				INNER JOIN Event.EventTypes ET1 ON ET1.EventTypeID = S.etype										-- V1.17
				LEFT JOIN dbo.DW_JLRCSPDealers D ON S.OutletPartyID = D.OutletPartyID								-- V1.17
													AND ET1.RelatedOutletFunctionID = D.OutletFunctionID			-- V1.17
				LEFT JOIN CTE_CRMInfo CRM ON CRM.CaseID = S.ID														-- V1.11
				LEFT JOIN [$(ETLDB)].CRM.Vista_Contract_Sales VCS ON VCS.AudititemID = CRM.AudititemID				-- V1.11
				LEFT JOIN [$(ETLDB)].CRM.CQI C ON C.AudititemID = CRM.AudititemID									-- V1.11	-- V1.14
				--LEFT JOIN [$(ETLDB)].China.Sales_WithResponses CSR ON S.ID = CSR.CaseID 							-- V1.11	-- V1.14							
			--WHERE (CSR.CaseID IS NULL)																			-- V1.14			
			ORDER BY O.AuditItemID																					-- V1.11

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