CREATE VIEW [SampleReceipt].[vwEmailReportOutputs]
AS 
	
/*
	Purpose:	Returns the various enabled Emails Lists and associated enabled Reports.
				i.e. the current valid list of reports and email addresses to use.
				Note that this is non-"environment specific" so the environment must be added as a filter.
		
	Version		Date				Developer			Comment
	1.0			24/07/2017			Chris Ross			Created

*/	
	
	
SELECT	el.EmailListID, 
		el.EmailListName, 
		el.Environment, 
		el.EmailAddressList, 
		ISNULL(el.EmailAddressListCC, '') EmailAddressListCC, 
		ro.ReportOutputID, 
		ro.MarketRegion, 
		ro.MarketOrRegionFlag, 
		ro.Questionnaire 
FROM [SampleReceipt].EmailReportOutputs ero
INNER JOIN SampleReceipt.EmailList el ON el.EmailListID = ero.EmailListID 
									 AND el.Enabled = 1
INNER JOIN SampleReceipt.ReportOutputs ro ON ro.ReportOutputID = ero.ReportOutputID 
										 AND ro.Enabled = 1

