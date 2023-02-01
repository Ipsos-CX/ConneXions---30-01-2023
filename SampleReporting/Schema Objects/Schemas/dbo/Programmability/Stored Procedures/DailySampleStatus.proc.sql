CREATE PROC dbo.DailySampleStatus

AS

/*	
		Version			Date			Developer			Comment
		-				05-02-2014		Ali Yuksel			Live version copied to the solution
LIVE	1.1				05-02-2014		Ali Yuksel			BUG 9972,9973  - DailyUncodedDealers report changed, excluded coded dealers after executing uspAddMissingDealersToEvents in the same job
LIVE	1.2				17-12-2014		Ali Yuksel			temproray table #T2 creation changed to solve project buliding issue
LIVE	1.3				10-10-2016		Ben King			BUG 13102 Add a VIN un-mached report tab to the daily report
LIVE	1.4				25-09-2017		Chris Ledger		Change Report to include everything loaded since last successful run rather than last day	
LIVE	1.5				17-10-2017		Chris Ledger		BUG 14242: Show FileLoadFailureShort instead of FileLoadFailureID	RELEASED LIVE: CL 2017-10-17
LIVE	1.6				10-09-2018		Chris Ledger		Change Report to correct logic for last successful run
LIVE	1.7				24-04-2019		Ben King			BUG 15326 - 
LIVE	1.8				23-07-2019		Chris Ledger		Add CQI to Selection Exclusions
LIVE	1.9				05-12-2019		Ben King			16783 - Capture caseIDs not output due to invite matrix
LIVE	1.10			15-01-2020		Chris Ledger 		BUG 15372 - Fix cases
LIVE	1.11			19-04-2021		Chris Ledger		Task 398 - Change check step for Sample Load and Selection job
LIVE	1.12			06-07-2021		Chris Ledger		Task 547 - Change selection logic to include CQI
LIVE	1.13			24-03-2022		Eddie Thomas		Task 839 - Add column EventsTooYoung
LIVE	1.14			19-04-2022		Chris Ledger		Task 851 - Tidy up CaseIDs not output due to invite matrix code
*/

BEGIN

