ALTER TABLE [dbo].[BrandMarketQuestionnaireSampleMetadata]
    ADD CONSTRAINT [DF_BrandMarketQuestionnaireSampleMetadata_SampleTriggeredSelection] DEFAULT ((0)) FOR [SampleTriggeredSelection];

