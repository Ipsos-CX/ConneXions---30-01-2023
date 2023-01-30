CREATE TABLE [Event].[CaseCRMResponses] (
    [CaseID]			dbo.CaseID   NOT NULL,
    [QuestionNumber]	nvarchar(5)  NOT NULL,
    [QuestionText]		nvarchar(255)  NOT NULL,
    [Response]			nvarchar(255)  NOT NULL,
    [LoadedToConnexions] DATETIME2 NULL,
    [OutputToCRMDate]	 DATETIME2  NULL
);

