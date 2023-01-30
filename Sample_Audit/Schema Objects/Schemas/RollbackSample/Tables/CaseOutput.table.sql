CREATE TABLE [RollbackSample].[CaseOutput]
(
	[AuditID]				  dbo.AuditID	NOT NULL,
    [CaseID]				  dbo.CaseID NOT NULL,
    [CaseOutput_AuditID]      dbo.AuditID NOT NULL,
    [CaseOutput_AuditItemID]  dbo.AuditItemID NOT NULL,
    [CaseOutputTypeID]		  INT  NULL
);

