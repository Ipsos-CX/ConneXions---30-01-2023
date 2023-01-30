CREATE TABLE [Requirement].[QuestionnaireIncompatibilities] (
    [RequirementIDFrom] dbo.RequirementID           NOT NULL,
    [RequirementIDTo]   dbo.RequirementID           NOT NULL,
    [FromDate]          DATETIME2      NOT NULL,
    [ThroughDate]       DATETIME2      NULL
);

