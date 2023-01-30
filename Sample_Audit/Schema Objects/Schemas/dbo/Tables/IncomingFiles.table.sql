CREATE TABLE [dbo].[IncomingFiles] (
    [AuditID]  AuditID NOT NULL,
    [FileChecksum]       INT			NOT NULL,
    [LoadSuccess]        BIT			NOT NULL,
    [FileLoadFailureID]	 INT			NULL,
	[SHA256HashCode]	 VARCHAR(100)	NULL
);