ALTER TABLE [dbo].[Markets]
    ADD CONSTRAINT [DF_Markets_RegionID] DEFAULT 1 FOR RegionID;

