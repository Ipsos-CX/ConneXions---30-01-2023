ALTER TABLE [Requirement].[QuestionnaireModelRequirements]
	ADD CONSTRAINT [FK_QuestionnaireModelRequirements_Requirements_PartOf] 
	FOREIGN KEY (RequirementIDPartOf)
	REFERENCES Requirement.Requirements (RequirementID)	

