CREATE VIEW [dbo].[vwVWT_FileRows]
AS

SELECT
	AuditID, 
	AuditItemID, 
	PhysicalFileRow AS PhysicalRow, 
	VWTID
FROM dbo.VWT
WHERE ISNULL(AuditItemID, 0) = 0
