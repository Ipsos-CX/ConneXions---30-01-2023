ALTER TABLE [Requirement].[SelectionRequirements]
    ADD CONSTRAINT [FK_SelectionRequirements_SelectionTypes] FOREIGN KEY ([SelectionTypeID]) REFERENCES [Requirement].[SelectionTypes] ([SelectionTypeID]) ON DELETE NO ACTION ON UPDATE NO ACTION;

