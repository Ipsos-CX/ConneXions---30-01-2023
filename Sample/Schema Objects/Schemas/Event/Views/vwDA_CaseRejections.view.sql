CREATE VIEW Event.vwDA_CaseRejections

AS

SELECT
	CONVERT(BIGINT, 0) AS AuditItemID,
	CaseID,
	CONVERT(BIT, 1) AS Rejection,
	FromDate
FROM Event.CaseRejections
