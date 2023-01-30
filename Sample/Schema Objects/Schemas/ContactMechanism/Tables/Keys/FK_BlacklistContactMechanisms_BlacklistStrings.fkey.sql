ALTER TABLE [ContactMechanism].[BlacklistContactMechanisms]
    ADD CONSTRAINT [FK_BlacklistContactMechanisms_BlacklistStrings] FOREIGN KEY ([BlacklistStringID]) 
    REFERENCES [ContactMechanism].[BlacklistStrings] ([BlacklistStringID]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

