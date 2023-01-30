ALTER TABLE [Party].[AddressingPatternDefaultElements]
	ADD CONSTRAINT [FK_AddressingPatternDefaultElements_QuestionnaireRequirements] 
	FOREIGN KEY (QuestionnaireRequirementID)
	REFERENCES Requirement.QuestionnaireRequirements (RequirementID)	