--BK V5

	DECLARE @DateLastRun DATETIME

	SELECT  @DateLastRun = MAX(
		DATEADD(SECOND,
		((h.run_duration / 1000000) * 86400)
			+ (((h.run_duration - ((h.run_duration / 1000000)* 1000000)) / 10000) * 3600)
			+ (((h.run_duration - ((h.run_duration / 10000) * 10000)) / 100) * 60) + (h.run_duration - (h.run_duration / 100) * 100), 
		CAST(STR(h.run_date, 8, 0) AS DATETIME)
			+ CAST(STUFF(STUFF(RIGHT('000000'
			+ CAST (h.run_time AS VARCHAR(6)), 6), 5, 0, ':'), 3, 0, ':') AS DATETIME)))
	FROM msdb..sysjobhistory h
		INNER JOIN msdb..sysjobs j ON j.job_id = h.job_id
	WHERE h.step_name = 'Report Cases Not Output'		-- V1.11
		AND h.run_status = 1 
		AND j.name = N'Sample Load and Selection'


	DELETE FROM dbo.DailyFilesLoaded
	DELETE FROM dbo.DailySelections
	DELETE FROM dbo.DailyUncodedDealers
	TRUNCATE TABLE dbo.DailyUnMatchedVINs		-- V1.3
	TRUNCATE TABLE dbo.DailyBounceBack
	TRUNCATE TABLE dbo.CaseIDNotOutputRolling	--V1.9


	INSERT INTO dbo.DailyFilesLoaded (AuditID, FileName, FileRowCount, ActionDate, LoadSuccess, FileLoadFailure)				-- V1.5
	SELECT F.AuditID, 
		F.FileName, 
		F.FileRowCount, 
		F.ActionDate, 
		ICF.LoadSuccess, 
		FFR.FileFailureReasonShort AS FileLoadFailure	-- V1.5
	FROM [$(AuditDB)].dbo.Files F
		JOIN [$(AuditDB)].dbo.IncomingFiles ICF ON F.AuditID = ICF.AuditID
		LEFT JOIN [$(AuditDB)].dbo.FileFailureReasons FFR ON ICF.FileLoadFailureID = FFR.FileFailureID								-- V1.5
	WHERE F.ActionDate >= @DateLastRun	-- V1.4
		AND F.FileRowCount <> 0
		AND F.FileTypeID = 1


	UPDATE DF
	SET DF.[Events] = T1.[Events]
	FROM dbo.DailyFilesLoaded DF
		INNER JOIN (	SELECT DISTINCT COUNT(MatchedODSEventID) AS [Events], 
							AuditID 
						FROM [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging
						WHERE LoadedDate >= @DateLastRun	-- V1.4
						GROUP BY AuditID) T1 ON DF.AuditID = T1.AuditID

	UPDATE DF
	SET DF.[EventsTooYoung] = T1.[EventsTooYoung]
	FROM dbo.DailyFilesLoaded DF
		INNER JOIN (	SELECT DISTINCT COUNT(MatchedODSEventID) AS [EventsTooYoung],  
							AuditID															-- V1.13
						FROM [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging
						WHERE LoadedDate >= @DateLastRun									-- V1.4
							AND ISNULL(EventDateTooYoung,0) = 1
						GROUP BY AuditID) T1 ON DF.AuditID = T1.AuditID


	-- V1.7
	SELECT COUNT(AuditID) AS Removed, 
		AuditID
	INTO #Misaligned
	FROM [$(ETLDB)].Stage.Removed_Records_Staging_Tables
	GROUP BY AuditID


	UPDATE F
	SET F.MisalignedRemoved = M.Removed
	FROM dbo.DailyFilesLoaded F
		INNER JOIN #Misaligned M ON F.AuditID = M.AuditID


	CREATE TABLE #T2 (EventID BIGINT, AuditID BIGINT, CaseID INT NULL)

	INSERT INTO #T2 (EventID ,AuditID)
	SELECT DISTINCT AE.EventID, 
		F.AuditID 
	FROM [$(SampleDB)].Meta.CaseDetails CD
		INNER JOIN [$(SampleDB)].Event.Cases C ON CD.CaseID = C.CaseID
		INNER JOIN [$(AuditDB)].[Audit].[Events] AE ON CD.EventID = AE.EventID
		INNER JOIN [$(AuditDB)].dbo.AuditItems AI ON AE.AuditItemID = AI.AuditItemID
		INNER JOIN [$(AuditDB)].dbo.Files F ON AI.AuditID = F.AuditID
	WHERE C.CreationDate >= F.ActionDate


	UPDATE #T2
	SET CaseID = CD.CaseID
	FROM [$(SampleDB)].Meta.CaseDetails CD
	WHERE #T2.EventID = CD.EventID


	UPDATE DF
	SET Cases = T3.Cases
	FROM dbo.DailyFilesLoaded DF INNER JOIN (	SELECT COUNT(CaseID) AS Cases, 
													AuditID
												FROM #T2
												GROUP BY AuditID) T3 ON DF.AuditID = T3.AuditID


	UPDATE dbo.DailyFilesLoaded
	SET PercentSelected = (Cases*100/FileRowCount)


	INSERT INTO dbo.DailySelections(DateLastRun, RequirementID, Requirement, CaseCount, RejectionCount)
	SELECT SR.DateLastRun, 
		R.RequirementID, 
		R.Requirement, 
		SR.RecordsSelected, 
		SR.RecordsRejected 
	FROM [$(SampleDB)].Requirement.Requirements R
		JOIN [$(SampleDB)].Requirement.SelectionRequirements SR ON R.RequirementID = SR.RequirementID
	WHERE SR.DateLastRun >= @DateLastRun				-- V1.12
		--R.RequirementCreationDate > = @DateLastRun	-- V1.4
		--AND R.Requirement NOT LIKE '%enprecis%'		-- V1.12
		--AND R.Requirement NOT LIKE '%CQI%'			-- V1.12


	-- NEW DailyUncodedDealers
	INSERT INTO dbo.DailyUncodedDealers
	SELECT COUNT(AEPR.AuditItemID) AS NumberOfRecordsUncoded, 
		AEPR.DealerCode, 
		F.FileName, 
		CONVERT(VARCHAR(10), F.ActionDate, 103) AS ActionDate
	FROM [$(AuditDB)].[Audit].EventPartyRoles AEPR
		JOIN [$(AuditDB)].dbo.AuditItems AI ON AEPR.AuditItemID = AI.AuditItemID
		JOIN [$(AuditDB)].dbo.Files F ON AI.AuditID = F.AuditID
		LEFT JOIN [$(SampleDB)].[Event].EventPartyRoles EPR ON EPR.EventID = AEPR.EventID 
														AND EPR.RoleTypeID = AEPR.RoleTypeID
	WHERE AEPR.PartyID = 0 
		AND ActionDate >= @DateLastRun		-- V1.4
		AND EPR.EventID IS NULL
		AND F.FileTypeID = 1				-- Sample Files  
	GROUP BY AEPR.DealerCode, 
		F.FileName, 
		F.ActionDate
	ORDER BY F.FileName


	-- NEW DailyUnMatchedVINS
	INSERT INTO dbo.DailyUnMatchedVINs
	SELECT V.VIN, 
		V.ModelDescription, 
		F.FileName, 
		F.ActionDate
	FROM [$(AuditDB)].[Audit].Vehicles V
		JOIN [$(AuditDB)].dbo.AuditItems AI ON V.AuditItemID = AI.AuditItemID
		JOIN [$(AuditDB)].dbo.Files F ON AI.AuditID = F.AuditID
	WHERE LEN(V.VIN) > 0
		AND F.ActionDate  >= @DateLastRun		-- V1.4
		AND F.FileTypeID = 1					-- Sample Files
		AND (V.ModelID = 7 OR V.ModelID = 1)
	GROUP BY V.VIN, 
		V.ModelDescription, 
		F.FileName, 
		F.ActionDate
	ORDER BY F.ActionDate DESC


	-- NEW DailyBounceBack
	INSERT INTO dbo.DailyBounceBack (AuditID, FileName, FileRowCount, ActionDate)
	SELECT ICF.AuditID, 
		F.FileName,
		F.FileRowCount,
		F.ActionDate
	FROM [$(AuditDB)].dbo.IncomingFiles ICF
		INNER JOIN [$(AuditDB)].dbo.Files F ON F.AuditID = ICF.AuditID
	WHERE F.FileTypeID = 10
		AND F.FileName LIKE '%Bouncebacks%'
		AND F.ActionDate  >= @DateLastRun		-- V1.4
	ORDER BY F.ActionDate DESC


	-- V1.9, V1.14
	-- CASE IDS NOT OUTPUT FOR ONLINE DUE TO INVITE MATRIX MISMATCH
	;WITH CTE_BMQ (Brand, Market, Questionnaire, QuestionnaireRequirementID, ContactMethodologyType) AS 
	(
		SELECT BMQ.Brand, 
			BMQ.Market, 
			CASE WHEN BMQ.SelectionName LIKE '%CQI%' THEN 'CQI'
				 ELSE BMQ.Questionnaire END AS Questionnaire,
			BMQ.QuestionnaireRequirementID,
			CM.ContactMethodologyType
		FROM [$(SampleDB)].dbo.vwBrandMarketQuestionnaireSampleMetadata BMQ
			INNER JOIN [$(SampleDB)].SelectionOutput.ContactMethodologyTypes CM ON CM.ContactMethodologyTypeID = BMQ.ContactMethodologyTypeID
		WHERE BMQ.SampleLoadActive = 1		
			AND CM.ContactMethodologyType LIKE '%EMAIL%'
		GROUP BY BMQ.Brand, 
			BMQ.Market, 
			CASE WHEN BMQ.SelectionName LIKE '%CQI%' THEN 'CQI'
				 ELSE BMQ.Questionnaire END,
			BMQ.QuestionnaireRequirementID,
			CM.ContactMethodologyType
	)
	INSERT INTO dbo.CaseIDNotOutput (ReportDate, CaseID, Brand, Market, Questionnaire, CaseCreationDate, CaseIDLang)
	SELECT GETDATE() AS ReportDate,  
		CD.CaseID, 
		BMQ.Brand, 
		BMQ.Market, 
		BMQ.Questionnaire, 
		CS.CreationDate, 
		CASE WHEN BMQ.Market = 'Portugal' AND L.Language = 'Brazil - Portuguese' THEN 'Portugal - Portuguese'
			 WHEN BMQ.Market = 'Mexico' AND L.Language = 'Spain - Spanish' THEN 'Portugal - Portuguese'
			 ELSE L.Language END AS [Language]
	FROM [$(SampleDB)].Meta.CaseDetails CD
		INNER JOIN [$(SampleDB)].dbo.Languages L ON L.LanguageID = CD.LanguageID
		INNER JOIN [$(SampleDB)].Event.Cases CS ON CD.CaseID = CS.CaseID
		INNER JOIN CTE_BMQ BMQ ON CD.QuestionnaireRequirementID = BMQ.QuestionnaireRequirementID
		LEFT JOIN [$(SampleDB)].SelectionOutput.OnlineEmailContactDetails ECD ON BMQ.Brand = ECD.Brand
																			AND BMQ.Market = ECD.Market
																			AND BMQ.Questionnaire = ECD.Questionnaire
																			AND CASE WHEN BMQ.Market = 'Portugal' AND L.Language = 'Brazil - Portuguese' THEN 'Portugal - Portuguese'
																					 WHEN BMQ.Market = 'Mexico' AND L.Language = 'Spain - Spanish' THEN 'Portugal - Portuguese'
																					 ELSE L.Language END = ECD.EmailLanguage
	WHERE ECD.EmailLanguage IS NULL
		AND CS.CreationDate >= @DateLastRun
	GROUP BY CD.CaseID, 
		BMQ.Brand, 
		BMQ.Market, 
		BMQ.Questionnaire, 
		CS.CreationDate, 
		L.Language


	INSERT INTO dbo.CaseIDNotOutputRolling ([ReportDate],[CaseID], [Brand], [Market], [Questionnaire], [CaseCreationDate], [CaseIDLang])
	SELECT CNO.ReportDate, 
		CNO.CaseID, 
		CNO.Brand, 
		CNO.Market, 
		CNO.Questionnaire, 
		CNO.CaseCreationDate, 
		CNO.CaseIDLang
	FROM dbo.CaseIDNotOutput CNO
	WHERE CNO.ReportDate >= @DateLastRun


	SELECT SL.AuditID, 
		COUNT(SL.AuditID) AS LoadedRows
	INTO #Loaded
	FROM [$(AuditDB)].[Audit].CustomerUpdate_ContactOutcome SL 
		INNER JOIN dbo.DailyBounceBack DB ON SL.AuditID = DB.AuditID
	GROUP BY SL.AuditID


	UPDATE DB
	SET LoadedRowCount = L.LoadedRows
	FROM dbo.DailyBounceBack DB
		INNER JOIN #Loaded L ON L.AuditID = db.AuditID


	UPDATE dbo.DailyBounceBack
	SET LoadSuccess = CASE	WHEN FileRowCount = LoadedRowCount THEN 'Y'
							ELSE 'N' END
				  
END