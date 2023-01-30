




CREATE PROCEDURE dbo.uspVWT_AddAuditItemIDs
AS

/*
	Purpose:	Writes rows from VWT into vwDA_FileRows in Audit which will write back AuditItemIDs to the VWT
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created from uspODSLOAD_AddAuditFileRows

*/

	INSERT INTO [$(AuditDB)].dbo.vwDA_FileRows
	(
		AuditID, 
		AuditItemID, 
		PhysicalRow, 
		VWTID
	)
	SELECT
		AuditID, 
		AuditItemID, 
		ISNULL(PhysicalRow, 0), 
		ISNULL(VWTID, 0)
	FROM dbo.vwVWT_FileRows

