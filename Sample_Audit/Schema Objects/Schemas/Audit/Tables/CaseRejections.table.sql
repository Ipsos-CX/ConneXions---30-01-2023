CREATE TABLE [Audit].[CaseRejections] (
    [AuditItemID]     dbo.AuditItemID   NOT NULL,
    [CaseID]          dbo.CaseID   NOT NULL,
    [Rejection] BIT      NOT NULL,
    [FromDate]        DATETIME2 NULL
);

