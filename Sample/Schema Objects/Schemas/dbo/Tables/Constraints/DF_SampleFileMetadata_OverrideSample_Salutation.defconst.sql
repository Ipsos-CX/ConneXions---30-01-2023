ALTER TABLE [dbo].[SampleFileMetadata]
    ADD  CONSTRAINT [DF_SampleFileMetadata_OverrideSample_Salutation]  DEFAULT ((0)) FOR [OverrideSample_Salutation];

