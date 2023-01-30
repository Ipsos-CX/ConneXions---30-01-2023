ALTER TABLE [dbo].[BrandMarketQuestionnaireSampleMetadata]
	ADD CONSTRAINT [FK_BrandMarketQuestionnaireSampleMetadata_SampleFileMetadata] 
	FOREIGN KEY (SampleFileID)
	REFERENCES dbo.SampleFileMetadata (SampleFileID)	

