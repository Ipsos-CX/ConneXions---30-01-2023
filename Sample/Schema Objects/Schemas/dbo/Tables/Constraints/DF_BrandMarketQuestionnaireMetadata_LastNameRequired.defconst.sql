ALTER TABLE [dbo].[BrandMarketQuestionnaireMetadata]
    ADD CONSTRAINT [DF_BrandMarketQuestionnaireMetadata_LastNameRequired] DEFAULT ((0)) FOR [PersonRequired];

