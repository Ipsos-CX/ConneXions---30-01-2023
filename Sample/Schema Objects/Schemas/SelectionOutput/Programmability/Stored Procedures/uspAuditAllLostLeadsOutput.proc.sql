CREATE PROC SelectionOutput.uspAuditAllLostLeadsOutput
(
	@FileName VARCHAR(255),
	@NorthAmericaOnly INTEGER = 0,	-- V1.2 
	@RussiaOutput INTEGER = 0		-- V1.6
)
AS

/*
	Purpose:	Audit the 'all' Lost Leads output for online
	
	Version			Date			Developer			Comment
	1.0				11-08-2016		Chris Ross			Copied from SelectionOutput.uspAuditAllSalesOutput procedure.
	1.1				24-10-2017		Chris Ledger		BUG 14245: Add BilingualFlag, langBilingual, DearNameBilingual, EmailSignatorTitleBilingual, EmailContactTextBilingual, EmailCompanyDetailsBilingual
	1.2				13-03-2018		Chris Ledger		BUG 14272: Add NA Filter to Audit
	1.3				15-06-2018		Chris Ledger		BUG 14752: Add missing fields
	1.4				26-09-2018		Eddie Thomas		BUG 14820: Lost Leads - Global loader change
	1.5				01-09-2019		Eddie Thomas		BUG 15281: Lost Leads Selection date 
	1.6				12-09-2019		Chris Ledger		BUG 15571: Separate Russia Output
	1.7				28-10-2019		Chris Ledger		BUG 15490: Add in DealerType column
	1.8				28-01-2020		Chris Ledger		BUG 16819: Add in Queue field
	1.9				31-03-2020		Chris Ledger		Add in PreOwned LostLeads
	1.10			27-05-2021		Chris Ledger		Remove China.Sales_WithResponses
	1.11			20-07-2021		Chris Ledger		Add EventID & EngineType
	1.12			21-07-2021		Chris Ledger		Add SVOvehicle
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

		DECLARE @NOW			DATETIME	-- V1.3
		DECLARE	@dtCATI			DATETIME	-- V1,3
	
		SET	@NOW = GETDATE() 										-- V1.3
		SET	@dtCATI	= DATEADD(week, DATEDIFF(day, 0, @NOW)/7, 4)	-- V1.3
		
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
			CASE SUBSTRING(ITYPE, 1,1)			
				WHEN 'H' THEN (SELECT CaseOutputTypeID FROM Event.CaseOutputTypes WHERE CaseOutputType = 'Online')
				WHEN 'T' THEN (SELECT CaseOutputTypeID FROM Event.CaseOutputTypes WHERE CaseOutputType = 'CATI')
				WHEN 'S' THEN (SELECT CaseOutputTypeID FROM Event.CaseOutputTypes WHERE CaseOutputType = 'SMS')
				ELSE (SELECT CaseOutputTypeID FROM Event.CaseOutputTypes WHERE CaseOutputType = 'Postal')
			END AS CaseOutputTypeID
		FROM SelectionOutput.OnlineOutput O
		INNER JOIN Event.vwEventTypes ET ON ET.EventTypeID = O.etype 
											AND ET.EventCategory IN ('LostLeads','PreOwned LostLeads')		-- V1.9
		--LEFT JOIN [$(ETLDB)].China.Sales_WithResponses CSR ON O.ID = CSR.CaseID 							-- V1.10			
		WHERE ((@NorthAmericaOnly = 1 AND O.CTRY IN ('UNITED STATES OF AMERICA','Canada'))					-- V1.2
			OR  (@NorthAmericaOnly = 0 AND O.CTRY NOT IN ('UNITED STATES OF AMERICA','Canada')))			-- V1.2
			AND ((@RussiaOutput = 1 AND ISNULL(O.CTRY,'') = 'Russian Federation') OR  (@RussiaOutput = 0 AND ISNULL(O.CTRY,'') <> 'Russian Federation'))	-- V1.6
			--AND CSR.Sales_WithResponses																	-- V1.10
	
		
		-- get the RowCount
		SET @RowCount = (SELECT COUNT(*) FROM #OutputtedSelections)

		IF @RowCount > 0
		BEGIN
		
			EXEC SelectionOutput.uspAudit @FileName, @RowCount, @Date, @AuditID OUTPUT
			
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
				ITYPE,					
				PilotCode,
				BilingualFlag,					-- V1.1
				langBilingual,					-- V1.1
				DearNameBilingual,				-- V1.1
				EmailSignatorTitleBilingual,	-- V1.1
				EmailContactTextBilingual,		-- V1.1
				EmailCompanyDetailsBilingual,	-- V1.1
				VIN,							-- V1.3
				EventDate,						-- V1.3
				DealerCode,						-- V1.3
				Telephone,						-- V1.3
				WorkTel,						-- V1.3
				MobilePhone,					-- V1.3
				ManufacturerDealerCode,			-- V1.3
				ModelYear,						-- V1.3
				CustomerIdentifier,				-- V1.3
				OwnershipCycle,					-- V1.3
				OutletPartyID,					-- V1.3
				GDDDealerCode,					-- V1.3
				ReportingDealerPartyID,			-- V1.3
				VariantID,						-- V1.3
				ModelVariant,					-- V1.3
				SelectionDate,					-- V1.3
				CampaignID,						-- V1.3
				EmailSignator,					-- V1.3
				EmailSignatorTitle,				-- V1.3
				EmailContactText,				-- V1.3
				EmailCompanyDetails,			-- V1.3
				JLRCompanyname,					-- V1.3
				NSCFlag,						-- V1.3
				JLREventType,					-- V1.4	
				DealerType,						-- V1.7
				Queue,							-- V1.8
				EventID,						-- V1.9
				EngineType,						-- V1.9
				SVOvehicle						-- V1.10
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
				S.EmployeeCode,			
				S.EmployeeName,			
				S.ITYPE,					
				S.PilotCode,
				S.BilingualFlag,				-- V1.1
				S.langBilingual,				-- V1.1
				S.DearNameBilingual,			-- V1.1
				S.EmailSignatorTitleBilingual,	-- V1.1
				S.EmailContactTextBilingual,	-- V1.1
				S.EmailCompanyDetailsBilingual,	-- V1.1
				REPLACE(S.VIN , CHAR(9), '') AS VIN,										-- V1.3
				REPLACE(CONVERT(VARCHAR(10), S.EventDate, 102), '.', '-') AS EventDate,		-- V1.3
				S.DealerCode,																-- V1.3
				REPLACE(S.Telephone, CHAR(9), '') AS Telephone,								-- V1.3
				REPLACE(S.WorkTel, CHAR(9), '') AS WorkTel,									-- V1.3
				REPLACE(S.MobilePhone, CHAR(9), '') AS MobilePhone,							-- V1.3
				S.ManufacturerDealerCode,													-- V1.3
				S.ModelYear,																-- V1.3
				REPLACE(S.CustomerIdentifier, CHAR(9), '') AS CustomerIdentifier,			-- V1.3
				S.OwnershipCycle,															-- V1.3
				S.OutletPartyID,															-- V1.3
				S.GDDDealerCode,															-- V1.3
				S.ReportingDealerPartyID,													-- V1.3
				S.VariantID,																-- V1.3
				S.ModelVariant,																-- V1.3
				--CONVERT (NVARCHAR(10), @dtCATI, 121) AS SelectionDate,					-- V1.3
				CONVERT (NVARCHAR(10), CS.[CreationDate], 121) AS SelectionDate,			-- V1.5	
				CONVERT(NVARCHAR(100), CONVERT(VARCHAR(10), ISNULL(S.etype, '')) + '_'
					+ CASE WHEN ISNULL(S.ITYPE, '') = '' THEN 'blank'
						   ELSE S.ITYPE END + '_' 
					+ CONVERT(VARCHAR(10), ISNULL(S.ccode, '')) + '_'
					+ CASE WHEN S.manuf = 2 THEN 'J'
						   WHEN S.manuf = 3 THEN 'L'
						   ELSE 'UknownManufacturer' END + '_' 
					+ CONVERT(VARCHAR(10), ISNULL(S.lang, ''))) AS CampaignId, 				-- V1.3
				REPLACE(S.EmailSignator, CHAR(10), '<br/>') AS EmailSignator,				-- V1.3			
				REPLACE(S.EmailSignatorTitle, CHAR(10), '<br/>') AS EmailSignatorTitle,		-- V1.3
				REPLACE(S.EmailContactText, CHAR(10), '<br/>') AS EmailContactText,			-- V1.3
				REPLACE(S.EmailCompanyDetails, CHAR(10), '<br/>') AS EmailCompanyDetails,	-- V1.3
				REPLACE(S.JLRCompanyname, CHAR(10), '<br/>') AS JLRCompanyname,				-- V1.3
				ISNULL(M.SelectionOutput_NSCFlag, 'N') AS NSCFlag,							-- V1.3
				S.JLREventType,																-- V1.4
				S.DealerType,																-- V1.7
				S.Queue,																	-- V1.8
				S.EventID,																	-- V1.9
				S.EngineType,																-- V1.9
				S.SVOvehicle																-- V1.10
			FROM #OutputtedSelections O
				INNER JOIN SelectionOutput.OnlineOutput S ON O.CaseID = S.[ID]
															AND O.PartyID = S.PartyID
				INNER JOIN Event.Cases CS ON S.ID = CS.CaseID								-- V1.5
				LEFT JOIN dbo.Markets M ON M.CountryID = S.ccode							-- V1.3
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