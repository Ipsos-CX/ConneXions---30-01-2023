ALTER TABLE [Requirement].[QuestionnaireVariantRequirements]
	ADD CONSTRAINT [PK_QuestionnaireVariantRequirements]
	PRIMARY KEY (RequirementIDMadeUpOf, RequirementIDPartOf, FromDate)