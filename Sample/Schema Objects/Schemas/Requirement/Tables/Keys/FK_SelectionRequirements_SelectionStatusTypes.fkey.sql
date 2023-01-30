ALTER TABLE [Requirement].[SelectionRequirements]
    ADD CONSTRAINT [FK_SelectionRequirements_SelectionStatusTypes] FOREIGN KEY ([SelectionStatusTypeID]) REFERENCES [Requirement].[SelectionStatusTypes] ([SelectionStatusTypeID]) ON DELETE NO ACTION ON UPDATE NO ACTION;

