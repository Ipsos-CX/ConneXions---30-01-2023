ALTER TABLE [Party].[BlacklistStringNonSolicitations]
    ADD CONSTRAINT [FK_BlacklistStringNonSolicitations_BlacklistStrings] FOREIGN KEY ([BlacklistStringID]) 
    REFERENCES [Party].[BlacklistStrings] ([BlacklistStringID]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

