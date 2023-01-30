CREATE PROCEDURE [GermanyRedFlagReport].[uspGermanyRedFlagReport]

AS

/*
		Purpose:	Produce Germany Red Flag Report
	
		Version		Date			Developer			Comment
LIVE	1.0			2022-08-23		Chris Ledger		Created
*/

DROP TABLE IF EXISTS #GermanyRedFlagReport
TRUNCATE TABLE GermanyRedFlagReport.GermanyRetailers
TRUNCATE TABLE GermanyRedFlagReport.GermanyRedFlagReportSourceData
TRUNCATE TABLE GermanyRedFlagReport.GermanyRedFlagReport

SET DATEFIRST 2				-- Tuesday

DECLARE @ReportWeek INT
DECLARE @MinDate DATE
DECLARE @MaxDate DATE
DECLARE @FirstDay INT = 2	-- Tuesday

SET @ReportWeek = DATEDIFF(WEEK, 0, (GETDATE()-7))
SET @MinDate = DATEADD(WEEK, @ReportWeek, @FirstDay - 1)
SET @MaxDate = DATEADD(WEEK, @ReportWeek, @FirstDay + 5)


;WITH CTE_AllDates AS 
(
	SELECT TOP (DATEDIFF(DAY, @MinDate, @MaxDate) + 1)
		DATEDIFF(WEEK, 0, DATEADD(DAY, ROW_NUMBER() OVER (ORDER BY A.object_id) - 1 - @FirstDay, @MinDate)) AS [Report Week],
		DATEADD(DAY, ROW_NUMBER() OVER (ORDER BY A.object_id) - 1, @MinDate) AS [Report Date]
	FROM sys.all_objects A
		CROSS JOIN sys.all_objects B
)
INSERT INTO GermanyRedFlagReport.GermanyRetailers
SELECT D.Market + ' National' AS Market,
	D.SubNationalRegion AS [Region],
	D.Outlet + ' (' + LOWER(D.Dealer10DigitCode) + ')' AS Dealer,
	D.Manufacturer AS Brand,
	D.ManufacturerPartyID AS BrandID,
	D.OutletFunctionID,
	D.OutletPartyID,
	AD.[Report Week],
	AD.[Report Date]
FROM [$(SampleDB)].dbo.DW_JLRCSPDealers D
	LEFT JOIN CTE_AllDates AD ON D.Market = 'Germany'
WHERE D.Market = 'Germany'
	AND D.OutletFunction = 'Aftersales'
	AND D.ThroughDate IS NULL


DBCC DBREINDEX ('GermanyRedFlagReport.GermanyRetailers', ' ')
UPDATE STATISTICS GermanyRedFlagReport.GermanyRetailers


-- National Total Sample
INSERT INTO GermanyRedFlagReport.GermanyRedFlagReportSourceData
SELECT 1 AS [Report Order],
	R.Market,
	NULL AS Region,
	NULL AS Dealer,
	'Jaguar Land Rover' AS Brand,
	1 AS BrandID,
	R.[Report Week],
	R.[Report Date],
	R.[Report Date] AS [Send Date],
	SUM(CASE WHEN G.[Source of this Survey] = 'INVITED' AND G.[Survey status] IN ('COMPLETION_PENDING', 'COMPLETED', 'SURVEY_ENGINE_ONLY', 'EXCLUDED', 'AUTO_EXCLUDED', 'EXIT_AUTO_EXCLUDED', 'DELIVERED', 'DELIVERED_AND_REMINDED', 'DELIVERED_NO_REMINDER', 'EXPIRED', 'DELIVERED_TO_BROADCASTER', 'DELIVERY_FAILED', 'DELIVERY_BOUNCED','DELIVERED_REMINDER_TO_BROADCASTER','PARTIALLY_COMPLETED','PARTIALLY_COMPLETED_AND_REMINDED', 'RESET','INVITATION_RESENT','RESET_PENDING') THEN 1 ELSE 0 END) AS [Count of sent emails],
	SUM(CASE WHEN G.[Source of this Survey] = 'INVITED' AND G.[Survey status] IN ('COMPLETION_PENDING', 'COMPLETED', 'EXCLUDED', 'AUTO_EXCLUDED', 'EXIT_AUTO_EXCLUDED', 'DELIVERED', 'DELIVERED_AND_REMINDED', 'DELIVERED_NO_REMINDER', 'EXPIRED','DELIVERED_REMINDER_TO_BROADCASTER','PARTIALLY_COMPLETED','PARTIALLY_COMPLETED_AND_REMINDED', 'RESET','INVITATION_RESENT','RESET_PENDING') THEN 1 ELSE 0 END) AS [Count of successfully delivered emails],
	0 AS [Count of responses],
	0 AS [Count of red flags],
	0 AS [Count of red flags closed within 72 hours]
