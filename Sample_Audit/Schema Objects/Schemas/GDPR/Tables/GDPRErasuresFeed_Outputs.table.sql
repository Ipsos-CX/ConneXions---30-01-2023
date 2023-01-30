CREATE TABLE [GDPR].[GDPRErasuresFeed_Outputs]
(
	AuditItemID		dbo.AuditItemID		NOT NULL, 
	PartyID			dbo.PartyID			NOT NULL,
	ErasureDate		DATETIME2			NOT NULL,
	LoggingAuditItemID dbo.AuditItemID	NOT NULL,
	CaseID			dbo.CaseID			NULL,
	Market			VARCHAR(200) NULL,
	Survey			VARCHAR(255) NULL,
	FileLoadDate	DATE NULL,
	RespondedDate	DATE NULL,
		
	OutputDate		DATETIME2			NOT NULL
)
