CREATE VIEW [Audit].[vwFranchiseHierarchy]

AS

/*
	
	Package Ref: Sample Load - Franchise Dealer Hierarchy
	
	Release			Version			Date			Developer			Comment
	LIVE			1.0				2021-03-16		Ben King			Task 732 - Send email alert if there is no FIMs file
	LIVE			1.1				2022-07-04		Eddie Thomas		TASK 955 - Added new field SHA256HashCode
*/

SELECT
	 F.AuditID
	,F.FileName
	,F.FileRowCount
	,F.ActionDate
	,I.LoadSuccess
	,I.FileChecksum
	,I.FileLoadFailureID
	,I.SHA256HashCode				--V1.1
FROM [$(AuditDB)].dbo.Files F
INNER JOIN [$(AuditDB)].dbo.IncomingFiles I ON F.AuditID = I.AuditID
INNER JOIN [$(AuditDB)].dbo.FileTypes FT ON FT.FileTypeID = F.FileTypeID
WHERE FT.FileType = 'Franchise Hierarchy'
GO
