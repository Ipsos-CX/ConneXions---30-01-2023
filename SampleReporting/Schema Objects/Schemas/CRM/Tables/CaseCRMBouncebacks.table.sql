
/* BUG 13566 (24/04/2017) - Chris Ross - This has been superseded by CaseResponseStatuses *****************************

CREATE TABLE [CRM].[CaseCRMBouncebacks]
(
    [CaseID]			dbo.CaseID   NOT NULL,
    [LoadedToConnexions] DATETIME2 NULL,
    [DateAddedForOutput] DATETIME2 NULL,
	[UUID]				VARCHAR(100) NULL,
	[OutputToCRMDate]	DATETIME2  NULL
);


*/