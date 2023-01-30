CREATE VIEW [DealerManagement].[vwFIMSAddedBlackListEmails]
AS 

/*
	Purpose:	Return Add emails black listed from FIMs file load
	
	Release		Version		Date		Deveoloper				Comment
	LIVE			1.1			03/05/2022	Ben King     			TASK 866 - 19490 - Add JLR Employees to the Excluded Email list

*/

	SELECT DISTINCT
			FL.ImportFileName,
			FM.Email,
			FM.FromDate
	FROM	Stage.FIMsBlackListEmail FM
	INNER JOIN DealerManagement.[Franchises_Load] FL ON FM.AuditID = FL.ImportAuditID
	WHERE	FM.AlreadyExists IS NULL
	AND		FM.Email IS NOT NULL

	UNION

	SELECT DISTINCT
			F.FileName AS ImportFileName,
			FM.Email,
			FM.FromDate
	FROM	Stage.FIMsBlackListEmail FM
	INNER JOIN [Stage].[JLRManagementUsersRapidMiner] JL ON FM.AuditItemID = JL.AuditItemID	
	INNER JOIN [$(AuditDB)].dbo.Files F ON JL.AuditID = F.AuditID
	WHERE	FM.AlreadyExists IS NULL
	AND		FM.Email IS NOT NULL

