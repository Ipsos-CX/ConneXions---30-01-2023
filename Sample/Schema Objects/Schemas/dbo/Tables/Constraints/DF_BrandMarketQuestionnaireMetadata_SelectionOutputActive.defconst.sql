ALTER TABLE [dbo].[BrandMarketQuestionnaireMetadata]
    ADD CONSTRAINT [DF_BrandMarketQuestionnaireMetadata_SelectionOutputActive] DEFAULT (0) FOR [SelectionOutputActive];

