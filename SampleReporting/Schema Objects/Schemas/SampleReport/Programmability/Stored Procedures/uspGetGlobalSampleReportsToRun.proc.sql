CREATE PROCEDURE [SampleReport].[uspGetGlobalSampleReportsToRun]
@RunDate DATETIME

AS

SET NOCOUNT ON

	DECLARE @ErrorNumber INT
	DECLARE @ErrorSeverity INT
	DECLARE @ErrorState INT
	DECLARE @ErrorLocation NVARCHAR(500)
	DECLARE @ErrorLine INT
	DECLARE @ErrorMessage NVARCHAR(2048)

	/*
		Purpose:	WHAT BRANDS, MARKETS/REGIONS AND QUESTIONNAIRES WE WANT TO RUN SAMPLE REPORTS FOR
			
		Version		Date				Developer			Comment
		1.0			26/08/2015			Chris Ledger		BUG 11658 - Addition of Roadside (major change for regions)
		1.1			03/08/2016			Ben King			BUG 12853 - Addition of CRC
		1.2			08/09/2017			Eddie Thomas		BUG 14141 - New Bodyshop questionnaire
		1.3			29/10/2019			Chris Ledger		BUG 15490 - Add PreOwned LostLeads
	*/
	
	BEGIN TRY

		SELECT 
			'Sales' AS Questionnaire,
			TimePeriod,
			TimePeriodDescription,
			ActiveFlag		
		FROM SampleReport.TimePeriods 
		WHERE 
			CASE 
				-- ONLY RUN QUARTERLY REPORTS IF THEY ARE ACTIVE AND IT IS THE MONTH FOLLOWING THE END OF A QUARTER
				WHEN TIMEPERIOD = 'QTR' AND ActiveFlag = 1 AND DATEPART(M, DATEADD(m, -1, @RunDate)) % 3 > 0 
				THEN 0
				ELSE ActiveFlag
			END = 1
			
		UNION

		SELECT 
			'Service' AS Questionnaire,
			TimePeriod,
			TimePeriodDescription,
			ActiveFlag		
		FROM SampleReport.TimePeriods 
		WHERE 
			CASE 
				-- ONLY RUN QUARTERLY REPORTS IF THEY ARE ACTIVE AND IT IS THE MONTH FOLLOWING THE END OF A QUARTER
				WHEN TIMEPERIOD = 'QTR' AND ActiveFlag = 1 AND DATEPART(M, DATEADD(m, -1, @RunDate)) % 3 > 0 
				THEN 0
				ELSE ActiveFlag
			END = 1

		UNION

		SELECT 
			'Roadside' AS Questionnaire,
			TimePeriod,
			TimePeriodDescription,
			ActiveFlag		
		FROM SampleReport.TimePeriods 
		WHERE 
			CASE 
				-- ONLY RUN QUARTERLY REPORTS IF THEY ARE ACTIVE AND IT IS THE MONTH FOLLOWING THE END OF A QUARTER
				WHEN TIMEPERIOD = 'QTR' AND ActiveFlag = 1 AND DATEPART(M, DATEADD(m, -1, @RunDate)) % 3 > 0 
				THEN 0
				ELSE ActiveFlag
			END = 1
			
			UNION

		SELECT 
			'Preowned' AS Questionnaire,
			TimePeriod,
			TimePeriodDescription,
			ActiveFlag		
		FROM SampleReport.TimePeriods 
		WHERE 
			CASE 
				-- ONLY RUN QUARTERLY REPORTS IF THEY ARE ACTIVE AND IT IS THE MONTH FOLLOWING THE END OF A QUARTER
				WHEN TIMEPERIOD = 'QTR' AND ActiveFlag = 1 AND DATEPART(M, DATEADD(m, -1, @RunDate)) % 3 > 0 
				THEN 0
				ELSE ActiveFlag
			END = 1
			
			UNION

		SELECT 
			'CRC' AS Questionnaire,
			TimePeriod,
			TimePeriodDescription,
			ActiveFlag		
		FROM SampleReport.TimePeriods 
		WHERE 
			CASE 
				-- ONLY RUN QUARTERLY REPORTS IF THEY ARE ACTIVE AND IT IS THE MONTH FOLLOWING THE END OF A QUARTER
				WHEN TIMEPERIOD = 'QTR' AND ActiveFlag = 1 AND DATEPART(M, DATEADD(m, -1, @RunDate)) % 3 > 0 
				THEN 0
				ELSE ActiveFlag
			END = 1
			
		UNION

		SELECT 
			'LostLeads' AS Questionnaire,
			TimePeriod,
			TimePeriodDescription,
			ActiveFlag		
		FROM SampleReport.TimePeriods 
		WHERE 
			CASE 
				-- ONLY RUN QUARTERLY REPORTS IF THEY ARE ACTIVE AND IT IS THE MONTH FOLLOWING THE END OF A QUARTER
				WHEN TIMEPERIOD = 'QTR' AND ActiveFlag = 1 AND DATEPART(M, DATEADD(m, -1, @RunDate)) % 3 > 0 
				THEN 0
				ELSE ActiveFlag
			END = 1
		
		UNION
		
		SELECT	--V1.2	
			'Bodyshop' AS Questionnaire,
			TimePeriod,
			TimePeriodDescription,
			ActiveFlag		
		FROM SampleReport.TimePeriods 
		WHERE 
			CASE 
				-- ONLY RUN QUARTERLY REPORTS IF THEY ARE ACTIVE AND IT IS THE MONTH FOLLOWING THE END OF A QUARTER
				WHEN TIMEPERIOD = 'QTR' AND ActiveFlag = 1 AND DATEPART(M, DATEADD(m, -1, @RunDate)) % 3 > 0 
				THEN 0
				ELSE ActiveFlag
			END = 1

		UNION

		SELECT		-- V1.3
			'PreOwned LostLeads' AS Questionnaire,
			TimePeriod,
			TimePeriodDescription,
			ActiveFlag		
		FROM SampleReport.TimePeriods 
		WHERE 
			CASE 
				-- ONLY RUN QUARTERLY REPORTS IF THEY ARE ACTIVE AND IT IS THE MONTH FOLLOWING THE END OF A QUARTER
				WHEN TIMEPERIOD = 'QTR' AND ActiveFlag = 1 AND DATEPART(M, DATEADD(m, -1, @RunDate)) % 3 > 0 
				THEN 0
				ELSE ActiveFlag
			END = 1

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
