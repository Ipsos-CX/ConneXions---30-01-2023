ALTER TABLE [dbo].[BrandMarketQuestionnaireMetadata]
    ADD CONSTRAINT [DF_BrandMarketQuestionnaireMetadata_IncludeEmailOutputInAllFile] DEFAULT (1) FOR [IncludeEmailOutputInAllFile];

