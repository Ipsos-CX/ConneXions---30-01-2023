ALTER TABLE [Party].[PersonAddressingPatterns]
    ADD CONSTRAINT [FK_PersonAddressingPatterns_AddressingTypes] FOREIGN KEY ([AddressingTypeID]) REFERENCES [Party].[AddressingTypes] ([AddressingTypeID]) ON DELETE NO ACTION ON UPDATE NO ACTION;

