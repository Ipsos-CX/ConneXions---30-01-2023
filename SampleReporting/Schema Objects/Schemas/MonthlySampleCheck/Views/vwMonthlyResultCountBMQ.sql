
CREATE VIEW [MonthlySampleCheck].[vwMonthlyResultCountBMQ]
AS
/*
	Purpose:	Return Sample Loaded by BMQ - Monthly Aggregates
	
	Version		Date		Deveoloper				Comment
	1.0			21/05/2021	Ben King			    TASK 518		
	
*/
	
	SELECT 
		Market,
		Brand,
		Questionnaire,
		ResultMonth + '-' + ResultYear AS 'MonthYear',
		FileRow_LoadedCount,
		Selected_Count,
		ResultDate
	FROM [MonthlySampleCheck].[MonthlyResultCountBMQ]
	WHERE Questionnaire LIKE '%CQI%'

	ORDER BY 7 DESC, 1,2,3 OFFSET 0 rows


GO
