ALTER TABLE [Party].[PartyLanguages]
    ADD CONSTRAINT [FK_PartyLanguages_Languages] FOREIGN KEY ([LanguageID]) 
    REFERENCES [dbo].[Languages] ([LanguageID]) ON DELETE NO ACTION ON UPDATE NO ACTION;

