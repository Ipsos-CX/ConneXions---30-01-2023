CREATE TABLE [RollbackSample].[Events]
(
	[AuditID]		dbo.AuditID				NOT NULL,
    [EventID]		dbo.EventID				NOT NULL,
    [EventDate]		DATETIME2				NULL,
    [EventTypeID]	dbo.EventTypeID			NOT NULL
);

