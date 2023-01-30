CREATE TABLE [GDPR].[ErasureRequests]
(
	AuditID		dbo.AuditID		NOT NULL, 
	PartyID		BIGINT			NOT NULL,
	FullErasure	CHAR(1)			NOT NULL,
	RequestDate	DATETIME2		NOT NULL,
	RequestedBy VARCHAR(100)	NOT NULL
)


