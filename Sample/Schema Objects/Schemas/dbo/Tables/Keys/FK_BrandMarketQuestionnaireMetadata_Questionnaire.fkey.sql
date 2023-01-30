ALTER TABLE [dbo].[BrandMarketQuestionnaireMetadata]
	ADD CONSTRAINT [FK_BrandMarketQuestionnaireMetadata_Questionnaire] 
	FOREIGN KEY (QuestionnaireID)
	REFERENCES Questionnaires (QuestionnaireID)	

