CREATE PROCEDURE [SampleReport].[uspReportNonOutputCases]

AS

/*
	Purpose:	Removal of Exec team means selection output will no longer be checked, this emailed report will flag
				when CaseID's are missing from an Outputted selection file.
			
	Release		Version		Date			Developer			Comment
	LIVE		1.0			11/03/2021		Eddie Thomas		Created - Task 313
	LIVE		1.1			11/01/2022		Ben King			Task 738 - General Tidy up of solution
	LIVE		1.2			07/03/2022		Chris Ledger		ADD ReasonsForNonOutput to match LIVE/UAT
	LIVE		1.3			14/04/2022		Chris Ledger		Task 851 - Making speed improvements	
	LIVE		1.4			02/11/2022		Ben King			TASK 1053 - 19616 - Sample Health - clear out reasons for non selections for duplicates

*/

DECLARE @ErrorNumber			INT

DECLARE @ErrorSeverity			INT
DECLARE @ErrorState				INT
DECLARE @ErrorLocation			NVARCHAR(500)
DECLARE @ErrorLine				INT
DECLARE @ErrorMessage			NVARCHAR(2048)

DECLARE @html NVARCHAR(MAX)
DECLARE @TimeSinceLastOutput	INT	= 60				-- ONLY INTERESTED IN THE MOST RECENT OUTPUT OF A CASE;
														-- SELECTION OUTPUT TIMES VARY SO I'VE CHOSEN 60 MINUTES TO ALLOW FOR THE POSSIBILITY OF
														-- SELECTION OUTPUT PACKAGE HANGING OR FOR THE PROCESSING OF MANY SELECTIONS.		

