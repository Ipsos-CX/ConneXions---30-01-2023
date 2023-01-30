CREATE PROCEDURE [SelectionOutput].[uspAuditAllGeneralEnquiryOutput]
	@FileName VARCHAR (255),
	@RussiaOutput INTEGER = 0
AS
SET NOCOUNT ON

---------------------------------------------------------------------------------------------------
--	
--	Change History...
--	
--	Date		Author			Version		DesCription
--  ----		------			-------		-----------
--	06-07-2021	Eddie Thomas	1.0			Orginal version
--	12-07-2021	Chris Ledger	1.1			TASK 553: Set CRCOwnerCode as DisplayOnQuestionnaire and add CDSID field
--	20-07-2021	Chris Ledger	1.2			TASK 558: Add EngineType
--	20-07-2021	Chris Ledger	1.3			TASK 552: Add SVOvehicle
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
			@dtCATI	DATETIME	
    
		SET	@NOW = GETDATE()										
		SET	@dtCATI	= DATEADD(week, DATEDIFF(day, 0, @NOW)/7, 4)	
		
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
			CASE SUBSTRING(ITYPE,1,1)			
				WHEN 'H' THEN (SELECT CaseOutputTypeID FROM Event.CaseOutputTypes WHERE CaseOutputType = 'Online')
				WHEN 'T' THEN (SELECT CaseOutputTypeID FROM Event.CaseOutputTypes WHERE CaseOutputType = 'CATI')
				WHEN 'S' THEN (SELECT CaseOutputTypeID FROM Event.CaseOutputTypes WHERE CaseOutputType = 'SMS')		
				ELSE (SELECT CaseOutputTypeID FROM Event.CaseOutputTypes WHERE CaseOutputType = 'Postal')
			END AS CaseOutputTypeID
		FROM SelectionOutput.OnlineOutput O
			INNER JOIN Event.vwEventTypes ET ON ET.EventTypeID = O.etype		
		WHERE ET.EventCategory = 'CRC General Enquiry'
			AND ((@RussiaOutput = 1 AND ISNULL(O.CTRY,'') = 'Russian Federation') OR  (@RussiaOutput = 0 AND ISNULL(O.CTRY,'') <> 'Russian Federation'))
		
		
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
				FROM [$(ETLDB)].GeneralEnquiry.GeneralEnquiryEvents
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
				ITYPE,
				PilotCode,						
				Owner,							
				OwnerCode,						
				CRCCode,						
				MarketCode,						
				SampleYear,						
				VehicleMileage,					
				VehicleMonthsinService,			
				RowId,
				SRNumber,						
				BilingualFlag,					
				langBilingual,					
				DearNameBilingual,				
				EmailSignatorTitleBilingual,	
				EmailContactTextBilingual,		
				EmailCompanyDetailsBilingual,	
				VIN,							
				EventDate,						
				DealerCode,						
				Telephone,						
				WorkTel,						
				MobilePhone,					
				ManufacturerDealerCode,			
				ModelYear,						
				CustomerIdentifier,				
				OwnershipCycle,					
				OutletPartyID,					
				GDDDealerCode,					
				ReportingDealerPartyID,			
				VariantID,						
				ModelVariant,					
				SelectionDate,					
				CampaignID,						
				EmailSignator,					
				EmailSignatorTitle,				
				EmailContactText,				
				EmailCompanyDetails,			
				JLRCompanyname,					
				EmployeeCode,					
				EmployeeName,					
				PreferredLanguageID,			
				ClosedBy,						
				BrandCode,						
				EventID,
				CDSID,						-- V1.1
				EngineType,					-- V1.2
				SVOvehicle					-- V1.3
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
				S.SalesServiceFile AS GeneralEnquirysurveyfile,
				S.Expired,
				@Date AS DateOutput,
				S.ITYPE,					
				S.PilotCode,				
				COALESCE(LTRIM(RTRIM(CRC.EmployeeResponsibleName)), LTRIM(RTRIM(CRC.Owner)), LTRIM(RTRIM(CRC.ClosedBy)), '') AS Owner,				-- V1.1
				CASE	WHEN LKO.CDSID IS NOT NULL THEN LKO.DisplayOnQuestionnaire				-- V1.1
						WHEN LKF.CDSID IS NOT NULL THEN LKF.DisplayOnQuestionnaire				-- V1.1
						ELSE COALESCE(LTRIM(RTRIM(CRC.EmployeeResponsibleName)), LTRIM(RTRIM(CRC.Owner)), '') END AS OwnerCode,						-- V1.1
				CRC.CRCCentreCode  AS CRCCode,
				CRC.MarketCode,
				YEAR (GetDate()) AS SampleYear,
				CRC.VehicleMileage,
				CRC.VehicleMonthsinService,
				CRC.RowId,
				CRC.CaseNumber AS SRNumber,		
				S.BilingualFlag,				
				S.langBilingual,				
				S.DearNameBilingual,			
				S.EmailSignatorTitleBilingual,	
				S.EmailContactTextBilingual,	
				S.EmailCompanyDetailsBilingual,	
				REPLACE(S.VIN , CHAR(9), '') AS VIN,															
				CAST(REPLACE(CONVERT(VARCHAR(10), S.EventDate, 102), '.', '-') AS VARCHAR(10)) AS EventDate,	
				S.DealerCode ,					
				'' AS Telephone,				
				'' AS WorkTel,					
				'' AS MobilePhone,				
				S.ManufacturerDealerCode,		
				S.ModelYear,					
				REPLACE(CRC.UniqueCustomerId, CHAR(9), '') AS CustomerIdentifier,			
				S.OwnershipCycle,				
				S.OutletPartyID,				
				S.GDDDealerCode,				
				S.ReportingDealerPartyID,		
				S.VariantID,					
				S.ModelVariant,					
				CASE	WHEN S.Itype ='T' THEN CONVERT(NVARCHAR(10), @dtCATI, 121)	
						ELSE CONVERT(NVARCHAR(10), @NOW, 121) END AS SelectionDate,														
				CONVERT(NVARCHAR(100), CONVERT(VARCHAR(10), ISNULL(S.etype, '')) + '_'
				+ CASE WHEN ISNULL(S.ITYPE, '') = '' THEN 'blank'
					   ELSE S.ITYPE END + '_' 
				+ CONVERT(VARCHAR(10), ISNULL(S.ccode, '')) + '_'
				+ CASE WHEN S.manuf = 2 THEN 'J'
					   WHEN S.manuf = 3 THEN 'L'
					   ELSE 'UknownManufaCturer' END + '_' 
				+ CONVERT(VARCHAR(10), ISNULL(S.lang, ''))) AS CampaignId, 									
				REPLACE(S.EmailSignator, CHAR(10), '<br/>') AS EmailSignator,									
				REPLACE(S.EmailSignatorTitle, CHAR(10), '<br/>') AS EmailSignatorTitle,			
				REPLACE(S.EmailContactText, CHAR(10), '<br/>') AS EmailContactText,				
				REPLACE(S.EmailCompanyDetails, CHAR(10), '<br/>') AS EmailCompanyDetails,	
				REPLACE(S.JLRCompanyname, CHAR(10), '<br/>') AS JLRCompanyname,					
				S.EmployeeCode,					
				S.EmployeeName,					
				CRC.PreferredLanguageID,		
				CRC.ClosedBy,					
				CRC.BrandCode, 					
				S.EventID,
				CASE	WHEN LKO.CDSID IS NOT NULL THEN LKO.CDSID							-- V1.1 
						WHEN LKF.CDSID IS NOT NULL THEN LKF.CDSID							-- V1.1
						ELSE CRC.EmployeeResponsibleName END AS CDSID,						-- V1.1
				S.EngineType,																-- V1.2
				S.SVOvehicle																-- V1.3
			FROM #OutputtedSelections O
			INNER JOIN SelectionOutput.OnlineOutput S ON O.CaseID = S.[ID]
														AND O.PartyID = S.PartyID
			INNER JOIN Event.vwEventTypes AS ET ON ET.EventTypeID = S.etype 
													AND ET.EventCategory = 'CRC General Enquiry' 
			INNER JOIN Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = S.ID 
																	AND AEBI.PartyID = S.PartyID
			INNER JOIN #DeDuped_Events RED ON RED.EventID = AEBI.EventID
			INNER JOIN [$(ETLDB)].GeneralEnquiry.GeneralEnquiryEvents CRC ON CRC.AuditItemID = RED.AuditItemID
			LEFT JOIN dbo.Languages L ON L.LanguageID = CRC.PreferREDLanguageID
			LEFT JOIN ContactMechanism.Countries C ON C.ISOAlpha3 = CRC.MarketCode
			LEFT JOIN Markets M	ON M.CountryID = C.CountryID
			LEFT JOIN dbo.Regions R	ON R.regionID = M.RegionID
			LEFT JOIN [$(ETLDB)].Lookup.CRCAgents_GlobalList LKO ON COALESCE(LTRIM(RTRIM(CRC.EmployeeResponsibleName)), LTRIM(RTRIM(CRC.Owner)), '') = LKO.CDSID		-- V1.1
																		AND CRC.MarketCode = LKO.MarketCode
			LEFT JOIN [$(ETLDB)].Lookup.CRCAgents_GlobalList LKF ON COALESCE(LTRIM(RTRIM(CRC.EmployeeResponsibleName)), LTRIM(RTRIM(CRC.Owner)), '') = LKF.FullName		-- V1.1
																		AND CRC.MarketCode = LKF.MarketCode
			LEFT JOIN SelectionOutput.ReoutputCases RE ON S.ID = RE.CaseID
		WHERE RE.CaseID IS NULL
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