ALTER TABLE [Party].[BlacklistStringNonSolicitations]
    ADD CONSTRAINT [FK_BlacklistStringNonSolicitations_NonSolicitationTexts] FOREIGN KEY ([NonSolicitationTextID]) 
    REFERENCES [dbo].[NonSolicitationTexts] ([NonSolicitationTextID]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