FROM GermanyRedFlagReport.GermanyRetailers R
	INNER JOIN [$(SampleDB)].Event.EventPartyRoles EPR ON R.OutletPartyID = EPR.PartyID
												AND R.OutletFunctionID = EPR.RoleTypeID
	INNER JOIN [$(SampleDB)].Event.Events E ON EPR.EventID = E.EventID
	INNER JOIN GermanyRedFlagReport.GermanyRedFlagReportData G ON E.EventID = G.[Event ID]
																AND R.[Report Date] = CAST(G.Creationdate AS DATE)
GROUP BY R.Market,
	--R.Region,
	--R.Dealer,
	--R.Brand,
	--R.BrandID,
	R.[Report Week],
	R.[Report Date]


-- National Total Responses
INSERT INTO GermanyRedFlagReport.GermanyRedFlagReportSourceData
SELECT 1 AS [Report Order],
	R.Market,
	NULL AS Region,
	NULL AS Dealer,
	'Jaguar Land Rover' AS Brand,
	1 AS BrandID,
	R.[Report Week],
	R.[Report Date],
	MAX(CAST(G.Creationdate AS DATE)) AS [Send Date],
	0 AS [Count of sent emails],
	0 AS [Count of successfully delivered emails],
	SUM(CASE WHEN G.[Source of this Survey] IN ('INVITED','EXTERNAL') AND G.[Survey status] IN ('COMPLETED','COMPLETION_PENDING','EXCLUDED','AUTO_EXCLUDED','EXIT_AUTO_EXCLUDED') THEN 1 ELSE 0 END) AS [Count of responses],
	SUM(CASE WHEN G.[Record has/had red flag issue] = 'Yes' THEN 1 ELSE 0 END) AS [Count of red flags],
	SUM(CASE WHEN G.[Record has/had red flag issue] = 'Yes' AND G.[Alert Closed Within 72 Hours] = 1 THEN 1 ELSE 0 END) AS [Count of red flags closed within 72 hours]
FROM GermanyRedFlagReport.GermanyRetailers R
	INNER JOIN [$(SampleDB)].Event.EventPartyRoles EPR ON R.OutletPartyID = EPR.PartyID
												AND R.OutletFunctionID = EPR.RoleTypeID
	INNER JOIN [$(SampleDB)].Event.Events E ON EPR.EventID = E.EventID
	INNER JOIN GermanyRedFlagReport.GermanyRedFlagReportData G ON E.EventID = G.[Event ID]
																AND R.[Report Date] = NULLIF(CAST(G.[Response Date] AS DATE),'1899-12-30')
GROUP BY R.Market,
	--R.Region,
	--R.Dealer,
	--R.Brand,
	--R.BrandID,
	R.[Report Week],
	R.[Report Date]


-- Blank National Total Responses
INSERT INTO GermanyRedFlagReport.GermanyRedFlagReportSourceData
SELECT 1 AS [Report Order],
	R.Market,
	NULL AS Region,
	NULL AS Dealer,
	'Jaguar Land Rover' AS Brand,
	1 AS BrandID,
	R.[Report Week],
	R.[Report Date],
	NULL AS [Send Date],
	0 AS [Count of sent emails],
	0 AS [Count of successfully delivered emails],
	0 AS [Count of responses],
	0 AS [Count of red flags],
	0 AS [Count of red flags closed within 72 hours]
FROM GermanyRedFlagReport.GermanyRetailers R
GROUP BY R.Market,
	--R.Region,
	--R.Dealer,
	--R.Brand,
	--R.BrandID,
	R.[Report Week],
	R.[Report Date]


