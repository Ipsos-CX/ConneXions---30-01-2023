ALTER TABLE [dbo].[SampleQualityAndSelectionLogging]
    ADD CONSTRAINT [DF_SampleQualityAndSelectionLogging_InvalidModel] DEFAULT ((0)) FOR [InvalidModel];

