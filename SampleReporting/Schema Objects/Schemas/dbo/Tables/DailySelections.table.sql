CREATE TABLE [dbo].[DailySelections] (
    [DateLastRun]    DATETIME2 (7) NULL,
    [RequirementID]  INT           NULL,
    [Requirement]    VARCHAR (255) NULL,
    [CaseCount]      INT           NULL,
    [RejectionCount] INT           NULL
);

