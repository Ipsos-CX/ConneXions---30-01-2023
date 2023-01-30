
CREATE PROCEDURE [SelectionOutput].[uspAuditAllRoadsideOutput]
	@FileName VARCHAR (255),
	@RussiaOutput INTEGER = 0		-- V1.6
AS
SET NOCOUNT ON


---------------------------------------------------------------------------------------------------
--	
--	Change History...
--	
--	Date		Author		Version		Description
--  ----		------		-------		-----------
--	27-06-2012	Chris Ross	1.1			BUG 6940.  Corrected bug where checking for wrong ITYPE value 
--										to determine On-line in SelectionOutput.OnlineOutput file.
--										Should have been 'H' and not 'I'.
--  12-02-2012  Chris Ross  1.2			Change Password to PartyID and also add in fuinctionality to 
--										determine 'T' in IType field as CATI
--  31-03-2016	Chris Ross	1.3			BUG 12407: Add ITYPE and PilotCode into Audit.SelectionOutput and update CaseOutputTypeID 
--													statement to use first char only for comparison.  Also include SMS check
--												   in CaseOutputTypeID statement.
--	24-10-2017	Chris Ledger 1.4		BUG 14245: Add BilingualFlag, langBilingual, DearNameBilingual, EmailSignatorTitleBilingual, EmailContactTextBilingual, EmailCompanyDetailsBilingual
--  19-06-2018	Chris Ledger 1.5		BUG 14751: Add missing fields
--	11-09-2019	Chris Ledger 1.6		BUG 15571: Separate Russia Output
--	02-07-2021	Chris Ledger 1.7		TASK 535: Add EventID
--	20-07-2021	Chris Ledger 1.8		TASK 558: Add EngineType
--	21-07-2021	Chris Ledger 1.9		TASK 552: Add SVOvehicle
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
		@dtCATI	DATETIME	-- V1.5
    
		SET		@NOW = GETDATE()
		SET		@dtCATI	= DATEADD(WEEK, DATEDIFF(DAY, 0, @NOW)/7, 4) -- V1.5	
		
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
			CASE SUBSTRING(ITYPE, 1,1)				-- V1.3
				WHEN 'H' THEN (SELECT CaseOutputTypeID FROM Event.CaseOutputTypes WHERE CaseOutputType = 'Online')
				WHEN 'T' THEN (SELECT CaseOutputTypeID FROM Event.CaseOutputTypes WHERE CaseOutputType = 'CATI')
				WHEN 'S' THEN (SELECT CaseOutputTypeID FROM Event.CaseOutputTypes WHERE CaseOutputType = 'SMS')				-- V1.3
				ELSE (SELECT CaseOutputTypeID FROM Event.CaseOutputTypes WHERE CaseOutputType = 'Postal')
			END AS CaseOutputTypeID
		FROM SelectionOutput.OnlineOutput O
		INNER JOIN Event.vwEventTypes ET ON ET.EventTypeID = O.etype		
		WHERE ET.EventCategory = 'Roadside'
		AND ((@RussiaOutput = 1 AND ISNULL(O.CTRY,'') = 'Russian Federation') OR  (@RussiaOutput = 0 AND ISNULL(O.CTRY,'') <> 'Russian Federation'))	-- V1.6
		
		
		-- get the RowCount
		SET @RowCount = (SELECT COUNT(*) FROM #OutputtedSelections)

		IF @RowCount > 0
		BEGIN
		
			EXEC SelectionOutput.uspAudit @FileName, @RowCount, @Date, @AuditID OUTPUT


			----------------------------------------------------------------------------
			-- V1.5 Use Temporary Tables
			----------------------------------------------------------------------------
			CREATE TABLE #UnDeDupedEvents									
			(
				EventID INT NULL,
				AuditItemID INT NULL
			)

			INSERT INTO #UnDeDupedEvents (EventID, AuditItemID)
			SELECT AEBI.EventID, 
				RE.AuditItemID
			FROM SelectionOutput.OnlineOutput O
				INNER JOIN Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = O.ID 
				INNER JOIN [$(AuditDB)].Audit.Events AE ON AE.EventID = AEBI.EventID
				INNER JOIN [$(ETLDB)].Roadside.RoadsideEvents RE ON RE.AuditItemID = AE.AuditItemID
			UNION
			SELECT AEBI.EventID, 
				REP.AuditItemID
			FROM SelectionOutput.OnlineOutput O
				INNER JOIN Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = O.ID 
				INNER JOIN [$(AuditDB)].Audit.Events AE ON AE.EventID = AEBI.EventID
				INNER JOIN [$(ETLDB)].Roadside.RoadsideEventsProcessed REP ON REP.AuditItemID = AE.AuditItemID


			CREATE TABLE #DeDupedEvents									-- 1.5
			(
				EventID INT NULL,
				AuditItemID INT NULL
			)

			INSERT INTO #DeDupedEvents (EventID, AuditItemID)
			SELECT CE.EventID, 
				MAX(CE.AuditItemID)
			FROM #UnDeDupedEvents CE
			GROUP BY CE.EventID


			CREATE TABLE #RoadsideEventData
			(
				EventID INT NULL,
				BreakdownDate DATETIME2(7) NULL,
				BreakdownDateOrig NVARCHAR(4000) NULL,
				BreakdownCountry VARCHAR(50) NULL,
				BreakdownCountryID INT NULL,
				BreakdownCaseId NVARCHAR(4000) NULL,
				CarHireStartDate DATETIME2(7) NULL,
				CarHireStartDateOrig NVARCHAR(4000) NULL,
				ReasonForHire NVARCHAR(4000) NULL,
				HireGroupBranch NVARCHAR(4000) NULL,
				CarHireTicketNumber NVARCHAR(4000) NULL,
				HireJobNumber NVARCHAR(4000) NULL,
				RepairingDealer NVARCHAR(4000) NULL,
				DataSource NVARCHAR(4000) NULL,
				ReplacementVehicleMake NVARCHAR(4000) NULL,
				ReplacementVehicleModel NVARCHAR(4000) NULL,
				VehicleReplacementTime TIME(7) NULL,
				CarHireStartTime NVARCHAR(4000) NULL,
				ConvertedCarHireStartTime TIME(7) NULL,
				RepairingDealerCountry NVARCHAR(4000) NULL,
				RoadsideAssistanceProvider NVARCHAR(4000) NULL,
				BreakdownAttendingResource NVARCHAR(4000) NULL,
				CarHireProvider NVARCHAR(4000) NULL,
				CountryCodeISOAlpha2 NVARCHAR(4000) NULL,
				BreakdownCountryISOAlpha2 NVARCHAR(4000) NULL,
				DealerCode NVARCHAR(4000) NULL,
				VehicleOriginCountry NVARCHAR(4000) NULL
			)

						
			INSERT INTO #RoadsideEventData (EventID, BreakdownDate, BreakdownDateOrig, BreakdownCountry, BreakdownCountryID, BreakdownCaseId, CarHireStartDate, ReasonForHire,
						HireGroupBranch, CarHireTicketNumber, HireJobNumber, RepairingDealer, DataSource, ReplacementVehicleMake, ReplacementVehicleModel, VehicleReplacementTime,
						CarHireStartTime, ConvertedCarHireStartTime, RepairingDealerCountry, RoadsideAssistanceProvider, BreakdownAttendingResource, CarHireProvider,
						CountryCodeISOAlpha2, BreakdownCountryISOAlpha2, DealerCode, VehicleOriginCountry)
			SELECT 
				E.EventID,
				REP.BreakdownDate, 
				REP.BreakdownDateOrig,
				REP.BreakdownCountry, 
				REP.BreakdownCountryID, 
				REP.BreakdownCaseId, 
				REP.CarHireStartDate, 
				REP.ReasonForHire, 
				REP.HireGroupBranch, 
				REP.CarHireTicketNumber, 
				REP.HireJobNumber, 
				REP.RepairingDealer, 
				REP.DataSource,
				REP.ReplacementVehicleMake,
				REP.ReplacementVehicleModel,
				REP.VehicleReplacementTime,
				REP.CarHireStartTime,
				REP.ConvertedCarHireStartTime,
				REP.RepairingDealerCountry,
				REP.RoadsideAssistanceProvider,
				REP.BreakdownAttendingResource,
				REP.CarHireProvider,
				REP.CountryCodeISOAlpha2,
				REP.BreakdownCountryISOAlpha2,
				REP.DealerCode,
				REP.CountryCode AS VehicleOriginCountry
			FROM [$(ETLDB)].Roadside.RoadsideEventsProcessed REP
				INNER JOIN #DeDupedEvents E ON E.AuditItemID = REP.AuditItemID
				INNER JOIN [$(AuditDB)].Audit.Events AE ON REP.AuditItemID = AE.AuditItemID 
			UNION 
			SELECT 
				E.EventID,
				RE.BreakdownDate, 
				RE.BreakdownDateOrig,
				RE.BreakdownCountry, 
				RE.BreakdownCountryID, 
				RE.BreakdownCaseId, 
				RE.CarHireStartDate, 
				RE.ReasonForHire, 
				RE.HireGroupBranch, 
				RE.CarHireTicketNumber, 
				RE.HireJobNumber, 
				RE.RepairingDealer, 
				RE.DataSource,
				RE.ReplacementVehicleMake,
				RE.ReplacementVehicleModel,
				RE.VehicleReplacementTime,
				RE.CarHireStartTime,
				RE.ConvertedCarHireStartTime,
				RE.RepairingDealerCountry,
				RE.RoadsideAssistanceProvider,
				RE.BreakdownAttendingResource,
				RE.CarHireProvider,
				RE.CountryCodeISOAlpha2,
				RE.BreakdownCountryISOAlpha2,
				RE.DealerCode,
				RE.CountryCode AS VehicleOriginCountry
			FROM [$(ETLDB)].Roadside.RoadsideEvents RE
				INNER JOIN #DeDupedEvents E ON E.AuditItemID = RE.AuditItemID
				INNER JOIN [$(AuditDB)].Audit.Events AE ON RE.AuditItemID = AE.AuditItemID 
			----------------------------------------------------------------------------
			

			INSERT INTO [$(AuditDB)].Audit.SelectionOutput
			(
				[AuditID], 
				[AuditItemID], 
				[SelectionOutputTypeID], 
				[PartyID], 
				[CaseID], 
				[FullModel], 
				[Model], 
				[sType], 
				[CarReg], 
				[Title], 
				[Initial], 
				[Surname], 
				[Fullname], 
				[DearName], 
				[CoName], 
				[Add1], 
				[Add2], 
				[Add3], 
				[Add4], 
				[Add5], 
				[Add6], 
				[Add7], 
				[Add8], 
				[Add9], 
				[CTRY], 
				[EmailAddress], 
				[Dealer], 
				[sno], 
				[ccode], 
				[modelcode], 
				[lang], 
				[manuf], 
				[gender], 
				[qver], 
				[blank], 
				[etype], 
				[reminder], 
				[week], 
				[test], 
				[SampleFlag], 
				[SalesServiceFile],
				[Expired],
				[DateOutput],
				ITYPE,							-- V1.3
				PilotCode,						-- V1.3
				BilingualFlag,					-- V1.4
				langBilingual,					-- V1.4
				DearNameBilingual,				-- V1.4
				EmailSignatorTitleBilingual,	-- V1.4
				EmailContactTextBilingual,		-- V1.4
				EmailCompanyDetailsBilingual,	-- V1.4
				BreakdownDate,					-- V1.5
				BreakdownCountry,				-- V1.5
				BreakdownCountryID,				-- V1.5
				BreakdownCaseId,				-- V1.5
				CarHireStartDate,				-- V1.5
				ReasonForHire,					-- V1.5
				HireGroupBranch,				-- V1.5
				CarHireTicketNumber,			-- V1.5
				HireJobNumber,					-- V1.5
				RepairingDealer,				-- V1.5
				DataSource,						-- V1.5
				ReplacementVehicleMake,			-- V1.5
				ReplacementVehicleModel,		-- V1.5
				CarHireStartTime,				-- V1.5
				ConvertedCarHireStartTime,		-- V1.5
				RepairingDealerCountry,			-- V1.5
				RoadsideAssistanceProvider,		-- V1.5
				BreakdownAttendingResource,		-- V1.5
				CarHireProvider,				-- V1.5
				VIN,							-- V1.5
				VehicleOriginCountry,			-- V1.5
				EmailSignator,					-- V1.5
				EmailSignatorTitle,				-- V1.5
				EmailContactText,				-- V1.5
				EmailCompanyDetails,			-- V1.5
				JLRCompanyname,					-- V1.5
				SelectionDate,					-- V1.5
				Telephone,						-- V1.5
				WorkTel,						-- V1.5
				MobilePhone,					-- V1.5
				ModelSummary,					-- V1.5
				EventID,						-- V1.7
				EngineType,						-- V1.8
				SVOvehicle						-- V1.9
			)
			SELECT DISTINCT
				O.[AuditID], 
				O.[AuditItemID], 
				(SELECT SelectionOutputTypeID FROM [$(AuditDB)].dbo.SelectionOutputTypes WHERE SelectionOutputType = 'All') AS [SelectionOutputTypeID],
				S.[PartyID], 
				S.[ID] AS [CaseID], 
				S.[FullModel], 
				S.[Model], 
				S.[sType], 
				S.[CarReg], 
				S.[Title], 
				S.[Initial], 
				S.[Surname], 
				S.[Fullname], 
				S.[DearName], 
				S.[CoName], 
				S.[Add1], 
				S.[Add2], 
				S.[Add3], 
				S.[Add4], 
				S.[Add5], 
				S.[Add6], 
				S.[Add7], 
				S.[Add8], 
				S.[Add9], 
				S.[CTRY], 
				S.[EmailAddress], 
				S.[Dealer], 
				S.[sno], 
				S.[ccode], 
				S.[modelcode], 
				S.[lang], 
				S.[manuf], 
				S.[gender], 
				S.[qver], 
				S.[blank], 
				S.[etype], 
				S.[reminder], 
				S.[week], 
				S.[test], 
				S.[SampleFlag], 
				S.[SalesServiceFile],
				S.[Expired],
				@Date,	
				ITYPE,							-- V1.3
				PilotCode,						-- V1.3
				S.BilingualFlag,				-- V1.4
				S.langBilingual,				-- V1.4
				S.DearNameBilingual,			-- V1.4
				S.EmailSignatorTitleBilingual,	-- V1.4
				S.EmailContactTextBilingual,	-- V1.4
				S.EmailCompanyDetailsBilingual,	-- V1.4
				RED.BreakdownDate,																		-- V1.5
				COALESCE(RED.BreakdownCountryISOAlpha2, RED.BreakdownCountry) AS BreakdownCountry,		-- V1.5
				RED.BreakdownCountryID, 																-- V1.5
				REPLACE(RED.BreakdownCaseId, CHAR(9), '') AS BreakdownCaseId,							-- V1.5
				REPLACE(RED.CarHireStartDate, CHAR(9), '') AS CarHireStartDate,							-- V1.5
				REPLACE(RED.ReasonForHire, CHAR(9), '') AS ReasonForHire,								-- V1.5
				REPLACE(RED.HireGroupBranch, CHAR(9), '') AS HireGroupBranch,							-- V1.5
				REPLACE(RED.CarHireTicketNumber, CHAR(9), '') AS CarHireTicketNumber,					-- V1.5
				REPLACE(RED.HireJobNumber, CHAR(9), '') AS HireJobNumber,								-- V1.5
				REPLACE(RED.RepairingDealer, CHAR(9), '') AS RepairingDealer,							-- V1.5
				REPLACE(RED.DataSource,  CHAR(9), '') AS DataSource,									-- V1.5
				REPLACE(RED.ReplacementVehicleMake, CHAR(9), '') AS ReplacementVehicleMake,				-- V1.5
				REPLACE(RED.ReplacementVehicleModel, CHAR(9), '') AS ReplacementVehicleModel,			-- V1.5
				REPLACE(RED.CarHireStartTime,  CHAR(9), '') AS CarHireStartTime,						-- V1.5
				RED.ConvertedCarHireStartTime,															-- V1.5
				REPLACE(RED.RepairingDealerCountry, CHAR(9), '') AS RepairingDealerCountry,				-- V1.5
				REPLACE(RED.RoadsideAssistanceProvider, CHAR(9), '') AS RoadsideAssistanceProvider,		-- V1.5
				REPLACE(RED.BreakdownAttendingResource, CHAR(9), '') AS BreakdownAttendingResource,		-- V1.5
				REPLACE(RED.CarHireProvider, CHAR(9), '') AS CarHireProvider,							-- V1.5
				REPLACE(S.VIN, CHAR(9), '') AS VIN,														-- V1.5
				REPLACE(RED.VehicleOriginCountry, CHAR(9), '') AS VehicleOriginCountry,					-- V1.5
				REPLACE(S.EmailSignator, CHAR(10), '<br/>') AS EmailSignator,							-- V1.5					
				REPLACE(S.EmailSignatorTitle, CHAR(10), '<br/>') AS EmailSignatorTitle,					-- V1.5	
				REPLACE(S.EmailContactText, CHAR(10), '<br/>') AS EmailContactText,						-- V1.5	
				REPLACE(S.EmailCompanyDetails, CHAR(10), '<br/>') AS EmailCompanyDetails,				-- V1.5
                REPLACE(S.JLRCompanyname, CHAR(10), '<br/>') AS JLRCompanyname,							-- V1.5
				CASE	WHEN S.Itype ='T' THEN  CONVERT(NVARCHAR(10), @dtCATI, 121) 
				        ELSE CONVERT(NVARCHAR(10), @NOW, 121) END AS SelectionDate,						-- V1.5
				REPLACE(S.Telephone,  CHAR(9), '') AS Telephone,										-- V1.5
				REPLACE(S.WorkTel,  CHAR(9), '') AS WorkTel,											-- V1.5
				REPLACE(S.MobilePhone,  CHAR(9), '') AS MobilePhone,									-- V1.5
				S.ModelSummary,																			-- V1.5
				S.EventID,																				-- V1.7
				S.EngineType,																			-- V1.8
				S.SVOvehicle																			-- V1.9
			FROM #OutputtedSelections O
				INNER JOIN SelectionOutput.OnlineOutput S ON O.CaseID = S.[ID]
													AND O.PartyID = S.PartyID
				INNER JOIN Event.vwEventTypes ET ON ET.EventTypeID = S.etype							-- V1.5
				INNER JOIN Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = S.ID 				-- V1.5
				INNER JOIN #RoadsideEventData RED ON RED.EventID = AEBI.EventID							-- V1.5
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