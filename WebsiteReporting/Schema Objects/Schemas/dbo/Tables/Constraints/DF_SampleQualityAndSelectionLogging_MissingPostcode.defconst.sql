ALTER TABLE [dbo].[SampleQualityAndSelectionLogging]
    ADD CONSTRAINT [DF_SampleQualityAndSelectionLogging_MissingPostcode] DEFAULT ((0)) FOR [MissingPostcode];

