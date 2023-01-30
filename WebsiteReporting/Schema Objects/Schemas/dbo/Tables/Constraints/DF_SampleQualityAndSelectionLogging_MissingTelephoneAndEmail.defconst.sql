ALTER TABLE [dbo].[SampleQualityAndSelectionLogging]
    ADD CONSTRAINT [DF_SampleQualityAndSelectionLogging_MissingTelephoneAndEmail] DEFAULT ((0)) FOR [MissingTelephoneAndEmail];