-- National Brand Sample
INSERT INTO GermanyRedFlagReport.GermanyRedFlagReportSourceData
SELECT 1 AS [Report Order],
	R.Market,
	NULL AS Region,
	NULL AS Dealer,
	R.Brand,
	R.BrandID,
	R.[Report Week],
	R.[Report Date],
	R.[Report Date] AS [Send Date],
	SUM(CASE WHEN G.[Source of this Survey] = 'INVITED' AND G.[Survey status] IN ('COMPLETION_PENDING', 'COMPLETED', 'SURVEY_ENGINE_ONLY', 'EXCLUDED', 'AUTO_EXCLUDED', 'EXIT_AUTO_EXCLUDED', 'DELIVERED', 'DELIVERED_AND_REMINDED', 'DELIVERED_NO_REMINDER', 'EXPIRED', 'DELIVERED_TO_BROADCASTER', 'DELIVERY_FAILED', 'DELIVERY_BOUNCED','DELIVERED_REMINDER_TO_BROADCASTER','PARTIALLY_COMPLETED','PARTIALLY_COMPLETED_AND_REMINDED', 'RESET','INVITATION_RESENT','RESET_PENDING') THEN 1 ELSE 0 END) AS [Count of sent emails],
	SUM(CASE WHEN G.[Source of this Survey] = 'INVITED' AND G.[Survey status] IN ('COMPLETION_PENDING', 'COMPLETED', 'EXCLUDED', 'AUTO_EXCLUDED', 'EXIT_AUTO_EXCLUDED', 'DELIVERED', 'DELIVERED_AND_REMINDED', 'DELIVERED_NO_REMINDER', 'EXPIRED','DELIVERED_REMINDER_TO_BROADCASTER','PARTIALLY_COMPLETED','PARTIALLY_COMPLETED_AND_REMINDED', 'RESET','INVITATION_RESENT','RESET_PENDING') THEN 1 ELSE 0 END) AS [Count of successfully delivered emails],
	0 AS [Count of responses],
	0 AS [Count of red flags],
	0 AS [Count of red flags closed within 72 hours]
FROM GermanyRedFlagReport.GermanyRetailers R
	INNER JOIN [$(SampleDB)].Event.EventPartyRoles EPR ON R.OutletPartyID = EPR.PartyID
												AND R.OutletFunctionID = EPR.RoleTypeID
	INNER JOIN [$(SampleDB)].Event.Events E ON EPR.EventID = E.EventID
	INNER JOIN GermanyRedFlagReport.GermanyRedFlagReportData G ON E.EventID = G.[Event ID]
																AND R.[Report Date] = CAST(G.Creationdate AS DATE)
GROUP BY R.Market,
	--R.Region,
	--R.Dealer,
	R.Brand,
	R.BrandID,
	R.[Report Week],
	R.[Report Date]


-- National Brand Responses
INSERT INTO GermanyRedFlagReport.GermanyRedFlagReportSourceData
SELECT 1 AS [Report Order],
	R.Market,
	NULL AS Region,
	NULL AS Dealer,
	R.Brand,
	R.BrandID,
	R.[Report Week],
	R.[Report Date],
	MAX(CAST(G.Creationdate AS DATE)) AS [Send Date],
	0 AS [Count of sent emails],
	0 AS [Count of successfully delivered emails],
	SUM(CASE WHEN G.[Source of this Survey] IN ('INVITED','EXTERNAL') AND G.[Survey status] IN ('COMPLETED','COMPLETION_PENDING','EXCLUDED','AUTO_EXCLUDED','EXIT_AUTO_EXCLUDED') THEN 1 ELSE 0 END) AS [Count of responses],
	SUM(CASE WHEN G.[Record has/had red flag issue] = 'Yes' THEN 1 ELSE 0 END) AS [Count of red flags],
	SUM(CASE WHEN G.[Record has/had red flag issue] = 'Yes' AND G.[Alert Closed Within 72 Hours] = 1 THEN 1 ELSE 0 END) AS [Count of red flags closed within 72 hours]
FROM GermanyRedFlagReport.GermanyRetailers R
	INNER JOIN [$(SampleDB)].Event.EventPartyRoles EPR ON R.OutletPartyID = EPR.PartyID
												AND R.OutletFunctionID = EPR.RoleTypeID
	INNER JOIN [$(SampleDB)].Event.Events E ON EPR.EventID = E.EventID
	INNER JOIN GermanyRedFlagReport.GermanyRedFlagReportData G ON E.EventID = G.[Event ID]
																AND R.[Report Date] = NULLIF(CAST(G.[Response Date] AS DATE),'1899-12-30')
GROUP BY R.Market,
	--R.Region,
	--R.Dealer,
	R.Brand,
	R.BrandID,
	R.[Report Week],
	R.[Report Date]


-- Blank National Brand Responses
INSERT INTO GermanyRedFlagReport.GermanyRedFlagReportSourceData
SELECT 1 AS [Report Order],
	R.Market,
	NULL AS Region,
	NULL AS Dealer,
	R.Brand,
	R.BrandID,
	R.[Report Week],
	R.[Report Date],
	NULL AS [Send Date],
	0 AS [Count of sent emails],
	0 AS [Count of successfully delivered emails],
	0 AS [Count of responses],
	0 AS [Count of red flags],
	0 AS [Count of red flags closed within 72 hours]
