ALTER TABLE [Party].[NonSolicitations]
    ADD CONSTRAINT [FK_Party_NonSolicitations_NonSolicitations] FOREIGN KEY ([NonSolicitationID]) 
    REFERENCES [dbo].[NonSolicitations] ([NonSolicitationID]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

