CREATE TABLE [SampleReport].[GetDailySampleVolumeBMQbyFile] (
    [Market]               NVARCHAR (255) NULL,
    [Brand]                NVARCHAR (255) NULL,
    [Questionnaire]        NVARCHAR (255) NULL,
    [Frequency]            NVARCHAR (255) NULL,
    [Files]                VARCHAR (100)  NULL,
    [LoadSuccess]          BIT            NULL,
    [FileLoadFailure]      VARCHAR (40)   NULL,
    [FileRowCount]         INT            NULL,
    [AuditID]              BIGINT         NULL,
    [FileRow_LoadedCount]  INT            NULL,
    [Selected_Count]       INT            NULL,
    [ResultDate]           DATETIME       NULL,
    [ReportDate]           DATETIME       NULL,
    [EventsTooYoung_Count] INT            NULL,
    [Region]               NVARCHAR (255) NULL
);