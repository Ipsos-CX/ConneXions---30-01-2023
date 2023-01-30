CREATE VIEW [SampleReport].[vwSampleVolumeFeedRemoved]
AS 

/*
	Purpose:	Return REMOVED entries in Sample Volume Feed
	
	Release			Version		Date		Deveoloper				Comment
	LIVE     		1.0			20102022	Ben King     			TASK 1011

*/

	SELECT DISTINCT
		L.Brand,
		L.Market, 
		L.Questionnaire, 
		
		L.Frequency,
		L.ExpectedDays,
		L.VolumeReportOutput
	FROM WeeklySampleCheck.LiveBrandMarketQuestionnaire L 
	LEFT JOIN [$(ETLDB)].Stage.SampleVolumeFeed S ON L.Brand = S.Brand
												 AND L.Market = S.Market
												 AND L.Questionnaire = S.Questionnaire
	WHERE S.Market IS NULL
	AND S.Questionnaire IS NULL
	AND S.Brand IS NULL




GO
