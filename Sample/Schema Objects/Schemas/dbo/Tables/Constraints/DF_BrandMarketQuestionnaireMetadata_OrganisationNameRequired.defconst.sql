ALTER TABLE [dbo].[BrandMarketQuestionnaireMetadata]
    ADD CONSTRAINT [DF_BrandMarketQuestionnaireMetadata_OrganisationNameRequired] DEFAULT ((0)) FOR [OrganisationRequired];

