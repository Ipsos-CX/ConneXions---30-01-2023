ALTER TABLE [Party].[LegalOrganisationsByLanguage]
    ADD CONSTRAINT [FK_LegalOrganisationByLanguage_Languages] FOREIGN KEY (LanguageID) REFERENCES [dbo].[Languages] (LanguageID) ON DELETE NO ACTION ON UPDATE NO ACTION;

