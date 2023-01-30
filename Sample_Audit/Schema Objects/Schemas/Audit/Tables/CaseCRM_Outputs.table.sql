CREATE TABLE [Audit].[CaseCRM_Outputs]
(
    [CaseID]			dbo.CaseID   NOT NULL,
    [ResponseDate]		DATETIME2	 NULL,
    [RedFlag]			BIT NULL,
    [GoldFlag]			BIT NULL,
    [Unsubscribe]		BIT NULL,
    [Bounceback]		BIT NULL,
    [LoadedToConnexions] DATETIME2 NULL,
	[UUID]				VARCHAR(100) NULL,
	[OutputToCRMDate]	DATETIME2  NULL,
    [EventID]			BIGINT			NULL,
	OutputFileName		VARCHAR(510) NULL,
	ResponseStatusID	INT		NULL,
	AllResponseStatuses VARCHAR(50) NULL
);


