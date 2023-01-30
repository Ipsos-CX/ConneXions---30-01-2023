CREATE TABLE [RollbackSample].[Requirements]
(
	[AuditID]				   dbo.AuditID				NOT NULL,
    [RequirementID]           dbo.RequirementID NOT NULL,
    [RequirementTypeID]       INT NOT NULL,
    [Requirement]             dbo.Requirement NOT NULL,
    [RequirementCreationDate] DATETIME2       NULL
);

