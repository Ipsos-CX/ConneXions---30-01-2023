CREATE VIEW Audit.vwResponseFiles
AS

/*
	Purpose:	Returns a list of all responses files we've loaded into audit
	
	Release		Version			Date				Developer			Comment
	LIVE		0.0				$(ReleaseDate)		Simon Peacock		Created from [Prophet-ETL].dbo.vwAUDIT_SampleFiles
	LIVE		1.0				03/07/2013			Martin Riverol		Copied and amended to pull through response files loaded
	LIVE		1.1				2022-07-04			Eddie Thomas		TASK 955 - Added new field SHA256HashCode
	
*/

SELECT
	 F.AuditID
	,F.FileName
	,F.FileRowCount
	,F.ActionDate
	,I.LoadSuccess
	,I.FileChecksum
	,I.FileLoadFailureID
	,I.SHA256HashCode			--V1.1
FROM [$(AuditDB)].dbo.Files F
INNER JOIN [$(AuditDB)].dbo.IncomingFiles I ON F.AuditID = I.AuditID
INNER JOIN [$(AuditDB)].dbo.FileTypes FT ON FT.FileTypeID = F.FileTypeID
WHERE FT.FileType = 'Responses'