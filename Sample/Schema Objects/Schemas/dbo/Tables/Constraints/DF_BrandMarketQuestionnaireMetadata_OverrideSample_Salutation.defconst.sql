ALTER TABLE [dbo].[BrandMarketQuestionnaireMetadata]
    ADD CONSTRAINT [DF_BrandMarketQuestionnaireMetadata_OverrideSample_Salutation] DEFAULT ((0)) FOR [OverrideSample_Salutation];

