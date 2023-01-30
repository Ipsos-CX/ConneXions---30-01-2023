ALTER TABLE [Event].[CaseContactMechanisms]
    ADD CONSTRAINT [FK_CaseContactMechanisms_Cases] FOREIGN KEY ([CaseID]) 
    REFERENCES [Event].[Cases] ([CaseID]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

