CREATE TABLE [dbo].[Files] (
    [AuditID]    AuditID NOT NULL,
    [FileTypeID] FileTypeID NOT NULL,
    [FileName]   FileName NOT NULL,
    [FileRowCount]   INT           NULL,
    [ActionDate] DATETIME2      NOT NULL
);

