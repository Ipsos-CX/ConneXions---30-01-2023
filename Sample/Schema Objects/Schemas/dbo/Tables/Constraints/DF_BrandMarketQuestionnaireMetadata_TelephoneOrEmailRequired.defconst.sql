ALTER TABLE [dbo].[BrandMarketQuestionnaireMetadata]
    ADD CONSTRAINT [DF_BrandMarketQuestionnaireMetadata_TelephoneOrEmailRequired] DEFAULT (0) FOR [TelephoneOrEmailRequired];

