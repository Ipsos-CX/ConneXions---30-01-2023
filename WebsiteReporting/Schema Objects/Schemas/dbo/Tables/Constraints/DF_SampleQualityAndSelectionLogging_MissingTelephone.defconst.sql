ALTER TABLE [dbo].[SampleQualityAndSelectionLogging]
    ADD CONSTRAINT [DF_SampleQualityAndSelectionLogging_MissingTelephone] DEFAULT ((0)) FOR [MissingTelephone];

