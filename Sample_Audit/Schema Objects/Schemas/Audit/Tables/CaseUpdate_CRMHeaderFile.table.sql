CREATE TABLE [Audit].CaseUpdate_CRMHeaderFile (
	[AuditID]			dbo.AuditID		NULL,
	[AuditItemID]		dbo.AuditItemID	NULL,
    [CaseID]			INT				NULL,
    [PartyID]			INT				NULL,
    [CasePartyCombinationValid]  BIT	NULL,
    [DateProcessed]     DATETIME2       NULL,
    [ResponseDate]		NVARCHAR(20)	NULL,
    [RedFlag]			NVARCHAR(20)	NULL,
    [GoldFlag]			NVARCHAR(20)	NULL
);