SET LANGUAGE ENGLISH
BEGIN TRY
	
	-- CLEAR PREVIOUS REPORT DATA
	TRUNCATE TABLE SampleReport.CasesNotOutput

	--V1.1
	DECLARE @EmailRecipients NVARCHAR(250);

	IF @@ServerName = '1005796-CXNSQLP'
		BEGIN
			SET @EmailRecipients = 'ben.king@ipsos.com; Eddie.Thomas@ipsos.com; Chris.Ledger@ipsos.com;Dipak.Gohil@ipsos.com; Pia.Forslund@ipsos.com; Andrew.Erskine@ipsos.com'
		END
	ELSE
		BEGIN
			SET @EmailRecipients = 'ben.king@ipsos.com;Chris.ledger@ipsos.com;Eddie.Thomas@ipsos.com'
		END	

	-- CASES AUDITED AS BEING OUTPUT 
	;WITH CTE_CasesOutput (CaseID) AS
	(
		SELECT CO.CaseID			-- V1.3
		FROM [$(SampleDB)].Event.CaseOutput CO
			INNER JOIN [$(SampleDB)].Requirement.SelectionCases SC ON CO.CaseID = SC.CaseID
			INNER JOIN [$(SampleDB)].SelectionOutput.SelectionsToOutput	STO ON SC.RequirementIDPartOf = STO.SelectionRequirementID
		GROUP BY CO.CaseID			-- V1.3
	)
	-- COMPARE AGAINST MOST RECENT OUTPUTS AND DETERMINE WHICH CASES HAVEN'T BEEN OUTPUT 	
	INSERT INTO SampleReport.CasesNotOutput (Brand, Market, Questionnaire, SelectionRequirementID, CaseID)
	SELECT STO.Brand, 
		CN.Country AS Market, 
		STO.Questionnaire, 
		STO.SelectionRequirementID, 
		SC.CaseID
	FROM [$(SampleDB)].SelectionOutput.SelectionsToOutput STO
		INNER JOIN [$(SampleDB)].Requirement.SelectionCases SC ON STO.SelectionRequirementID = SC.RequirementIDPartOf
		INNER JOIN [$(SampleDB)].ContactMechanism.Countries CN ON STO.Market = CN.ISOAlpha3
		LEFT JOIN CTE_CasesOutput CO ON SC.CaseID = CO.CaseID
		--LEFT JOIN	[$(SampleDB)].Event.CaseRejections CR ON SC.CaseID = CR.CaseID
	WHERE DATEDIFF(minute, STO.DateProcessed, GETDATE()) BETWEEN 1 AND @TimeSinceLastOutput
		AND CO.CaseID IS NULL


	IF  EXISTS (SELECT * FROM SampleReport.CasesNotOutput)
	BEGIN 

		---------------------------------------------------- REASONS FOR NON OUTPUT ---------------------------------------------------- 

		-- 1 CHECK FOR CASE REJECTION
		UPDATE CNO
		SET	CNO.ReasonsForNonOutput	= CASE	WHEN CNO.Questionnaire IN ('CRC','CRC General Enquiry') THEN 'CaseID was rejected, check ' + CHAR(39) + 'Missing CRC Agent Report' +CHAR(39) +'; '  
											ELSE 'CaseID was rejected; ' END		
		FROM SampleReport.CasesNotOutput CNO
			INNER JOIN [$(SampleDB)].Event.CaseRejections CR ON CNO.CaseID = CR.CaseID


		-- 2 CHECK FOR NON-SUPPORTED LANGUAGE PREFERENCE
		;WITH CTE_CasesNotOutput (CaseID, Brand, Market, Questionnaire, Language) AS
		(
			SELECT DISTINCT CD.CaseID,
				MD.Brand, 
				MD.Market, 
				MD.Questionnaire, 
				LG.Language
			FROM SampleReport.CasesNotOutput CNO
				INNER JOIN [$(SampleDB)].Meta.CaseDetails CD ON CNO.CaseID = CD.CaseID
				INNER JOIN [$(SampleDB)].dbo.vwBrandMarketQuestionnaireSampleMetadata MD ON CD.QuestionnaireRequirementID = MD.QuestionnaireRequirementID
				INNER JOIN [$(SampleDB)].dbo.Languages LG ON CD.LanguageID = LG.LanguageID
		)
		UPDATE CNO
		SET CNO.ReasonsForNonOutput = ISNULL(CNO.ReasonsForNonOutput,'') + 'The customer''s preferred language ' + CHAR(39) + CTE.Language + CHAR(39) + ' isn''t available in the Invite Matrix, for the BMQ combination.'  
		FROM SampleReport.CasesNotOutput CNO
			INNER JOIN CTE_CasesNotOutput CTE ON CNO.CaseID = CTE.CaseID
			LEFT JOIN [$(SampleDB)].SelectionOutput.OnlineEmailContactDetails ONC ON CTE.Brand = ONC.Brand 
																					AND CTE.Market = ONC.Market 
																					AND CTE.Questionnaire = ONC.Questionnaire
																					AND	CTE.Language = ONC.EmailLanguage
		WHERE ONC.ID IS NULL
		---------------------------------------------------- REASONS FOR NON OUTPUT ----------------------------------------------------
		
		EXEC [$(ETLDB)].dbo.spQueryToHtmlTable	@html = @html OUTPUT,  
												@query = N' SELECT Brand, Market, Questionnaire, SelectionRequirementID, CaseID, ReasonsForNonOutput
															FROM SampleReporting.SampleReport.CasesNotOutput',		-- V1.2
												@orderBy = N'ORDER BY 1, 2, 3';
		
		DECLARE @Subject NVARCHAR(MAX);
		SET @Subject = 'CASES NOT OUTPUT';
		
		--DON'T FORGET TO UPDATE RECIPIENT LIST WHEN RELEASING TO LIVE
		EXEC msdb.dbo.sp_send_dbmail
			@profile_name = 'DBAProfile',
			--@recipients = 'ben.king@ipsos.com; Eddie.Thomas@ipsos.com; Chris.Ledger@ipsos.com;Dipak.Gohil@ipsos.com; Pia.Forslund@ipsos.com',
			@recipients = @EmailRecipients, -- V1.1
			@subject = @Subject, 
			@body = @html,
			@body_format = 'HTML',
			@from_address = 'CNX_JLR_Output@ipsos-online.com'
	END

	-- V1.4
	-- 3 CHECK FOR MISSING BMQ IN INVITE MATRIX
		;WITH CTE_CasesNotOutput (CaseID, Brand, Market, Questionnaire, Language) AS
		(
			SELECT DISTINCT CD.CaseID,
				MD.Brand, 
				MD.Market, 
				MD.Questionnaire, 
				LG.Language
			FROM SampleReport.CasesNotOutput CNO
				INNER JOIN [$(SampleDB)].Meta.CaseDetails CD ON CNO.CaseID = CD.CaseID
				INNER JOIN [$(SampleDB)].dbo.vwBrandMarketQuestionnaireSampleMetadata MD ON CD.QuestionnaireRequirementID = MD.QuestionnaireRequirementID
				INNER JOIN [$(SampleDB)].dbo.Languages LG ON CD.LanguageID = LG.LanguageID
		)
		UPDATE CNO
		SET CNO.ReasonsForNonOutput = ISNULL(CNO.ReasonsForNonOutput,'') + 'BMQ combination missing from Invite Matrix '  
		FROM SampleReport.CasesNotOutput CNO
			INNER JOIN CTE_CasesNotOutput CTE ON CNO.CaseID = CTE.CaseID
			LEFT JOIN [$(SampleDB)].SelectionOutput.OnlineEmailContactDetails ONC ON CTE.Brand = ONC.Brand 
																					AND CTE.Market = ONC.Market 
																					AND CTE.Questionnaire = ONC.Questionnaire
																					--AND	CTE.Language = ONC.EmailLanguage
		WHERE ONC.ID IS NULL
		


	-- INSERT INTO HOLDING TABLE FOR HEALTH CHECK
	INSERT INTO [SampleReport].[CasesNotOutputHealthCheck] ([ReportDate], [CaseID], [ReasonsForNonOutput])
	SELECT		GETDATE(), CaseID, ReasonsForNonOutput
	FROM		SampleReport.CasesNotOutput

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
		
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH
