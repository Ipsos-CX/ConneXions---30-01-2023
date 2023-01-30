CREATE TABLE [CRM].[OutputErrors]
(
	CaseID				INT NOT NULL,
	AttemptedOutputDate	DATETIME,
	ErrorDescription	VARCHAR(500),
	ErrorMailedDate		DATETIME,
	EventID				BIGINT NOT NULL
)
