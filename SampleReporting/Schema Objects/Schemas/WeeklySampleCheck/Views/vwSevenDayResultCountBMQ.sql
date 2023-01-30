CREATE VIEW [WeeklySampleCheck].[vwSevenDayResultCountBMQ]
AS
/*
	Purpose:	Return Sample Loaded by BMQ & Day of week (run on FRIDAY)
	
	Version		Date		Deveoloper				Comment
	1.0			21/05/2021	Ben King			    TASK 450			
	
*/
	
	WITH File_Count_Week (Brand, Market, Questionnaire, Number_of_files_in_the_week)

	AS
		(
			SELECT 
				Brand, 
				Market, 
				Questionnaire, 
				SUM(File_Count) AS Number_of_files_in_the_week
			FROM WeeklySampleCheck.SevenDayResultCountBMQ
			WHERE File_Count IS NOT NULL
			GROUP BY Brand, Market, Questionnaire
		),
	FileRow_Count_Weekly (Brand, Market, Questionnaire, Number_of_fileRows_in_the_week)

	AS
		(
			SELECT 
				Brand, 
				Market, 
				Questionnaire, 
				SUM(FileRow_Count) AS Number_of_fileRows_in_the_week
			FROM WeeklySampleCheck.SevenDayResultCountBMQ
			WHERE FileRow_Count IS NOT NULL
			GROUP BY Brand, Market, Questionnaire
		),	
	FileRow_LoadedCount_Weekly (Brand, Market, Questionnaire, Number_of_fileRowsLoaded_in_the_week)

	AS
		(
			SELECT 
				Brand, 
				Market, 
				Questionnaire, 
				SUM(FileRow_LoadedCount) AS Number_of_fileRowsLoaded_in_the_week
			FROM WeeklySampleCheck.SevenDayResultCountBMQ
			WHERE FileRow_LoadedCount IS NOT NULL
			GROUP BY Brand, Market, Questionnaire
		),	

	Selected_Count_Weekly (Brand, Market, Questionnaire, Number_of_selected_in_the_week)

	AS
		(
			SELECT 
				Brand, 
				Market, 
				Questionnaire, 
				SUM(Selected_Count) AS Number_of_selected_in_the_week
			FROM WeeklySampleCheck.SevenDayResultCountBMQ
			WHERE Selected_Count IS NOT NULL
			GROUP BY Brand, Market, Questionnaire
		)	

	SELECT
		SD.Brand,
		SD.Market,
		SD.Questionnaire,
		SD.Frequency,

		CW.Number_of_files_in_the_week,
		FCW.Number_of_fileRows_in_the_week,
		LCW.Number_of_fileRowsLoaded_in_the_week,
		SCW.Number_of_selected_in_the_week,

		SD.[File_Count - Thursday], 
		SD.[FileRow_Count - Thursday],
		SD.[FileRow_LoadedCount - Thursday],
		SD.[Selected_Count - Thursday],

		SD.[File_Count - Wednesday], 
		SD.[FileRow_Count - Wednesday],
		SD.[FileRow_LoadedCount - Wednesday],
		SD.[Selected_Count - Wednesday],

		SD.[File_Count - Tuesday], 
		SD.[FileRow_Count - Tuesday],
		SD.[FileRow_LoadedCount - Tuesday],
		SD.[Selected_Count - Tuesday],

		SD.[File_Count - Monday], 
		SD.[FileRow_Count - Monday],
		SD.[FileRow_LoadedCount - Monday],
		SD.[Selected_Count - Monday],

		SD.[File_Count - Sunday], 
		SD.[FileRow_Count - Sunday],
		SD.[FileRow_LoadedCount - Sunday],
		SD.[Selected_Count - Sunday],

		SD.[File_Count - Saturday], 
		SD.[FileRow_Count - Saturday],
		SD.[FileRow_LoadedCount - Saturday],
		SD.[Selected_Count - Saturday],

		SD.[File_Count - Friday], 
		SD.[FileRow_Count - Friday],
		SD.[FileRow_LoadedCount - Friday],
		SD.[Selected_Count - Friday]

	--SELECT *
	FROM		WeeklySampleCheck.SevenDayResultCountBMQbyDay SD
	LEFT JOIN	File_Count_Week CW ON SD.Brand = CW.Brand
								  AND SD.Market = CW.Market
								  AND SD.Questionnaire = CW.Questionnaire
	LEFT JOIN	FileRow_Count_Weekly FCW ON SD.Brand = FCW.Brand
								         AND SD.Market = FCW.Market
								         AND SD.Questionnaire = FCW.Questionnaire
	LEFT JOIN	FileRow_LoadedCount_Weekly LCW ON SD.Brand = LCW.Brand
								               AND SD.Market = LCW.Market
								               AND SD.Questionnaire = LCW.Questionnaire
	LEFT JOIN	Selected_Count_Weekly SCW ON SD.Brand = SCW.Brand
								          AND SD.Market = SCW.Market
								          AND SD.Questionnaire = SCW.Questionnaire

	ORDER BY 2,3,1,5 OFFSET 0 rows
	
	



GO

