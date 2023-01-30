CREATE TABLE [Audit].[Franchises_Load]
(
	[AuditItemID]						INT NOT NULL,
	[ImportAuditItemID]					INT NOT NULL,
	[LoadType]							CHAR(1) NULL,
	[Update_FranchiseTradingTitle]		CHAR(1) NULL,
	[Update_FranchiseCICode]			CHAR(1) NULL,
	[Update_Address]					CHAR(1) NULL,
	[Update_LocalLanguage]				CHAR(1) NULL

)
