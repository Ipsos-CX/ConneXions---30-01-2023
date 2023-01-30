CREATE TABLE [dbo].[FileRowsRemovedBeforeLoad] (
    [AuditID]				dbo.AuditID	NOT NULL,
    [PhysicalRow]			INT			NOT NULL,
    [RemovingProcess]		VARCHAR(MAX),
    [RemovalReasons]		VARCHAR(MAX),
    [FailedValues]			VARCHAR(MAX),
    EventDate				NVARCHAR(200),
    DealerCode				NVARCHAR(200), 
    Manufacturer			NVARCHAR(200),
    VIN						NVARCHAR(200)
);