FROM GermanyRedFlagReport.GermanyRetailers R
GROUP BY R.Market,
	--R.Region,
	--R.Dealer,
	R.Brand,
	R.BrandID,
	R.[Report Week],
	R.[Report Date]


-- Region Total Sample
INSERT INTO GermanyRedFlagReport.GermanyRedFlagReportSourceData
SELECT 2 AS [Report Order],
	R.Market,
	R.Region,
	NULL AS Dealer,
	'Jaguar Land Rover' AS Brand,
	1 AS BrandID,
	R.[Report Week],
	R.[Report Date],
	R.[Report Date] AS [Send Date],
	SUM(CASE WHEN G.[Source of this Survey] = 'INVITED' AND G.[Survey status] IN ('COMPLETION_PENDING', 'COMPLETED', 'SURVEY_ENGINE_ONLY', 'EXCLUDED', 'AUTO_EXCLUDED', 'EXIT_AUTO_EXCLUDED', 'DELIVERED', 'DELIVERED_AND_REMINDED', 'DELIVERED_NO_REMINDER', 'EXPIRED', 'DELIVERED_TO_BROADCASTER', 'DELIVERY_FAILED', 'DELIVERY_BOUNCED','DELIVERED_REMINDER_TO_BROADCASTER','PARTIALLY_COMPLETED','PARTIALLY_COMPLETED_AND_REMINDED', 'RESET','INVITATION_RESENT','RESET_PENDING') THEN 1 ELSE 0 END) AS [Count of sent emails],
	SUM(CASE WHEN G.[Source of this Survey] = 'INVITED' AND G.[Survey status] IN ('COMPLETION_PENDING', 'COMPLETED', 'EXCLUDED', 'AUTO_EXCLUDED', 'EXIT_AUTO_EXCLUDED', 'DELIVERED', 'DELIVERED_AND_REMINDED', 'DELIVERED_NO_REMINDER', 'EXPIRED','DELIVERED_REMINDER_TO_BROADCASTER','PARTIALLY_COMPLETED','PARTIALLY_COMPLETED_AND_REMINDED', 'RESET','INVITATION_RESENT','RESET_PENDING') THEN 1 ELSE 0 END) AS [Count of successfully delivered emails],
	0 AS [Count of responses],
	0 AS [Count of red flags],
	0 AS [Count of red flags closed within 72 hours]
FROM GermanyRedFlagReport.GermanyRetailers R
	INNER JOIN [$(SampleDB)].Event.EventPartyRoles EPR ON R.OutletPartyID = EPR.PartyID
												AND R.OutletFunctionID = EPR.RoleTypeID
	INNER JOIN [$(SampleDB)].Event.Events E ON EPR.EventID = E.EventID
	INNER JOIN GermanyRedFlagReport.GermanyRedFlagReportData G ON E.EventID = G.[Event ID]
																AND R.[Report Date] = CAST(G.Creationdate AS DATE)
GROUP BY R.Market,
	R.Region,
	--R.Dealer,
	--R.Brand,
	--R.BrandID,
	R.[Report Week],
	R.[Report Date]


-- Region Total Responses
INSERT INTO GermanyRedFlagReport.GermanyRedFlagReportSourceData
SELECT 2 AS [Report Order],
	R.Market,
	R.Region,
	NULL AS Dealer,
	'Jaguar Land Rover' AS Brand,
	1 AS BrandID,
	R.[Report Week],
	R.[Report Date],
	MAX(CAST(G.Creationdate AS DATE)) AS [Send Date],
	0 AS [Count of sent emails],
	0 AS [Count of successfully delivered emails],
	SUM(CASE WHEN G.[Source of this Survey] IN ('INVITED','EXTERNAL') AND G.[Survey status] IN ('COMPLETED','COMPLETION_PENDING','EXCLUDED','AUTO_EXCLUDED','EXIT_AUTO_EXCLUDED') THEN 1 ELSE 0 END) AS [Count of responses],
	SUM(CASE WHEN G.[Record has/had red flag issue] = 'Yes' THEN 1 ELSE 0 END) AS [Count of red flags],
	SUM(CASE WHEN G.[Record has/had red flag issue] = 'Yes' AND G.[Alert Closed Within 72 Hours] = 1 THEN 1 ELSE 0 END) AS [Count of red flags closed within 72 hours]
FROM GermanyRedFlagReport.GermanyRetailers R
	INNER JOIN [$(SampleDB)].Event.EventPartyRoles EPR ON R.OutletPartyID = EPR.PartyID
												AND R.OutletFunctionID = EPR.RoleTypeID
	INNER JOIN [$(SampleDB)].Event.Events E ON EPR.EventID = E.EventID
	INNER JOIN GermanyRedFlagReport.GermanyRedFlagReportData G ON E.EventID = G.[Event ID]
																AND R.[Report Date] = NULLIF(CAST(G.[Response Date] AS DATE),'1899-12-30')
