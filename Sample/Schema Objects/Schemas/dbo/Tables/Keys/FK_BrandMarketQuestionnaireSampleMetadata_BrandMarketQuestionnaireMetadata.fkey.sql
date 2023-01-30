ALTER TABLE [dbo].[BrandMarketQuestionnaireSampleMetadata]
	ADD CONSTRAINT [FK_BrandMarketQuestionnaireSampleMetadata_BrandMarketQuestionnaireMetadata] 
	FOREIGN KEY (BMQID)
	REFERENCES BrandMarketQuestionnaireMetadata (BMQID)	

