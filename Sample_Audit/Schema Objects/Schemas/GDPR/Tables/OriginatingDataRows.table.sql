CREATE TABLE [GDPR].[OriginatingDataRows]
(
	AuditItemID				dbo.AuditItemID	NOT NULL, 
	OriginatingAuditID		dbo.AuditItemID	NOT NULL,
	FileName				dbo.Filename	NOT NULL, 
	ActionDate				DATETIME2		NULL, 
	PhysicalRow				INT				NOT NULL, 
	OriginatingAuditItemID	dbo.AuditItemID NOT NULL,
	FileType				VARCHAR(50)		NOT NULL
)


