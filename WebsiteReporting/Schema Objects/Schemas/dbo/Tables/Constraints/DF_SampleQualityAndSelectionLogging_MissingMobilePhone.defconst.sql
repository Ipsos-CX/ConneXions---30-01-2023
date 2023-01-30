ALTER TABLE [dbo].[SampleQualityAndSelectionLogging]
    ADD CONSTRAINT [DF_SampleQualityAndSelectionLogging_MissingMobilePhone] DEFAULT ((0)) FOR [MissingMobilePhone];

