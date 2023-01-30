ALTER TABLE [dbo].[NonSolicitations]
    ADD CONSTRAINT [FK_NonSolicitations_NonSolicitationTexts] FOREIGN KEY ([NonSolicitationTextID]) 
    REFERENCES [dbo].[NonSolicitationTexts] ([NonSolicitationTextID]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

