CREATE TABLE [Requirement].[QuestionnaireVariantRequirements]
(
	RequirementIDMadeUpOf dbo.RequirementID NOT NULL, 
	RequirementIDPartOf dbo.RequirementID NOT NULL,
	FromDate DATETIME2 NOT NULL,
	ThroughDate DATETIME2 NULL
)
