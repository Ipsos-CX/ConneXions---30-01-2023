ALTER TABLE [dbo].[SampleFileMetadata]
    ADD CONSTRAINT [DF_SampleFileMetadata_NonSolSupplied_Party] DEFAULT (0) FOR NonSolSupplied_Party;