GROUP BY R.Market,
	R.Region,
	--R.Dealer,
	--R.Brand,
	--R.BrandID,
	R.[Report Week],
	R.[Report Date]


-- Blank Region Total Responses
INSERT INTO GermanyRedFlagReport.GermanyRedFlagReportSourceData
SELECT 2 AS [Report Order],
	R.Market,
	R.Region,
	NULL AS Dealer,
	'Jaguar Land Rover' AS Brand,
	1 AS BrandID,
	R.[Report Week],
	R.[Report Date],
	NULL AS [Send Date],
	0 AS [Count of sent emails],
	0 AS [Count of successfully delivered emails],
	0 AS [Count of responses],
	0 AS [Count of red flags],
	0 AS [Count of red flags closed within 72 hours]
FROM GermanyRedFlagReport.GermanyRetailers R
GROUP BY R.Market,
	R.Region,
	--R.Dealer,
	--R.Brand,
	--R.BrandID,
	R.[Report Week],
	R.[Report Date]


-- Region Brand Sample
INSERT INTO GermanyRedFlagReport.GermanyRedFlagReportSourceData
SELECT 2 AS [Report Order],
	R.Market,
	R.Region,
	NULL AS Dealer,
	R.Brand,
	R.BrandID,
	R.[Report Week],
	R.[Report Date],
	R.[Report Date] AS [Send Date],
	SUM(CASE WHEN G.[Source of this Survey] = 'INVITED' AND G.[Survey status] IN ('COMPLETION_PENDING', 'COMPLETED', 'SURVEY_ENGINE_ONLY', 'EXCLUDED', 'AUTO_EXCLUDED', 'EXIT_AUTO_EXCLUDED', 'DELIVERED', 'DELIVERED_AND_REMINDED', 'DELIVERED_NO_REMINDER', 'EXPIRED', 'DELIVERED_TO_BROADCASTER', 'DELIVERY_FAILED', 'DELIVERY_BOUNCED','DELIVERED_REMINDER_TO_BROADCASTER','PARTIALLY_COMPLETED','PARTIALLY_COMPLETED_AND_REMINDED', 'RESET','INVITATION_RESENT','RESET_PENDING') THEN 1 ELSE 0 END) AS [Count of sent emails],
	SUM(CASE WHEN G.[Source of this Survey] = 'INVITED' AND G.[Survey status] IN ('COMPLETION_PENDING', 'COMPLETED', 'EXCLUDED', 'AUTO_EXCLUDED', 'EXIT_AUTO_EXCLUDED', 'DELIVERED', 'DELIVERED_AND_REMINDED', 'DELIVERED_NO_REMINDER', 'EXPIRED','DELIVERED_REMINDER_TO_BROADCASTER','PARTIALLY_COMPLETED','PARTIALLY_COMPLETED_AND_REMINDED', 'RESET','INVITATION_RESENT','RESET_PENDING') THEN 1 ELSE 0 END) AS [Count of successfully delivered emails],
	0 AS [Count of responses],
	0 AS [Count of red flags],
	0 AS [Count of red flags closed within 72 hours]
FROM GermanyRedFlagReport.GermanyRetailers R
	INNER JOIN [$(SampleDB)].Event.EventPartyRoles EPR ON R.OutletPartyID = EPR.PartyID
												AND R.OutletFunctionID = EPR.RoleTypeID
	INNER JOIN [$(SampleDB)].Event.Events E ON EPR.EventID = E.EventID
	INNER JOIN GermanyRedFlagReport.GermanyRedFlagReportData G ON E.EventID = G.[Event ID]
																AND R.[Report Date] = CAST(G.Creationdate AS DATE)
GROUP BY R.Market,
	R.Region,
	--R.Dealer,
	R.Brand,
	R.BrandID,
	R.[Report Week],
	R.[Report Date]


