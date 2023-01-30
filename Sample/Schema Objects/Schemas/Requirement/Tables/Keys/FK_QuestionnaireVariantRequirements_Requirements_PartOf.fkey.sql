ALTER TABLE [Requirement].[QuestionnaireVariantRequirements]
	ADD CONSTRAINT [FK_QuestionnaireVariantRequirements_Requirements_PartOf] 
	FOREIGN KEY (RequirementIDPartOf)
	REFERENCES Requirement.Requirements (RequirementID)	

