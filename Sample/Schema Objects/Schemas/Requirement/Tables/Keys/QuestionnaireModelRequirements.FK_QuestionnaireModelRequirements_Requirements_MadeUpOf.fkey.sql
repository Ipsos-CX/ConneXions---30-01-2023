ALTER TABLE [Requirement].[QuestionnaireModelRequirements]
	ADD CONSTRAINT [FK_QuestionnaireModelRequirements_Requirements_MadeUpOf] 
	FOREIGN KEY (RequirementIDMadeUpOf)
	REFERENCES Requirement.Requirements (RequirementID)	

