CREATE TABLE [Audit].[Events] (
    [AuditItemID]   dbo.AuditItemID        NOT NULL,
    [EventID]       dbo.EventID        NOT NULL,
    [EventDate]     DATETIME2			NULL,
    [EventTypeID]   dbo.EventTypeID           NOT NULL,
    [TypeOfSaleOrig] VARCHAR(50)			NULL,
	[InvoiceDate]	DATETIME2			NULL,
    [EventDateOrig] VARCHAR(50) NULL
);

