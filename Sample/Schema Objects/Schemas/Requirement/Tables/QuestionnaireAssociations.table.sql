CREATE TABLE [Requirement].[QuestionnaireAssociations] (
    [RequirementIDFrom] dbo.RequirementID      NOT NULL,
    [RequirementIDTo]   dbo.RequirementID      NOT NULL,
    [FromDate]          DATETIME2 NOT NULL
);

