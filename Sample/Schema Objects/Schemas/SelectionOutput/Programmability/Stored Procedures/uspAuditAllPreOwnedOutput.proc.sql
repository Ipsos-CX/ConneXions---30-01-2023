CREATE PROC SelectionOutput.uspAuditAllPreOwnedOutput
(
	@FileName VARCHAR(255),
	@RussiaOutput INTEGER = 0		-- V1.6
)
AS

/*
	Purpose:	Audit the all PreOwned output for online
	
	Version			Date			Developer			Comment
	-------			----			---------			-------
	1.0				03-02-2016		Chris Ross			Original version.  BUG 12038. 
	1.1				31-03-2016		Chris Ross			BUG 12407: Add ITYPE and PilotCode into Audit.SelectionOutput and update CaseOutputTypeID 
																	statement to use first char only for comparison.
	1.2				06-07-2017		Eddie Thomas		BUG 14035 was : Added/populate fields SVOVehicle & FOBCode																
	1.3				24-10-2017		Chris Ledger		BUG 14245: Add BilingualFlag, langBilingual, DearNameBilingual, EmailSignatorTitleBilingual, EmailContactTextBilingual, EmailCompanyDetailsBilingual
	1.4				19-06-2018		Chris Ledger		BUG 14751: Add missing output fields.	
	1.5				26-03-2019		Chris Ross			BUG 15310 - Add in HotTopicCodes column
	1.6				12-09-2019		Chris Ledger		BUG 15571 - Separate Russia Output
	1.7				27-05-2021		Chris Ledger		Remove China.Sales_WithResponses
	1.8				02-07-2021		Chris Ledger		TASK 535: Add EventID
	1.9				20-07-2021		Chris Ledger		TASK 558: Add EngineType
	1.10			19-10-2021		Chris Ledger		TASK 664: Add PAGCode to EmployeeName & CRMEmployeeName fields
	1.11			09-11-2021		Chris Ledger		TASK 664: Fix bug with adding PAGCode to EmployeeName & CRMEmployeeName fields
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

		DECLARE @NOW	DATETIME,	-- V1.4
		@dtCATI	DATETIME			-- V1.4
    
		SET	@NOW = GETDATE()										-- V1.4
		SET	@dtCATI	= DATEADD(week, DATEDIFF(day, 0, @NOW)/7, 4)	-- V.14
		
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
			CASE SUBSTRING(ITYPE, 1,1)			-- V1.1
				WHEN 'H' THEN (SELECT CaseOutputTypeID FROM Event.CaseOutputTypes WHERE CaseOutputType = 'Online')
				WHEN 'T' THEN (SELECT CaseOutputTypeID FROM Event.CaseOutputTypes WHERE CaseOutputType = 'CATI')
				WHEN 'S' THEN (SELECT CaseOutputTypeID FROM Event.CaseOutputTypes WHERE CaseOutputType = 'SMS')
				ELSE (SELECT CaseOutputTypeID FROM Event.CaseOutputTypes WHERE CaseOutputType = 'Postal')
			END AS CaseOutputTypeID
		FROM SelectionOutput.OnlineOutput O
			INNER JOIN Event.vwEventTypes ET ON ET.EventTypeID = O.etype 
												AND ET.EventCategory = 'PreOwned'
			INNER JOIN Event.AutomotiveEventBasedInterviews AEBI ON O.ID = AEBI.CaseID							-- V1.4
			INNER JOIN Event.AdditionalInfoSales AIS ON AIS.EventID = AEBI.EventID								-- V1.4
			INNER JOIN Vehicle.Vehicles V	ON O.VIN = V.VIN													-- V1.4
			--LEFT JOIN [$(ETLDB)].China.Sales_WithResponses CSR ON O.ID = CSR.CaseID 							-- V1.7								
		WHERE  ((@RussiaOutput = 1 AND ISNULL(O.CTRY,'') = 'Russian Federation') OR  (@RussiaOutput = 0 AND ISNULL(O.CTRY,'') <> 'Russian Federation'))	-- V1.6
		-- AND Market NOT IN ('CHN', 'RUS','ZAF')	-- V1.2
		-- AND CSR.CaseID IS NULL																				-- V1.7
	
		
		-- get the RowCount
		SET @RowCount = (SELECT COUNT(*) FROM #OutputtedSelections)

		IF @RowCount > 0
		BEGIN
		
			EXEC SelectionOutput.uspAudit @FileName, @RowCount, @Date, @AuditID OUTPUT
			
			;WITH CTE_CRMInfoPreOwned (CaseID, AuditItemID) AS										-- V1.10
			(
				SELECT SL.CaseID, 
					MAX(SL.AuditItemID) AS AuditItemID
				FROM SelectionOutput.OnlineOutput O
					INNER JOIN Event.vwEventTypes ET ON	ET.EventTypeID = O.etype 
														AND	ET.EventCategory = 'PreOwned'
					INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL ON SL.CaseID = O.ID
					INNER JOIN [$(ETLDB)].CRM.PreOwned P ON SL.AuditItemID = P.AuditItemID
					--LEFT JOIN [$(ETLDB)].China.Service_WithResponses CSR ON O.ID = CSR.CaseID 	-- V1.7								
				--WHERE CSR.CaseID IS NULL															-- V1.7
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
				EmployeeCode,			
				EmployeeName,			
				ITYPE,							-- V1.1
				PilotCode,						-- V1.1
				SVOVehicle,						-- V1.2
				FOBCode,
				BilingualFlag,					-- V1.3
				langBilingual,					-- V1.3
				DearNameBilingual,				-- V1.3
				EmailSignatorTitleBilingual,	-- V1.3
				EmailContactTextBilingual,		-- V1.3
				EmailCompanyDetailsBilingual,	-- V1.3
				VIN,							-- V1.4
				EventDate,						-- V1.4
				DealerCode,						-- V1.4
				Telephone,						-- V1.4
				WorkTel,						-- V1.4
				MobilePhone,					-- V1.4
				ManufacturerDealerCode,			-- V1.4
				ModelYear,						-- V1.4
				CustomerIdentifier,				-- V1.4
				OwnershipCycle,					-- V1.4
				OutletPartyID,					-- V1.4
				GDDDealerCode,					-- V1.4
				ReportingDealerPartyID,			-- V1.4
				VariantID,						-- V1.4
				ModelVariant,					-- V1.4
				SelectionDate,					-- V1.4
				CampaignID,						-- V1.4
				EmailSignator,					-- V1.4
				EmailSignatorTitle,				-- V1.4
				EmailContactText,				-- V1.4
				EmailCompanyDetails,			-- V1.4
				CRMSalesmanName,				-- V1.10
				CRMSalesmanCode,				-- V1.10
				JLRCompanyname,					-- V1.4
				Approved,						-- V1.4
				HotTopicCodes,					-- V1.5
				EventID,						-- V1.8
				EngineType						-- V1.9
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
				@Date AS DateOutput,
				CASE	WHEN P.AudititemID IS NULL THEN S.EmployeeCode																		-- V1.10
						ELSE '' END AS EmployeeCode,																						-- V1.10
				CASE	WHEN P.AudititemID IS NULL THEN CASE	WHEN D.PAGCode IS NULL THEN S.EmployeeName									-- V1.10
																WHEN LEN(S.EmployeeName) > 0 THEN S.EmployeeName + ' (' + D.PAGCode + ')'	-- V1.10
																ELSE '' END																	-- V1.10
						ELSE '' END AS EmployeeName,																						-- V1.10
				S.ITYPE,										-- V1.1
				S.PilotCode,									-- V1.1
				ISNULL(V.SVOTypeID,0) AS SVOvehicle,			-- V1.2
				V.FOBCode,										-- V1.2
				S.BilingualFlag,								-- V1.3
				S.langBilingual,								-- V1.3
				S.DearNameBilingual,							-- V1.3
				S.EmailSignatorTitleBilingual,					-- V1.3
				S.EmailContactTextBilingual,					-- V1.3
				S.EmailCompanyDetailsBilingual,					-- V1.3
				REPLACE(S.VIN, CHAR(9), '') AS VIN,											-- V1.4
				REPLACE(CONVERT(VARCHAR(10), S.EventDate, 102), '.', '-') AS EventDate,		-- V1.4
				S.DealerCode,																-- V1.4
				REPLACE(S.Telephone, CHAR(9), '') AS Telephone,								-- V1.4
				REPLACE(S.WorkTel, CHAR(9), '') AS WorkTel,									-- V1.4
				REPLACE(S.MobilePhone, CHAR(9), '') AS MobilePhone,							-- V1.4
				S.ManufacturerDealerCode,													-- V1.4
				S.ModelYear,																-- V1.4
				REPLACE(S.CustomerIdentifier, CHAR(9), '') AS CustomerIdentifier,			-- V1.4
				S.OwnershipCycle,															-- V1.4
				S.OutletPartyID,															-- V1.4
				S.GDDDealerCode,															-- V1.4
				S.ReportingDealerPartyID,													-- V1.4
				S.VariantID,																-- V1.4
				S.ModelVariant,																-- V1.4
				CASE	WHEN S.Itype ='T' THEN  CONVERT(NVARCHAR(10), @dtCATI, 121)
						ELSE CONVERT(NVARCHAR(10), @NOW, 121) END AS SelectionDate,			-- V1.4
				CONVERT(NVARCHAR(100), CONVERT(VARCHAR(10), ISNULL(S.etype, '')) + '_'
					+ CASE WHEN ISNULL(S.ITYPE, '') = '' THEN 'blank'
						   ELSE S.ITYPE END + '_' 
					+ CONVERT(VARCHAR(10), ISNULL(S.ccode, '')) + '_'
					+ CASE WHEN S.manuf = 2 THEN 'J'
						   WHEN S.manuf = 3 THEN 'L'
						   ELSE 'UknownManufacturer' END + '_' 
					+ CONVERT(VARCHAR(10), ISNULL(S.lang, ''))) AS CampaignId,				-- V1.4
				REPLACE(S.EmailSignator, CHAR(10), '<br/>') AS EmailSignator,				-- V1.4			
				REPLACE(S.EmailSignatorTitle, CHAR(10), '<br/>') AS EmailSignatorTitle,		-- V1.4
				REPLACE(S.EmailContactText, CHAR(10), '<br/>') AS EmailContactText,			-- V1.4
				REPLACE(S.EmailCompanyDetails, CHAR(10), '<br/>') AS EmailCompanyDetails,	-- V1.4
				REPLACE(S.JLRCompanyname, CHAR(10), '<br/>') AS JLRCompanyname,				-- V1.4
				CASE	WHEN D.PAGCode IS NULL THEN ISNULL(COALESCE(P.VISTACONTRACT_SALES_MAN_FULNAM, S.SalesAdvisorName), '')																				-- V1.10
						WHEN LEN(ISNULL(COALESCE(P.VISTACONTRACT_SALES_MAN_FULNAM, S.SalesAdvisorName), ''))>0 THEN COALESCE(P.VISTACONTRACT_SALES_MAN_FULNAM, S.SalesAdvisorName) + ' (' + D.PAGCode + ')'	-- V1.10
						ELSE '' END AS CRMSalesmanName,																																						-- V1.10
				ISNULL(COALESCE(P.VISTACONTRACT_SALESMAN_CODE, S.SalesAdvisorID), '') AS CRMSalesmanCode,			-- V1.10
				AIS.Approved,																-- V1.4
				S.HotTopicCodes,															-- V1.5
				S.EventID,																	-- V1.8
				S.EngineType																-- V1.9
			FROM #OutputtedSelections O
				INNER JOIN SelectionOutput.OnlineOutput S ON O.CaseID = S.[ID]
															AND O.PartyID = S.PartyID
 				INNER JOIN Event.EventTypes ET1 ON ET1.EventTypeID = S.etype										-- V1.10
				LEFT JOIN dbo.DW_JLRCSPDealers D ON S.OutletPartyID = D.OutletPartyID								-- V1.10
													AND ET1.RelatedOutletFunctionID = D.OutletFunctionID			-- V1.10
				INNER JOIN Event.AutomotiveEventBasedInterviews AEBI ON S.ID = AEBI.CaseID		-- V1.4
				INNER JOIN Event.AdditionalInfoSales AIS ON AIS.EventID = AEBI.EventID			-- V1.4
				INNER JOIN Vehicle.Vehicles V ON S.VIN = V.VIN	
				LEFT JOIN CTE_CRMInfoPreOwned CRM ON CRM.CaseID = S.ID							-- V1.11
				LEFT JOIN [$(ETLDB)].CRM.PreOwned P ON P.AuditItemID = CRM.AuditItemID			-- V1.11
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