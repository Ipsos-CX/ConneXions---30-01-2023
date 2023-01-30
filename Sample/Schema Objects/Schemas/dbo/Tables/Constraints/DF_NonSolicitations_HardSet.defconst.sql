ALTER TABLE [dbo].[NonSolicitations]
    ADD CONSTRAINT [DF_NonSolicitations_HardSet] DEFAULT (0) FOR HardSet;

