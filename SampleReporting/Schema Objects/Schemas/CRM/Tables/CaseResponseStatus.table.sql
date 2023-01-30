CREATE TABLE [CRM].[CaseResponseStatuses]
(
    [CaseID]			dbo.CaseID   NOT NULL,
    [EventID]			BIGINT		 NOT NULL,
	[ResponseStatusID]	INT			 NOT NULL,
    [LoadedToConnexions] DATETIME2 NULL,
    [DateAddedForOutput] DATETIME2 NULL,
    [AddedByProcess]	VARCHAR(200) NULL,
	[UUID]				VARCHAR(100) NULL,
	[OutputToCRMDate]	DATETIME2  NULL
);
