CREATE VIEW [Audit].[vwIncomingFiles]

AS 

/*
	Release			Version			Date			Developer			Comment
	LIVE			1.1				2021-03-16		Ben King			BUG 18109 - CHINA VIN REPORT
	LIVE			1.2				2021-10-26		Chris Ledger		Task 666 - Add SVO Lookup FileType
	LIVE			1.3             2021-15-12      Ben King            Task 732 - Send email alert if there is no FIMs file
	LIVE			1.4				2022-07-04		Eddie Thomas		TASK 955 - Added new field SHA256HashCode
*/

SELECT
	 AuditID
	,FileName
	,FileRowCount
	,ActionDate
	,LoadSuccess
	,FileChecksum
	,FileLoadFailureID
	,SHA256HashCode					--V1.4
FROM Audit.vwSampleFiles

UNION

SELECT
	 AuditID
	,FileName
	,FileRowCount
	,ActionDate
	,LoadSuccess
	,FileChecksum
	,FileLoadFailureID
	,SHA256HashCode					--V1.4
FROM Audit.vwCustomerUpdateFiles

UNION

SELECT
	 AuditID
	,FileName
	,FileRowCount
	,ActionDate
	,LoadSuccess
	,FileChecksum
	,FileLoadFailureID
	,SHA256HashCode					--V1.4
FROM Audit.vwResponseFiles

UNION

-- V1.1
SELECT
	 AuditID
	,FileName
	,FileRowCount
	,ActionDate
	,LoadSuccess
	,FileChecksum
	,FileLoadFailureID
	,SHA256HashCode					--V1.4
FROM Audit.vwChinaVINs

UNION

-- V1.2
SELECT
	 AuditID
	,FileName
	,FileRowCount
	,ActionDate
	,LoadSuccess
	,FileChecksum
	,FileLoadFailureID
	,SHA256HashCode					--V1.4
FROM Audit.vwSVOLookupFiles

UNION
-- V1.3
SELECT
	 AuditID
	,FileName
	,FileRowCount
	,ActionDate
	,LoadSuccess
	,FileChecksum
	,FileLoadFailureID
	,SHA256HashCode					--V1.4
FROM Audit.vwFranchiseHierarchy


;
