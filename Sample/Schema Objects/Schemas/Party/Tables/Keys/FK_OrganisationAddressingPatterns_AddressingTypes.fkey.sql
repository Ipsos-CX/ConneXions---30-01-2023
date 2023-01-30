ALTER TABLE [Party].[OrganisationAddressingPatterns]
    ADD CONSTRAINT [FK_OrganisationAddressingPatterns_AddressingTypes] FOREIGN KEY ([AddressingTypeID]) REFERENCES [Party].[AddressingTypes] ([AddressingTypeID]) ON DELETE NO ACTION ON UPDATE NO ACTION;

