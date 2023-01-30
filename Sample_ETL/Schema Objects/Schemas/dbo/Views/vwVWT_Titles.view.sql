CREATE  VIEW dbo.vwVWT_Titles

AS

/*
	Purpose:	Returns Title information from the VWT
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created from [Prophet-ETL].dbo.vwSTANDARDISE_PreNominalTitles

*/

	SELECT 
		AuditItemID, 
		ISNULL(Title, N'') AS Title, 
		CHECKSUM(ISNULL(Title, N'')) AS TitleChecksum, 
		ISNULL(TitleID, 0) AS TitleID
	FROM dbo.VWT






