ALTER TABLE [dbo].[BrandMarketQuestionnaireMetadata]
    ADD CONSTRAINT [DF_BrandMarketQuestionnaireMetadata_TelephoneRequired] DEFAULT (0) FOR [TelephoneRequired];

