ALTER TABLE [dbo].[BrandMarketQuestionnaireMetadata]
    ADD CONSTRAINT [DF_BrandMarketQuestionnaireMetadata_LanguageRequired] DEFAULT (0) FOR [LanguageRequired];

