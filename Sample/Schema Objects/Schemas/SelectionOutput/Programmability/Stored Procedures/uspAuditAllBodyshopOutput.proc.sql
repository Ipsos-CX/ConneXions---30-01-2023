CREATE PROCEDURE [SelectionOutput].[uspAuditAllBodyshopOutput]
@FileName VARCHAR (255), @RussiaOutput INTEGER = 0		-- V1.11
AS
/*
	Purpose:	Audit the all Bodyshop output for online
	
	Version			Date			Developer			Comment
	-------			----			---------			-------
	1.0				16-08-2017		Eddie Thomas		Original version.  BUG 14141. 
	1.9				24-10-2017		Chris Ledger		BUG 14245: Add BilingualFlag, langBilingual, DearNameBilingual, EmailSignatorTitleBilingual, EmailContactTextBilingual, EmailCompanyDetailsBilingual
	1.10			15-06-2018		Chris Ledger		BUG 14751: Add extra columns
	1.11			16-09-2019		Chris Ledger		BUG 15571: Separate Russia Output
	1.12			27-05-2021		Chris Ledger		Tidy formatting
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
				@dtCATI	DATETIME	-- V1.12
	    
		SET	@NOW = GETDATE()
		SET	@dtCATI	= DATEADD(week, DATEDIFF(day, 0, @NOW)/7, 4) -- V1.12
		
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
												AND ET.EventCategory = 'Bodyshop'
		WHERE ((@RussiaOutput = 1 AND ISNULL(O.CTRY,'') = 'Russian Federation') OR  (@RussiaOutput = 0 AND ISNULL(O.CTRY,'') <> 'Russian Federation'))	-- V1.11
		
		
		
		-- get the RowCount
		SET @RowCount = (SELECT COUNT(*) FROM #OutputtedSelections)

		IF @RowCount > 0
		BEGIN
		
			EXEC SelectionOutput.uspAudit @FileName, @RowCount, @Date, @AuditID OUTPUT
			
			INSERT INTO [$(Sample_Audit)].Audit.SelectionOutput
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
				FOBCode,
				UnknownLang,
				BilingualFlag,					-- V1.9
				DearNameBilingual,				-- V1.9
				langBilingual,					-- V1.9
				EmailSignatorTitleBilingual,	-- V1.9
				EmailContactTextBilingual,		-- V1.9
				EmailCompanyDetailsBilingual,	-- V1.9
				VIN,							-- V1.10
				EventDate,						-- V1.10
				DealerCode,						-- V1.10
				Telephone,						-- V1.10
				WorkTel,						-- V1.10
				MobilePhone,					-- V1.10
				ManufacturerDealercode,			-- V1.10
				ModelYear,						-- V1.10
				CustomerIdentifier,				-- V1.10
				OwnershipCycle,					-- V1.10
				OutletPartyID,					-- V1.10
				GDDDealerCode,					-- V1.10
				ReportingDealerPartyID,			-- V1.10
				VariantID,						-- V1.10
				ModelVariant,					-- V1.10
				SelectionDate,					-- V1.10
				CampaignID,						-- V1.10
				EmailSignator,					-- V1.10
				EmailSignatorTitle,				-- V1.10
				EmailContactText,				-- V1.10
				EmailCompanyDetails,			-- V1.10
				JLRCompanyname,					-- V1.10
				RockarDealer,					-- V1.10
				SVOvehicle,						-- V1.10
				SVODealer,						-- V1.10
				RepairOrderNumber				-- V1.10
			)
			SELECT DISTINCT
				O.AuditID, 
				O.AuditItemID, 
				(SELECT SelectionOutputTypeID FROM [$(Sample_Audit)].dbo.SelectionOutputTypes WHERE SelectionOutputType = 'All') AS SelectionOutputTypeID,
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
				S.EmployeeCode,					-- V1.5
				S.EmployeeName,					-- V1.5
				S.ITYPE,						-- V1.6
				S.Pilotcode,					-- V1.6
				S.FOBCode,						-- V1.8
				S.UnknownLang,					-- V1.8
				S.BilingualFlag,				-- V1.9
				S.langBilingual,				-- V1.9
				S.DearNameBilingual,			-- V1.9
				S.EmailSignatorTitleBilingual,	-- V1.9
				S.EmailContactTextBilingual,	-- V1.9
				S.EmailCompanyDetailsBilingual,	-- V1.9
				REPLACE(S.VIN , CHAR(9), '') AS VIN,											-- V1.10
				REPLACE(CONVERT(VARCHAR(10), S.EventDate, 102), '.', '-') AS EventDate,			-- V1.10
				S.DealerCode,																	-- V1.10
				REPLACE(S.Telephone , CHAR(9), '') AS Telephone,								-- V1.10
				REPLACE(S.WorkTel , CHAR(9), '') AS WorkTel,									-- V1.10
				REPLACE(S.MobilePhone , CHAR(9), '') AS MobilePhone,							-- V1.10
				S.ManufacturerDealerCode,														-- V1.10
				S.ModelYear,																	-- V1.10
				REPLACE(S.CustomerIdentifier , CHAR(9), '') AS CustomerIdentifier,				-- V1.10
				S.OwnershipCycle,																-- V1.10
				S.OutletPartyID,																-- V1.10
				S.GDDDealerCode,																-- V1.10
				S.ReportingDealerPartyID,														-- V1.10
				S.VariantID,																	-- V1.10
				S.ModelVariant,																	-- V1.10
				CASE	WHEN S.Itype ='T' THEN  CONVERT(NVARCHAR(10), @dtCATI, 121)
						ELSE CONVERT(NVARCHAR(10), @NOW, 121) END AS SelectionDate,				-- V1.10
				CONVERT(NVARCHAR(100), CONVERT(VARCHAR(10), ISNULL(S.etype, ''))
					+ '_' + CASE WHEN ISNULL(S.ITYPE, '') = '' THEN 'blank'
								 ELSE S.ITYPE END + '_' 
					+ CONVERT(VARCHAR(10), ISNULL(S.ccode, ''))
					+ '_' + CASE WHEN S.manuf = 2 THEN 'J'
								 WHEN S.manuf = 3 THEN 'L'
								 ELSE 'UnknownManufacturer'	END + '_' 
					+ CONVERT(VARCHAR(10), ISNULL(S.lang, ''))) AS CampaignId,					-- V1.10
				REPLACE(S.EmailSignator, CHAR(10), '<br/>') AS EmailSignator,					-- V1.10
				REPLACE(S.EmailSignatorTitle, CHAR(10), '<br/>') AS EmailSignatorTitle,			-- V1.10
				REPLACE(S.EmailContactText, CHAR(10), '<br/>') AS EmailContactText,				-- V1.10
				REPLACE(S.EmailCompanyDetails, CHAR(10), '<br/>') AS EmailCompanyDetails,		-- V1.10
				REPLACE(S.JLRCompanyname, CHAR(10), '<br/>') AS JLRCompanyname,					-- V1.10
				ISNULL(S.RockarDealer,0) AS RockarDealer,										-- V1.10
				ISNULL(S.SVOvehicle,0) As SVOvehicle,											-- V1.10
				ISNULL(S.SVODealer,0) AS SVODealer,												-- V1.10
				S.RepairOrderNumber																-- V1.10
			FROM #OutputtedSelections O
				INNER JOIN SelectionOutput.OnlineOutput S ON O.CaseID = S.[ID]
															AND O.PartyID = S.PartyID
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