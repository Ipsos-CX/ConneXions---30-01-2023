ALTER TABLE [dbo].[BrandMarketQuestionnaireMetadata]
    ADD CONSTRAINT [DF_BrandMarketQuestionnaireMetadata_PostcodeRequired] DEFAULT (0) FOR [PostcodeRequired];

