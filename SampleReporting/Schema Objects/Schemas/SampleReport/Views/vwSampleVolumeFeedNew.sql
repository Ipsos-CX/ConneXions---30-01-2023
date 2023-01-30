CREATE VIEW [SampleReport].[vwSampleVolumeFeedNew]
AS 

/*
	Purpose:	Return NEW entries in Sample Volume Feed
	
	Release		Version		Date		Deveoloper				Comment
	LIVE  		1.0			20102022	Ben King     			TASK 1011

*/
	SELECT DISTINCT
		S.Brand,
		S.Market, 
		S.Questionnaire, 
		
		S.Frequency,
		S.ExpectedDays,
		S.VolumeReportOutput

	FROM [$(ETLDB)].Stage.SampleVolumeFeed S
	LEFT JOIN WeeklySampleCheck.LiveBrandMarketQuestionnaire L   ON L.Brand = S.Brand
																AND L.Market = S.Market
															    AND L.Questionnaire = S.Questionnaire
	WHERE L.Market IS NULL
	AND L.Questionnaire IS NULL
	AND L.Brand IS NULL

GO
