ALTER TABLE [dbo].[SampleFileMetadata]
    ADD CONSTRAINT [DF_SampleFileMetadata_NonSolSupplied_Postal] DEFAULT (0) FOR NonSolSupplied_Postal;

