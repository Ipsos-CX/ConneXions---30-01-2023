CREATE TABLE [Requirement].[SelectionCases] (
    [CaseID]                dbo.CaseID        NOT NULL,
    [RequirementIDMadeUpOf] dbo.RequirementID           NOT NULL,
    [RequirementIDPartOf]   dbo.RequirementID           NOT NULL
);

