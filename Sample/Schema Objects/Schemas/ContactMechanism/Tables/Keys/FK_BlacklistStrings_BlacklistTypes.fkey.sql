ALTER TABLE [ContactMechanism].[BlacklistStrings]
    ADD CONSTRAINT [FK_BlacklistStrings_BlacklistTypes] FOREIGN KEY ([BlacklistTypeID]) 
    REFERENCES [ContactMechanism].[BlacklistTypes] ([BlacklistTypeID]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