-- Region Brand Responses
INSERT INTO GermanyRedFlagReport.GermanyRedFlagReportSourceData
SELECT 2 AS [Report Order],
	R.Market,
	R.Region,
	NULL AS Dealer,
	R.Brand,
	R.BrandID,
	R.[Report Week],
	R.[Report Date],
	MAX(CAST(G.Creationdate AS DATE)) AS [Send Date],
	0 AS [Count of sent emails],
	0 AS [Count of successfully delivered emails],
	SUM(CASE WHEN G.[Source of this Survey] IN ('INVITED','EXTERNAL') AND G.[Survey status] IN ('COMPLETED','COMPLETION_PENDING','EXCLUDED','AUTO_EXCLUDED','EXIT_AUTO_EXCLUDED') THEN 1 ELSE 0 END) AS [Count of responses],
	SUM(CASE WHEN G.[Record has/had red flag issue] = 'Yes' THEN 1 ELSE 0 END) AS [Count of red flags],
	SUM(CASE WHEN G.[Record has/had red flag issue] = 'Yes' AND G.[Alert Closed Within 72 Hours] = 1 THEN 1 ELSE 0 END) AS [Count of red flags closed within 72 hours]
FROM GermanyRedFlagReport.GermanyRetailers R
	INNER JOIN [$(SampleDB)].Event.EventPartyRoles EPR ON R.OutletPartyID = EPR.PartyID
												AND R.OutletFunctionID = EPR.RoleTypeID
	INNER JOIN [$(SampleDB)].Event.Events E ON EPR.EventID = E.EventID
	INNER JOIN GermanyRedFlagReport.GermanyRedFlagReportData G ON E.EventID = G.[Event ID]
																AND R.[Report Date] = NULLIF(CAST(G.[Response Date] AS DATE),'1899-12-30')
GROUP BY R.Market,
	R.Region,
	--R.Dealer,
	R.Brand,
	R.BrandID,
	R.[Report Week],
	R.[Report Date]


-- Blank Region Brand Responses
INSERT INTO GermanyRedFlagReport.GermanyRedFlagReportSourceData
SELECT 2 AS [Report Order],
	R.Market,
	R.Region,
	NULL AS Dealer,
	R.Brand,
	R.BrandID,
	R.[Report Week],
	R.[Report Date],
	NULL AS [Send Date],
	0 AS [Count of sent emails],
	0 AS [Count of successfully delivered emails],
	0 AS [Count of responses],
	0 AS [Count of red flags],
	0 AS [Count of red flags closed within 72 hours]
FROM GermanyRedFlagReport.GermanyRetailers R
GROUP BY R.Market,
	R.Region,
	--R.Dealer,
	R.Brand,
	R.BrandID,
	R.[Report Week],
	R.[Report Date]


-- Retailer Sample
INSERT INTO GermanyRedFlagReport.GermanyRedFlagReportSourceData
SELECT 2 AS [Report Order],
	R.Market,
	R.Region,
	R.Dealer,
	R.Brand,
	R.BrandID,
	R.[Report Week],
	R.[Report Date],
	R.[Report Date] AS [Send Date],
	SUM(CASE WHEN G.[Source of this Survey] = 'INVITED' AND G.[Survey status] IN ('COMPLETION_PENDING', 'COMPLETED', 'SURVEY_ENGINE_ONLY', 'EXCLUDED', 'AUTO_EXCLUDED', 'EXIT_AUTO_EXCLUDED', 'DELIVERED', 'DELIVERED_AND_REMINDED', 'DELIVERED_NO_REMINDER', 'EXPIRED', 'DELIVERED_TO_BROADCASTER', 'DELIVERY_FAILED', 'DELIVERY_BOUNCED','DELIVERED_REMINDER_TO_BROADCASTER','PARTIALLY_COMPLETED','PARTIALLY_COMPLETED_AND_REMINDED', 'RESET','INVITATION_RESENT','RESET_PENDING') THEN 1 ELSE 0 END) AS [Count of sent emails],
	SUM(CASE WHEN G.[Source of this Survey] = 'INVITED' AND G.[Survey status] IN ('COMPLETION_PENDING', 'COMPLETED', 'EXCLUDED', 'AUTO_EXCLUDED', 'EXIT_AUTO_EXCLUDED', 'DELIVERED', 'DELIVERED_AND_REMINDED', 'DELIVERED_NO_REMINDER', 'EXPIRED','DELIVERED_REMINDER_TO_BROADCASTER','PARTIALLY_COMPLETED','PARTIALLY_COMPLETED_AND_REMINDED', 'RESET','INVITATION_RESENT','RESET_PENDING') THEN 1 ELSE 0 END) AS [Count of successfully delivered emails],
	0 AS [Count of responses],
	0 AS [Count of red flags],
	0 AS [Count of red flags closed within 72 hours]
