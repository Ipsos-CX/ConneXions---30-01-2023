ALTER TABLE [dbo].[BrandMarketQuestionnaireMetadata]
    ADD CONSTRAINT [DF_BrandMarketQuestionnaireMetadata_IncludePostalOutputInAllFile] DEFAULT (1) FOR [IncludePostalOutputInAllFile];

