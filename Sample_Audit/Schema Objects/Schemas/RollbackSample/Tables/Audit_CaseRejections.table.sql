CREATE TABLE [RollbackSample].[Audit_CaseRejections]
(
	[AuditID]					dbo.AuditID				NOT NULL,
    [CaseRejections_AuditItemID]  dbo.AuditItemID   NOT NULL,
    [CaseID]					dbo.CaseID   NOT NULL,
    [Rejection]					BIT      NOT NULL,
    [FromDate]					DATETIME2 NULL
);

