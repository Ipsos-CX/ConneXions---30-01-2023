ALTER TABLE [dbo].[SampleQualityAndSelectionLogging]
    ADD CONSTRAINT [DF_SampleQualityAndSelectionLogging_WrongEventType] DEFAULT ((0)) FOR [WrongEventType];

