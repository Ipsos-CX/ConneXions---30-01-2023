CREATE VIEW [WeeklySampleCheck].[vwSevenDayResultCountBMQfiles]
AS 

/*
	Purpose:	Return Sample Loaded by BMQ Filename & Day of week (run on FRIDAY)
	
	Version		Date		Deveoloper				Comment
	1.0			21/05/2021	Ben King			    TASK 450			
	
*/
	SELECT 
		S.Market,
		S.Brand,
		S.Questionnaire,
		S.Frequency,
		S.Files,
		S.LoadSuccess,
		--S.FileLoadFailure,
		S.FileRowCount,
		S.AuditID,
		S.FileRow_LoadedCount,
		S.Selected_Count,
		S.ResultDay
	FROM [WeeklySampleCheck].[SevenDayResultCountBMQfiles] S

	ORDER BY 5 DESC,1 DESC, 3, 2 OFFSET 0 rows
	

GO