ALTER TABLE [dbo].[SampleQualityAndSelectionLogging]
    ADD CONSTRAINT [DF_SampleQualityAndSelectionLogging_MissingStreet] DEFAULT ((0)) FOR [MissingStreet];

