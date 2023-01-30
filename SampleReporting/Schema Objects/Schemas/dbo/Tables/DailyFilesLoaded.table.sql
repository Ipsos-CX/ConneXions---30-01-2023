CREATE TABLE [dbo].[DailyFilesLoaded] (
    [AuditID]           BIGINT        NULL,
    [FileName]          VARCHAR (100) NULL,
    [FileRowCount]      INT           NULL,
    [ActionDate]        DATETIME2 (7) NULL,
    [LoadSuccess]       BIT           NULL,
    [FileLoadFailure]	VARCHAR (100) NULL,
    [Events]            INT           NULL,
	[EventsTooYoung]    INT			  NULL,
    [BlankVIN]          INT           NULL,
    [Cases]             INT           NULL,
    [PercentSelected]   INT           NULL,
    [MisalignedRemoved] INT		  NULL	
);

