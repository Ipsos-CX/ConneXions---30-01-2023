ALTER TABLE [Event].[NonSolicitations]
    ADD CONSTRAINT [FK_Event_NonSolicitations_NonSolicitations] FOREIGN KEY ([NonSolicitationID]) 
    REFERENCES [dbo].[NonSolicitations] ([NonSolicitationID]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

