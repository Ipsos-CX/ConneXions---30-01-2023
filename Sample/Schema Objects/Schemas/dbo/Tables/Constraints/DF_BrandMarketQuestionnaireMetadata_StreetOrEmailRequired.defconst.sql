ALTER TABLE [dbo].[BrandMarketQuestionnaireMetadata]
    ADD CONSTRAINT [DF_BrandMarketQuestionnaireMetadata_StreetOrEmailRequired] DEFAULT (0) FOR [StreetOrEmailRequired];

