CREATE VIEW dbo.vwDA_FileRows
AS

SELECT
	AI.AuditID, 
	ISNULL(AI.AuditItemID, 0) AS AuditItemID, 
	ISNULL(FR.PhysicalRow, 0) AS PhysicalRow, 
	CONVERT(INT, NULL) AS VWTID
FROM dbo.FileRows FR
INNER JOIN dbo.AuditItems AI ON FR.AuditItemID = AI.AuditItemID


