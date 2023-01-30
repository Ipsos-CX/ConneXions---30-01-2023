ALTER TABLE [dbo].[SampleQualityAndSelectionLogging]
    ADD CONSTRAINT [DF_SampleQualityAndSelectionLogging_MissingEmail] DEFAULT ((0)) FOR [MissingEmail];

