CREATE TABLE [LostLeads].[OutputErrors]
(
	EventID				BIGINT NOT NULL,
	CaseID				BIGINT NOT NULL,
	AttemptedOutputDate	DATETIME,
	ErrorDescription	VARCHAR(2000),
	ErrorMailedDate		DATETIME
)
