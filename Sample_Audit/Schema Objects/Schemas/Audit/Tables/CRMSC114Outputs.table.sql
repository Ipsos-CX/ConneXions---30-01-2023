CREATE TABLE Audit.CRMSC114Outputs
(
    CaseID				dbo.CaseID NOT NULL,
    EventID				BIGINT NULL,
    LoadedToConnexions	DATETIME2 NULL,
	UUID				VARCHAR(100) NULL,
	OutputToCRMDate		DATETIME2  NULL,
	OutputFileName		VARCHAR(510) NULL,
	ResponseStatusID	INT		NULL
);