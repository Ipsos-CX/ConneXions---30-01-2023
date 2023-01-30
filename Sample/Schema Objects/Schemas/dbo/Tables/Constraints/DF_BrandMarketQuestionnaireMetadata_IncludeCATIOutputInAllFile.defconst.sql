ALTER TABLE [dbo].[BrandMarketQuestionnaireMetadata]
    ADD CONSTRAINT [DF_BrandMarketQuestionnaireMetadata_IncludeCATIOutputInAllFile] DEFAULT (1) FOR [IncludeCATIOutputInAllFile];

