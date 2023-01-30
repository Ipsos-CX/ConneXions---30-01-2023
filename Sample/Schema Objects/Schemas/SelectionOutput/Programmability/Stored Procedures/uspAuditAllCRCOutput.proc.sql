CREATE PROCEDURE [SelectionOutput].[uspAuditAllCRCOutput]
	@FileName VARCHAR (255),
	@RussiaOutput INTEGER = 0		-- V1.7
AS
SET NOCOUNT ON

---------------------------------------------------------------------------------------------------
--	
--	Change History...
--	
--	Date		Author			Version		DesCription
--  ----		------			-------		-----------
--	27-04-2015	Chris Ross		1.0			Orginal version
--  31-03-2016	Chris Ross		1.1			BUG 12407: Add ITYPE and PilotCode into Audit.SelectionOutput and update CaseOutputTypeID 
--														statement to use first char only for comparison.  Also include SMS Check
--													   in CaseOutputTypeID statement.
--  24-08-2016  Eddie Thomas	1.2			BUG 12945: CRC - new selection output file layout required for On-line
--	18-10-2016  Chris Ledger	1.3			BUG 13235: Add SRNumber for CRC output 
--	24-10-2017	Chris Ledger	1.4			BUG 14245: Add BilingualFlag, langBilingual, DearNameBilingual, EmailSignatorTitleBilingual, EmailContactTextBilingual, EmailCompanyDetailsBilingual
--	19-11-2017	Eddie Thomas	1.5			BUG 14362: Re-output records to be output once a week 
--	15-08-2018	Chris Ledger	1.6			BUG 14751: Add extra fields
--	11-09-2019	Chris Ledger	1.7			BUG 15571: Separate Russia Output
--	26-03-2021	Eddie Thomas	1.8			BUG 18152: CRC New Global Agent table
--	27-05-2021	Chris Ledger	1.9			Tidy formatting
--	02-07-2021	Chris Ledger	1.10		Task 535: Add EventID
--	12-07-2021	Chris Ledger	1.11		Task 553: Set CRCOwnerCode as DisplayOnQuestionnaire and add CDSID field
--	20-07-2021	Chris Ledger	1.12		Task 558: Add EngineType
--	21-07-2021	Chris Ledger	1.13		Task 552: Add SVOvehicle
---------------------------------------------------------------------------------------------------

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
			@dtCATI	DATETIME	-- V1.6
    
		SET	@NOW = GETDATE()										-- V1.6
		SET	@dtCATI	= DATEADD(week, DATEDIFF(day, 0, @NOW)/7, 4)	-- V1.6
		
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
			CASE SUBSTRING(ITYPE,1,1)			-- V1.1
				WHEN 'H' THEN (SELECT CaseOutputTypeID FROM Event.CaseOutputTypes WHERE CaseOutputType = 'Online')
				WHEN 'T' THEN (SELECT CaseOutputTypeID FROM Event.CaseOutputTypes WHERE CaseOutputType = 'CATI')
				WHEN 'S' THEN (SELECT CaseOutputTypeID FROM Event.CaseOutputTypes WHERE CaseOutputType = 'SMS')		-- V1.1
				ELSE (SELECT CaseOutputTypeID FROM Event.CaseOutputTypes WHERE CaseOutputType = 'Postal')
			END AS CaseOutputTypeID
		FROM SelectionOutput.OnlineOutput O
			INNER JOIN Event.vwEventTypes ET ON ET.EventTypeID = O.etype		
		WHERE ET.EventCategory = 'CRC'
			AND ((@RussiaOutput = 1 AND ISNULL(O.CTRY,'') = 'Russian Federation') OR  (@RussiaOutput = 0 AND ISNULL(O.CTRY,'') <> 'Russian Federation'))	-- V1.7
		
		
		-- get the RowCount
		SET @RowCount = (SELECT COUNT(*) FROM #OutputtedSelections)

		IF @RowCount > 0
		BEGIN
		
			EXEC SelectionOutput.uspAudit @FileName, @RowCount, @Date, @AuditID OUTPUT
	
			-- CREATE A TEMP TABLE TO HOLD DEDUPED EVENTS
			CREATE TABLE #DeDuped_Events
			(
				EventID INT NULL,
				AuditItemID INT NULL
			)
		
			INSERT INTO #DeDuped_Events (EventID, AuditItemID)
				SELECT ODSEventID AS EventID, 
					MAX(AuditItemID)
				FROM [$(ETLDB)].CRC.CRCEvents
				GROUP BY ODSEventID
			
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
				ITYPE,							-- V1.1
				PilotCode,						-- V1.1
				Owner,							-- V1.2
				OwnerCode,						-- V1.2
				CRCCode,						-- V1.2
				MarketCode,						-- V1.2
				SampleYear,						-- V1.2
				VehicleMileage,					-- V1.2
				VehicleMonthsinService,			-- V1.2
				RowId,
				SRNumber,						-- V1.3
				BilingualFlag,					-- V1.4
				langBilingual,					-- V1.4
				DearNameBilingual,				-- V1.4
				EmailSignatorTitleBilingual,	-- V1.4
				EmailContactTextBilingual,		-- V1.4
				EmailCompanyDetailsBilingual,	-- V1.4
				VIN,							-- V1.6
				EventDate,						-- V1.6
				DealerCode,						-- V1.6
				Telephone,						-- V1.6
				WorkTel,						-- V1.6
				MobilePhone,					-- V1.6
				ManufacturerDealerCode,			-- V1.6
				ModelYear,						-- V1.6
				CustomerIdentifier,				-- V1.6
				OwnershipCycle,					-- V1.6
				OutletPartyID,					-- V1.6
				GDDDealerCode,					-- V1.6
				ReportingDealerPartyID,			-- V1.6
				VariantID,						-- V1.6
				ModelVariant,					-- V1.6
				SelectionDate,					-- V1.6
				CampaignID,						-- V1.6
				EmailSignator,					-- V1.6
				EmailSignatorTitle,				-- V1.6
				EmailContactText,				-- V1.6
				EmailCompanyDetails,			-- V1.6
				JLRCompanyname,					-- V1.6
				EmployeeCode,					-- V1.6
				EmployeeName,					-- V1.6
				PreferredLanguageID,			-- V1.6
				ClosedBy,						-- V1.6
				BrandCode,						-- V1.6
				EventID,						-- V1.10
				CDSID,							-- V1.11
				EngineType,						-- V1.12
				SVOvehicle						-- V1.13
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
				CASE WHEN S.VIN LIKE '%_CRC_Unknown_V' THEN '99999' ELSE S.modelcode END AS modelcode, 
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
				S.SalesServiceFile AS CRCsurveyfile,
				S.Expired,
				@Date AS DateOutput,
				S.ITYPE,					-- V1.1
				S.PilotCode,				-- V1.1
				----------------------------------------- V1.2-----------------------------------------
				--CASE	WHEN LK.CODE IS NOT NULL THEN LK.FirstName	-- WE'VE GOT A MATCH IN THE LOOKUP TABLE, USE IT. 
				--		WHEN LK.CODE IS NULL AND LEN(ISNULL(CRC.ClosedBy,'')) > 0 THEN LTRIM(RTRIM(CRC.ClosedBy))
				--		ELSE LTRIM(RTRIM(CRC.Owner)) END AS [Owner],
				COALESCE(LTRIM(RTRIM(CRC.Owner)), LTRIM(RTRIM(CRC.ClosedBy)), '') AS Owner,		-- V1.8
				CASE	WHEN LKO.CDSID IS NOT NULL THEN LKO.DisplayOnQuestionnaire				-- V1.11 WE'VE GOT A MATCH IN THE LOOKUP TABLE, USE IT. 
						WHEN LKF.CDSID IS NOT NULL THEN LKF.DisplayOnQuestionnaire				-- V1.11
						ELSE CRC.Owner END AS OwnerCode,
				CRC.CRCCode,
				CRC.MarketCode,
				YEAR (GetDate()) AS SampleYear,
				CRC.VehicleMileage,
				CRC.VehicleMonthsinService,
				CRC.RowId,
				----------------------------------------- V1.2-----------------------------------------
				CRC.CaseNumber AS SRNumber,		-- V1.3
				S.BilingualFlag,				-- V1.4
				S.langBilingual,				-- V1.4
				S.DearNameBilingual,			-- V1.4
				S.EmailSignatorTitleBilingual,	-- V1.4
				S.EmailContactTextBilingual,	-- V1.4
				S.EmailCompanyDetailsBilingual,	-- V1.4
				REPLACE(S.VIN , CHAR(9), '') AS VIN,															-- V1.6
				CAST(REPLACE(CONVERT(VARCHAR(10), S.EventDate, 102), '.', '-') AS VARCHAR(10)) AS EventDate,	-- V1.6
				S.DealerCode ,					-- V1.6
				'' AS Telephone,				-- V1.6
				'' AS WorkTel,					-- V1.6
				'' AS MobilePhone,				-- V1.6
				S.ManufacturerDealerCode,		-- V1.6
				S.ModelYear,					-- V1.6
				REPLACE(CRC.UniqueCustomerId, CHAR(9), '') AS CustomerIdentifier,			-- V1.6
				S.OwnershipCycle,				-- V1.6
				S.OutletPartyID,				-- V1.6
				S.GDDDealerCode,				-- V1.6
				S.ReportingDealerPartyID,		-- V1.6
				S.VariantID,					-- V1.6
				S.ModelVariant,					-- V1.6
				CASE	WHEN S.Itype ='T' THEN CONVERT(NVARCHAR(10), @dtCATI, 121)	
						ELSE CONVERT(NVARCHAR(10), @NOW, 121) END AS SelectionDate,			-- V1.6											
				CONVERT(NVARCHAR(100), CONVERT(VARCHAR(10), ISNULL(S.etype, '')) + '_'
				+ CASE WHEN ISNULL(S.ITYPE, '') = '' THEN 'blank'
					   ELSE S.ITYPE END + '_' 
				+ CONVERT(VARCHAR(10), ISNULL(S.ccode, '')) + '_'
				+ CASE WHEN S.manuf = 2 THEN 'J'
					   WHEN S.manuf = 3 THEN 'L'
					   ELSE 'UknownManufaCturer' END + '_' 
				+ CONVERT(VARCHAR(10), ISNULL(S.lang, ''))) AS CampaignId, 					-- V1.6				
				REPLACE(S.EmailSignator, CHAR(10), '<br/>') AS EmailSignator,				-- V1.6					
				REPLACE(S.EmailSignatorTitle, CHAR(10), '<br/>') AS EmailSignatorTitle,		-- V1.6	
				REPLACE(S.EmailContactText, CHAR(10), '<br/>') AS EmailContactText,			-- V1.6	
				REPLACE(S.EmailCompanyDetails, CHAR(10), '<br/>') AS EmailCompanyDetails,	-- V1.6
				REPLACE(S.JLRCompanyname, CHAR(10), '<br/>') AS JLRCompanyname,				-- V1.6	
				S.EmployeeCode,					-- V1.6
				S.EmployeeName,					-- V1.6
				CRC.PreferredLanguageID,		-- V1.6
				CRC.ClosedBy,					-- V1.6
				CRC.BrandCode, 					-- V1.6
				S.EventID,						-- V1.10
				CASE	WHEN LKO.CDSID IS NOT NULL THEN LKO.CDSID							-- V1.11 WE'VE GOT A MATCH IN THE LOOKUP TABLE, USE IT. 
						WHEN LKF.CDSID IS NOT NULL THEN LKF.CDSID							-- V1.11
						ELSE CRC.Owner END AS CDSID,
				S.EngineType,																-- V1.12
				S.SVOvehicle																-- V1.13
		FROM #OutputtedSelections O
			INNER JOIN SelectionOutput.OnlineOutput S ON O.CaseID = S.[ID]
														AND O.PartyID = S.PartyID
			INNER JOIN Event.vwEventTypes AS ET ON ET.EventTypeID = S.etype 
													AND ET.EventCategory = 'CRC' 
			INNER JOIN Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = S.ID 
																	AND AEBI.PartyID = S.PartyID
			INNER JOIN #DeDuped_Events RED ON RED.EventID = AEBI.EventID
			INNER JOIN [$(ETLDB)].CRC.CRCEvents CRC ON CRC.AuditItemID = RED.AuditItemID
			LEFT JOIN dbo.Languages L ON L.LanguageID = CRC.PreferREDLanguageID
			LEFT JOIN ContactMechanism.Countries C ON C.ISOAlpha3 = CRC.MarketCode
			LEFT JOIN Markets M	ON M.CountryID = C.CountryID
			LEFT JOIN dbo.Regions R	ON R.regionID = M.RegionID
			LEFT JOIN [$(ETLDB)].Lookup.CRCAgents_GlobalList LKO ON LTRIM(RTRIM(CRC.Owner)) = LKO.CDSID 
																		AND CRC.MarketCode = LKO.MarketCode		-- V1.8
			--LEFT JOIN	[$(ETLDB)].Lookup.CRCAgents_GlobalList LKC ON LTRIM(RTRIM(CRC.ClosedBy)) = LKC.CDSID AND CRC.MarketCode = LKC.MarketCode  -- V1.8
			LEFT JOIN [$(ETLDB)].Lookup.CRCAgents_GlobalList LKF ON LTRIM(RTRIM(CRC.Owner)) = LKF.FullName 
																		AND CRC.MarketCode = LKF.MarketCode		-- V1.8
			LEFT JOIN SelectionOutput.ReoutputCases RE ON S.ID = RE.CaseID										-- V1.5
		WHERE RE.CaseID IS NULL		-- V1.5
		ORDER BY O.AuditItemID

		-- DROP TEMPORARY TABLE
		DROP TABLE #DeDuped_Events
		
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