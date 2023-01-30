CREATE TABLE [dbo].[SampleProcessedLoggingAudit] (
	[AuditTimestamp]					DATETIME2 (7)              NOT NULL,
	
    [AuditID]                            [dbo].[AuditID]            NOT NULL,
    [AuditItemID]                        [dbo].[AuditItemID]        NOT NULL,

    [CaseID]                             [dbo].[CaseID]             NULL,
    [SelectionPoint]					 BIT						NULL,
    
    [SampleRowProcessed]                 BIT                        NOT NULL,
    [SampleRowProcessedDate]             DATETIME2 (7)              NULL
    
);






