CREATE VIEW [Audit].[vwChinaVINs]

AS

/*
	Purpose:	Reports China VINs Report details.
	Package Ref: Sample Reporting - Chinese VIN Report
	
	Release		Version			Date			Developer			Comment
	LIVE		1.0				2021-03-16		Ben King			BUG 18109 - CHINA VIN REPORT
	LIVE		1.1				2022-07-04		Eddie Thomas		TASK 955 - Added new field SHA256HashCode
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
WHERE FT.FileType = 'Chinese VINs'
