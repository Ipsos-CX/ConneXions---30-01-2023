ALTER TABLE [dbo].[SampleQualityAndSelectionLogging]
    ADD CONSTRAINT [DF_SampleQualityAndSelectionLogging_MissingStreetAndEmail] DEFAULT ((0)) FOR [MissingStreetAndEmail];

