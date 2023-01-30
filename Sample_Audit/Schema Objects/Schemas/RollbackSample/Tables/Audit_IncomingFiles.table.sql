CREATE TABLE [RollbackSample].[Audit_IncomingFiles]
(
    [AuditID]				AuditID NOT NULL,
    [FileChecksum]       INT      NOT NULL,
    [LoadSuccess]        BIT      NOT NULL,
    [FileLoadFailureID]		INT		NULL
);

