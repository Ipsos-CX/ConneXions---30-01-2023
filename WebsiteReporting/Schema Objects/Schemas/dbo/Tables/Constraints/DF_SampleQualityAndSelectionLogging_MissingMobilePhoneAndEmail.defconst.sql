ALTER TABLE [dbo].[SampleQualityAndSelectionLogging]
    ADD CONSTRAINT [DF_SampleQualityAndSelectionLogging_MissingMobilePhoneAndEmail] DEFAULT ((0)) FOR [MissingMobilePhoneAndEmail];

