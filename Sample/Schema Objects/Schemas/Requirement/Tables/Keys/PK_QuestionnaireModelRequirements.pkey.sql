ALTER TABLE [Requirement].[QuestionnaireModelRequirements]
	ADD CONSTRAINT [PK_QuestionnaireModelRequirements]
	PRIMARY KEY (RequirementIDMadeUpOf, RequirementIDPartOf, FromDate)