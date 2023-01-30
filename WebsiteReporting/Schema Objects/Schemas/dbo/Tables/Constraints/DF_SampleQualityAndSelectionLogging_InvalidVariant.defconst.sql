ALTER TABLE [dbo].[SampleQualityAndSelectionLogging]
    ADD CONSTRAINT [DF_SampleQualityAndSelectionLogging_InvalidVariant] DEFAULT ((0)) FOR [InvalidVariant];

