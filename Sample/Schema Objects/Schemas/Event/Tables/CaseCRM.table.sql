CREATE TABLE [Event].[CaseCRM] (
    [CaseID]			dbo.CaseID   NOT NULL,
    [ResponseDate]		DATETIME2	 NULL,
    [RedFlag]			BIT NULL,
    [GoldFlag]			BIT NULL,
    [LoadedToConnexions] DATETIME2 NULL,
	[UUID]				VARCHAR(100) NULL,
	[OutputToCRMDate]	DATETIME2  NULL
);