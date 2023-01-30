ALTER TABLE [dbo].[SampleFileMetadata]
    ADD CONSTRAINT [DF_SampleFileMetadata_NonSolSupplied_Email] DEFAULT (0) FOR NonSolSupplied_Email;

