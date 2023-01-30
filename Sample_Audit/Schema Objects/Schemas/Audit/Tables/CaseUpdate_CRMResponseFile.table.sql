CREATE TABLE [Audit].CaseUpdate_CRMResponseFile (
	[AuditID]			dbo.AuditID		NULL,
	[AuditItemID]		dbo.AuditItemID	NULL,
    [CaseID]			INT		NULL,
    [PartyID]			INT			  NULL,
    [CasePartyCombinationValid] BIT	 NULL,
    [DateProcessed]     DATETIME2      NULL,
	[QuestionNumber]	nvarchar(5)   NULL,
    [QuestionText]		nvarchar(255) NULL,
    [Response]			nvarchar(255) NULL
);

