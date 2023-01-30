CREATE VIEW [CRM].[vwValidResponseMarketQuestionnaires]

AS

/*
		Purpose:	View for valid CRM questionnaires
		
		Version		Date			Developer			Comment
LIVE	1.0			????-??-??		Chris Ross			Created
*/
	
SELECT M.Market, 
	EC.EventCategory,
	ISNULL(RMQ.FromDate, '1900-01-01') AS FromDate		-- BUG 15149 
FROM CRM.ResponseMarketQuestionnaires RMQ
	INNER JOIN [$(SampleDB)].dbo.Markets M ON M.CountryID = RMQ.CountryID
	INNER JOIN [$(SampleDB)].Event.EventCategories EC ON EC.EventCategoryID = RMQ.EventCategoryID
WHERE RMQ.Enabled = 1 