FROM GermanyRedFlagReport.GermanyRetailers R
	INNER JOIN [$(SampleDB)].Event.EventPartyRoles EPR ON R.OutletPartyID = EPR.PartyID
												AND R.OutletFunctionID = EPR.RoleTypeID
	INNER JOIN [$(SampleDB)].Event.Events E ON EPR.EventID = E.EventID
	INNER JOIN GermanyRedFlagReport.GermanyRedFlagReportData G ON E.EventID = G.[Event ID]
																AND R.[Report Date] = CAST(G.Creationdate AS DATE)
GROUP BY R.Market,
	R.Region,
	R.Dealer,
	R.Brand,
	R.BrandID,
	R.[Report Week],
	R.[Report Date]


-- Retailer Responses
INSERT INTO GermanyRedFlagReport.GermanyRedFlagReportSourceData
SELECT 2 AS [Report Order],
	R.Market,
	R.Region,
	R.Dealer,
	R.Brand,
	R.BrandID,
	R.[Report Week],
	R.[Report Date],
	MAX(CAST(G.Creationdate AS DATE)) AS [Send Date],
	0 AS [Count of sent emails],
	0 AS [Count of successfully delivered emails],
	SUM(CASE WHEN G.[Source of this Survey] IN ('INVITED','EXTERNAL') AND G.[Survey status] IN ('COMPLETED','COMPLETION_PENDING','EXCLUDED','AUTO_EXCLUDED','EXIT_AUTO_EXCLUDED') THEN 1 ELSE 0 END) AS [Count of responses],
	SUM(CASE WHEN G.[Record has/had red flag issue] = 'Yes' THEN 1 ELSE 0 END) AS [Count of red flags],
	SUM(CASE WHEN G.[Record has/had red flag issue] = 'Yes' AND G.[Alert Closed Within 72 Hours] = 1 THEN 1 ELSE 0 END) AS [Count of red flags closed within 72 hours]
FROM GermanyRedFlagReport.GermanyRetailers R
	INNER JOIN [$(SampleDB)].Event.EventPartyRoles EPR ON R.OutletPartyID = EPR.PartyID
												AND R.OutletFunctionID = EPR.RoleTypeID
	INNER JOIN [$(SampleDB)].Event.Events E ON EPR.EventID = E.EventID
	INNER JOIN GermanyRedFlagReport.GermanyRedFlagReportData G ON E.EventID = G.[Event ID]
																AND R.[Report Date] = NULLIF(CAST(G.[Response Date] AS DATE),'1899-12-30')
GROUP BY R.Market,
	R.Region,
	R.Dealer,
	R.Brand,
	R.BrandID,
	R.[Report Week],
	R.[Report Date]


-- Blank Retailer Responses
INSERT INTO GermanyRedFlagReport.GermanyRedFlagReportSourceData
SELECT 2 AS [Report Order],
	R.Market,
	R.Region,
	R.Dealer,
	R.Brand,
	R.BrandID,
	R.[Report Week],
	R.[Report Date],
	NULL AS [Send Date],
	0 AS [Count of sent emails],
	0 AS [Count of successfully delivered emails],
	0 AS [Count of responses],
	0 AS [Count of red flags],
	0 AS [Count of red flags closed within 72 hours]
FROM GermanyRedFlagReport.GermanyRetailers R
GROUP BY R.Market,
	R.Region,
	R.Dealer,
	R.Brand,
	R.BrandID,
	R.[Report Week],
	R.[Report Date]


--SELECT *
--FROM GermanyRedFlagReport.GermanyRedFlagReportSourceData

SELECT R.[Report Week],
	R.[Report Order],
	R.Market,
	R.Region,
	R.Dealer,
	R.Brand,
	R.BrandID,
	R.[Report Date],
	MAX(R.[Send Date]) AS [Send Date],
	SUM(R.[Count of red flags]) AS [Count of red flags],
	SUM(R.[Count of red flags closed within 72 hours]) AS [Count of red flags closed within 72 hours],
	SUM(R.[Count of sent emails]) AS[Count of sent emails],
	SUM(R.[Count of successfully delivered emails]) AS [Count of successfully delivered emails],
	SUM(R.[Count of responses]) AS [Count of responses]
INTO #GermanyRedFlagReport
FROM GermanyRedFlagReport.GermanyRedFlagReportSourceData R
GROUP BY R.[Report Week],
	R.[Report Order],
	R.Market,
	R.Region,
	R.Dealer,
	R.Brand,
	R.BrandID,
	R.[Report Date]


--SELECT *
--FROM #GermanyRedFlagReport

