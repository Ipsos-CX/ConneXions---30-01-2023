ALTER TABLE [dbo].[BrandMarketQuestionnaireSampleMetadata]
	ADD CONSTRAINT [FK_BrandMarketQuestionnaireSampleMetadata_QuestionnaireRequirements] 
	FOREIGN KEY (QuestionnaireRequirementID)
	REFERENCES Requirement.QuestionnaireRequirements (RequirementID)	

