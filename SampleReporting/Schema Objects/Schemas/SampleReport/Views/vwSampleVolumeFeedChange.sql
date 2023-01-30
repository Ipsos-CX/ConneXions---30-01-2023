CREATE VIEW [SampleReport].[vwSampleVolumeFeedChange]
AS 

/*
	Purpose:	Return CHANGED entries in Sample Volume Feed
	
	Release			Version		Date		Deveoloper				Comment
	LIVE  			1.0			20102022	Ben King     			TASK 1011
	

*/
	SELECT DISTINCT
		S.Brand,
		S.Market, 
		S.Questionnaire, 
		
		S.Frequency AS Frequency_NEW,
		L.Frequency AS Frequency_ORIGINAL,
		S.ExpectedDays AS ExpectedDays_NEW,
		L.ExpectedDays AS ExpectedDays_ORIGINAL,
		S.VolumeReportOutput AS VolumeReportOutput_NEW,
		L.VolumeReportOutput AS VolumeReportOutput_ORIGINAL

	FROM [$(ETLDB)].Stage.SampleVolumeFeed S
	LEFT JOIN WeeklySampleCheck.LiveBrandMarketQuestionnaire L   ON L.Brand = S.Brand
																AND L.Market = S.Market
															    AND L.Questionnaire = S.Questionnaire

	WHERE CONCAT(S.Frequency , S.ExpectedDays , S.VolumeReportOutput)
		  <>
		  CONCAT(L.Frequency , L.ExpectedDays , L.VolumeReportOutput)
	AND L.Brand IS NOT NULL
	AND L.Market IS NOT NULL
	AND L.Questionnaire IS NOT NULL

GO
