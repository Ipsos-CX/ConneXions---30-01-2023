CREATE PROCEDURE [SelectionOutput].[uspAuditAllIAssistanceOutput]
	@FileName VARCHAR (255),
	@RussiaOutput INTEGER = 0		-- V1.6
AS

/*
	Date		Author			Version		Description
	----		------			-------		-----------
	2018-11-03	Chris Ledger	1.0			Orginal version
	2019-09-12	Chris Ledger	1.1			BUG 15571 - Separate Russia Output
	2021-05-27	Chris Ledger	1.2			Tidy formatting
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
				@dtCATI	DATETIME
    
		SET		@NOW = GETDATE()	
		SET		@dtCATI	= DATEADD(week, DATEDIFF(day, 0, @NOW)/7, 4)
		
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
		WHERE ET.EventCategory = 'I-Assistance'
			AND ((@RussiaOutput = 1 AND ISNULL(O.CTRY,'') = 'Russian Federation') OR  (@RussiaOutput = 0 AND ISNULL(O.CTRY,'') <> 'Russian Federation'))	-- V1.1
		
		
		-- get the RowCount
		SET @RowCount = (SELECT COUNT(*) FROM #OutputtedSelections)

		IF @RowCount > 0
		BEGIN
		
			EXEC SelectionOutput.uspAudit @FileName, @RowCount, @Date, @AuditID OUTPUT
	
			-- CREATE A TEMP TABLE TO HOLD DEDUPED EVENTS
			DECLARE @DeDupedEvents TABLE(  
				EventID INT NULL,
				AuditItemID INT NULL,
				UNIQUE CLUSTERED (EventID)		
			)

			INSERT INTO @DeDupedEvents (EventID, AuditItemID)
			SELECT EventID, 
				MAX(AuditItemID) AS AuditItemID
			FROM [$(ETLDB)].IAssistance.IAssistanceEvents
			GROUP BY EventID
			
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
				VIN,
				EventDate,	
				SelectionDate,
				Telephone,
				WorkTel,
				MobilePhone,
				ModelSummary,
				EmailSignator,
				EmailSignatorTitle,
				EmailContactText,
				EmailCompanyDetails,
				JLRCompanyname,
				JLRPrivacyPolicy,		
				BilingualFlag,	
				langBilingual,
				DearNameBilingual,
				EmailSignatorTitleBilingual,
				EmailContactTextBilingual,
				EmailCompanyDetailsBilingual,
				JLRPrivacyPolicyBilingual,			
				IAssistanceProvider,
				IAssistanceCallID,
				IAssistanceCallStartDate,
				IAssistanceCallCloseDate,
				IAssistanceHelpdeskAdvisorName,
				IAssistanceHelpdeskAdvisorID,
				IAssistanceCallMethod
			)			
			SELECT DISTINCT
				O.AuditID, 
				O.AuditItemID, 
				(SELECT SelectionOutputTypeID FROM [$(AuditDB)].dbo.SelectionOutputTypes WHERE SelectionOutputType = 'All') AS SelectionOutputTypeID,
				S.PartyID,
				S.[ID],
				S.FullModel,
				S.Model,
				S.sType,
				REPLACE(S.CarReg, CHAR(9), '') AS CarReg,
				REPLACE(S.Title, CHAR(9), '') AS Title,
				REPLACE(S.Initial, CHAR(9), '') AS Initial,
				REPLACE(S.Surname, CHAR(9), '') AS Surname,
				REPLACE(S.Fullname, CHAR(9), '') AS Fullname,
				REPLACE(S.DearName, CHAR(9), '') AS DearName,
				REPLACE(S.CoName, CHAR(9), '') AS CoName,
				REPLACE(S.Add1, CHAR(9), '') AS Add1,
				REPLACE(S.Add2, CHAR(9), '') AS Add2,
				REPLACE(S.Add3, CHAR(9), '') AS Add3,
				REPLACE(S.Add4, CHAR(9), '') AS Add4,
				REPLACE(S.Add5, CHAR(9), '') AS Add5,
				REPLACE(S.Add6, CHAR(9), '') AS Add6,
				REPLACE(S.Add7, CHAR(9), '') AS Add7,
				REPLACE(S.Add8, CHAR(9), '') AS Add8,
				REPLACE(S.Add9, CHAR(9), '') AS Add9,
				S.CTRY,
				REPLACE(S.EmailAddress, CHAR(9), '') AS EmailAddress,
				ISNULL(S.dealer, '') AS Dealer,
				S.sno,
				S.ccode,
				CASE WHEN S.VIN LIKE '%I-Ass Unknown%' OR S.Model = 'Unknown Vehicle' THEN '99999' ELSE S.modelcode END AS modelcode,
				S.lang,
				S.manuf,
				S.gender,
				S.qver,
				S.blank,
				S.[etype],
				S.reminder,
				S.week,
				S.test, 
				S.SampleFlag,   
				S.SalesServiceFile,
				S.Expired,
				@Date AS DateOutput,
				S.ITYPE,
				REPLACE(S.VIN, CHAR(9), '') AS VIN,
				CAST(REPLACE(CONVERT(VARCHAR(10), S.EventDate, 102), '.', '-') AS VARCHAR(10)) AS EventDate, 
				CASE	WHEN S.Itype ='T' THEN  CONVERT(NVARCHAR(10), @dtCATI, 121)
						ELSE CONVERT(NVARCHAR(10), @NOW, 121) END AS SelectionDate,
				REPLACE(S.[Telephone],  CHAR(9), '') AS [Telephone],
				REPLACE(S.[WorkTel],  CHAR(9), '') AS [WorkTel],
				REPLACE(S.[MobilePhone],  CHAR(9), '') AS [MobilePhone],
				S.ModelSummary,    
				REPLACE(S.EmailSignator, CHAR(10), '<br/>') AS EmailSignator,					
				REPLACE(S.EmailSignatorTitle, CHAR(10), '<br/>') AS EmailSignatorTitle,	
				REPLACE(S.EmailContactText, CHAR(10), '<br/>') AS EmailContactText,	
				REPLACE(S.EmailCompanyDetails, CHAR(10), '<br/>') AS EmailCompanyDetails,
				REPLACE(S.JLRCompanyname, CHAR(10), '<br/>') AS JLRCompanyname,
				REPLACE(S.JLRPrivacyPolicy, CHAR(10), '<br/>') AS JLRPrivacyPolicy,
				S.BilingualFlag,
				S.langBilingual,			
				S.DearNameBilingual,		
				S.EmailSignatorTitleBilingual,
				S.EmailContactTextBilingual,
				S.EmailCompanyDetailsBilingual,
				S.JLRPrivacyPolicyBilingual,
				IAE.IAssistanceProvider,
				IAE.IAssistanceCallID,
				IAE.IAssistanceCallStartDate,
				IAE.IAssistanceCallCloseDate,
				IAE.IAssistanceHelpdeskAdvisorName,
				IAE.IAssistanceHelpdeskAdvisorID,
				IAE.IAssistanceCallMethod
			FROM #OutputtedSelections O
				INNER JOIN SelectionOutput.OnlineOutput S ON O.CaseID = S.[ID]
															AND O.PartyID = S.PartyID
				INNER JOIN Event.vwEventTypes ET ON ET.EventTypeID = S.[etype] 
													AND ET.EventCategory = 'I-Assistance' 	
				INNER JOIN Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = S.[ID] 
				INNER JOIN @DeDupedEvents DDE ON DDE.EventID = AEBI.EventID
				INNER JOIN [$(ETLDB)].IAssistance.IAssistanceEvents IAE ON IAE.AuditItemID = DDE.AuditItemID	
				LEFT JOIN SelectionOutput.ReoutputCases RE ON S.ID = RE.CaseID
			WHERE RE.CaseID IS NULL	
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