INSERT INTO GermanyRedFlagReport.GermanyRedFlagReport
SELECT R.[Report Week],
	R.[Report Order],
	R.Market,
	R.Region,
	R.Dealer,
	COALESCE(R.Dealer,R.Region,R.Market) AS Retailer,
	R.Brand,
	R.BrandID,
	CAST(R.[Report Date] AS VARCHAR) AS [Report Date],
	R.[Send Date],
	R.[Count of red flags],
	CASE WHEN R.[Count of red flags] = 0 THEN ''
		 ELSE CAST(R.[Count of red flags closed within 72 hours] AS VARCHAR) END AS [Count of red flags closed within 72 hours],
	CASE WHEN R.[Count of red flags] = 0 THEN ''
		 ELSE CAST(ROUND(CAST((R.[Count of red flags closed within 72 hours] * 100.0 / R.[Count of red flags]) AS FLOAT), 0) AS VARCHAR)+'%' END AS [% of red flags closed within within 72 hours],
	R.[Count of sent emails],
	CASE WHEN R.[Count of sent emails] = 0 THEN ''
		 ELSE CAST(R.[Count of successfully delivered emails] AS VARCHAR) END AS [Count of successfully delivered emails],
	R.[Count of responses],
	--SUM(R.[Count of successfully delivered emails]) OVER (PARTITION BY COALESCE(R.Dealer,R.Region,R.Market), R.Brand, R.[Send Date] ORDER BY R.[Report Date]) AS [Running count of successfully delivered emails],
	--SUM(R.[Count of responses]) OVER (PARTITION BY COALESCE(R.Dealer,R.Region,R.Market), R.Brand, R.[Send Date] ORDER BY R.[Report Date]) AS [Running count of responses],
	CASE WHEN SUM(R.[Count of successfully delivered emails]) OVER (PARTITION BY COALESCE(R.Dealer,R.Region,R.Market), R.Brand, R.[Send Date] ORDER BY R.[Report Date]) = 0 THEN ''
		 ELSE CAST(ROUND(CAST((SUM(R.[Count of responses]) OVER (PARTITION BY COALESCE(R.Dealer,R.Region,R.Market), R.Brand, R.[Send Date] ORDER BY R.[Report Date]) * 100.0 / SUM(R.[Count of successfully delivered emails]) OVER (PARTITION BY COALESCE(R.Dealer,R.Region,R.Market), R.Brand, R.[Send Date] ORDER BY R.[Report Date])) AS FLOAT), 1) AS VARCHAR)+'%' END AS [Response rate %]
FROM #GermanyRedFlagReport R
UNION ALL
SELECT R.[Report Week],
	R.[Report Order],
	R.Market,
	R.Region,
	R.Dealer,
	COALESCE(R.Dealer,R.Region,R.Market) AS Retailer,
	R.Brand,
	R.BrandID,
	'Weekly Total (' + CAST(MIN(R.[Report Date]) AS VARCHAR) + ' - ' + CAST(MAX(R.[Report Date]) AS VARCHAR) + ')' AS [Report Date],
	NULL AS [Send Date],
	CAST(SUM(R.[Count of red flags]) AS VARCHAR) AS [Count of red flags],
	CASE WHEN SUM(R.[Count of red flags]) = 0 THEN ''
		 ELSE CAST(SUM(R.[Count of red flags closed within 72 hours]) AS VARCHAR) END AS [Count of red flags closed within 72 hours],
	CASE WHEN SUM(R.[Count of red flags]) = 0 THEN ''
		 ELSE CAST(ROUND(CAST((SUM(R.[Count of red flags closed within 72 hours]) * 100.0 / SUM(R.[Count of red flags])) AS FLOAT), 0) AS VARCHAR)+'%' END AS [% of red flags closed within within 72 hours],
	SUM(R.[Count of sent emails]) AS [Count of sent emails],
	CASE WHEN SUM(R.[Count of sent emails]) = 0 THEN ''
		 ELSE CAST(SUM(R.[Count of successfully delivered emails]) AS VARCHAR) END AS [Count of successfully delivered emails],
	SUM(R.[Count of responses]) AS [Count of responses],
	CASE WHEN SUM(R.[Count of successfully delivered emails]) = 0 THEN ''
		 ELSE CAST(ROUND(CAST((SUM(R.[Count of responses]) * 100.0 / SUM(R.[Count of successfully delivered emails])) AS FLOAT), 1) AS VARCHAR)+'%' END AS [Response rate %]
FROM #GermanyRedFlagReport R
GROUP BY R.[Report Week],
	R.[Report Order],
	R.Market,
	R.Region,
	R.Dealer,
	R.Brand,
	R.BrandID


SELECT *
FROM GermanyRedFlagReport.GermanyRedFlagReport R
ORDER BY [Report Week],
	[Report Order],
	Region,
	Dealer,
	[BrandID],
	[Report Date]