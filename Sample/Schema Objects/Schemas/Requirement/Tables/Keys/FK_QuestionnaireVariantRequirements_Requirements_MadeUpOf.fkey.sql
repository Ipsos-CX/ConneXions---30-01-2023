ALTER TABLE [Requirement].[QuestionnaireVariantRequirements]
	ADD CONSTRAINT [FK_QuestionnaireVariantRequirements_Requirements_MadeUpOf] 
	FOREIGN KEY (RequirementIDMadeUpOf)
	REFERENCES Requirement.Requirements (RequirementID)	

