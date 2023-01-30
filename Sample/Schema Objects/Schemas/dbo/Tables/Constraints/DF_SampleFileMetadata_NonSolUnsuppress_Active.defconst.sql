ALTER TABLE [dbo].[SampleFileMetadata]
    ADD CONSTRAINT [DF_SampleFileMetadata_NonUnsuppress_Active] DEFAULT (0) FOR NonSolUnsuppress_Active;

